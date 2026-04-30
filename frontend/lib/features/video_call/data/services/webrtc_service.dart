import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Function(MediaStream)? onAddRemoteStream;
  Function(RTCIceCandidate)? onIceCandidate;
  Function()? onConnectionClosed;

  final String appointmentId;
  final String apiUrl;
  final String token;

  // Default fallback. Production TURN credentials are fetched from Laravel
  // and are never hard-coded in the mobile application.
  final Map<String, dynamic> _fallbackConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  WebRTCService({
    required this.appointmentId,
    required this.apiUrl,
    required this.token,
  });

  Future<void> initialize() async {
    final iceConfig = await _fetchIceConfiguration();

    _peerConnection = await createPeerConnection(iceConfig, {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    });

    _peerConnection!.onAddStream = (MediaStream stream) {
      if (onAddRemoteStream != null) {
        onAddRemoteStream!(stream);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      await _sendIceCandidate(candidate);
      if (onIceCandidate != null) {
        onIceCandidate!(candidate);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (onConnectionClosed != null) {
          onConnectionClosed!();
        }
      }
    };

    // Acquisition du flux local (utilisateur) - contraintes de 60fps/150ms requises
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    });

    _peerConnection!.addStream(_localStream!);

    await _joinConsultation();
  }

  MediaStream? get localStream => _localStream;

  Future<void> _joinConsultation() async {
    await http.post(
      Uri.parse('$apiUrl/consultations/$appointmentId/webrtc/join'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  Future<Map<String, dynamic>> _fetchIceConfiguration() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl${ApiConstants.webrtcIceServers}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackConfig;
      }

      final payload = jsonDecode(response.body);
      final data = payload is Map<String, dynamic>
          ? payload['data'] as Map<String, dynamic>?
          : null;
      final iceServers = data?['ice_servers'];

      if (iceServers is! List || iceServers.isEmpty) {
        return _fallbackConfig;
      }

      return {
        'iceServers': iceServers
            .whereType<Map>()
            .map((server) => Map<String, dynamic>.from(server))
            .toList(),
        'sdpSemantics': 'unified-plan',
      };
    } catch (_) {
      return _fallbackConfig;
    }
  }

  Future<void> createOffer() async {
    if (_peerConnection == null) return;
    final RTCSessionDescription offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    await http.post(
      Uri.parse('$apiUrl/consultations/$appointmentId/webrtc/offer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'sdp': offer.sdp,
        'sdp_type': offer.type,
      }),
    );
  }

  Future<void> createAnswer(RTCSessionDescription offer) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(offer);

    final RTCSessionDescription answer =
        await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);

    await http.post(
      Uri.parse('$apiUrl/consultations/$appointmentId/webrtc/answer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'sdp': answer.sdp,
        'sdp_type': answer.type,
      }),
    );
  }

  Future<void> handleRemoteAnswer(RTCSessionDescription answer) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(answer);
  }

  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    await http.post(
      Uri.parse('$apiUrl/consultations/$appointmentId/webrtc/ice'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'candidate': candidate.candidate,
        'sdp_mid': candidate.sdpMid,
        'sdp_mline_index': candidate.sdpMLineIndex,
      }),
    );
  }

  Future<void> handleRemoteIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    await _peerConnection!.addCandidate(candidate);
  }

  void toggleVideo(bool value) {
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = value;
      }
    }
  }

  void toggleAudio(bool value) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = value;
      }
    }
  }

  Future<void> dispose() async {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
  }
}
