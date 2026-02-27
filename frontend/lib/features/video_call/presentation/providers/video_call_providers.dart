import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';
import 'package:mediconnect_pro/features/video_call/domain/repositories/video_call_repository.dart';

final videoCallRepositoryProvider = Provider<VideoCallRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VideoCallRepositoryImpl(dio: dio);
});

final videoCallNotifierProvider = StateNotifierProvider.autoDispose
    .family<VideoCallNotifier, VideoCallEntity, String>(
  (ref, appointmentId) {
    final repository = ref.watch(videoCallRepositoryProvider);
    return VideoCallNotifier(
      appointmentId: appointmentId,
      repository: repository,
    );
  },
);

class VideoCallNotifier extends StateNotifier<VideoCallEntity> {
  final VideoCallRepository repository;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  Timer? _durationTimer;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  VideoCallNotifier({
    required String appointmentId,
    required this.repository,
  }) : super(VideoCallEntity(appointmentId: appointmentId));

  Future<void> initializeCall() async {
    state = state.copyWith(state: CallState.joining);

    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      // Get user media
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      localRenderer.srcObject = _localStream;

      // Create peer connection
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      });

      // Add local tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // Handle remote stream
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
          remoteRenderer.srcObject = _remoteStream;
        }
      };

      // Handle ICE candidates
      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        repository.sendIceCandidate(
          appointmentId: state.appointmentId,
          candidate: candidate.candidate ?? '',
          sdpMid: candidate.sdpMid,
          sdpMLineIndex: candidate.sdpMLineIndex,
        );
      };

      // Handle connection state
      _peerConnection?.onConnectionState = (RTCPeerConnectionState pcs) {
        if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          state = state.copyWith(state: CallState.connected);
          _startDurationTimer();
        } else if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          state = state.copyWith(
              state: CallState.error, errorMessage: 'Connection failed');
        } else if (pcs ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          state = state.copyWith(state: CallState.reconnecting);
        }
      };

      // Join the room
      await repository.joinRoom(state.appointmentId);
      state = state.copyWith(state: CallState.ringing);
    } catch (e) {
      state =
          state.copyWith(state: CallState.error, errorMessage: e.toString());
    }
  }

  Future<void> createOffer() async {
    final offer = await _peerConnection?.createOffer();
    if (offer != null) {
      await _peerConnection?.setLocalDescription(offer);
      await repository.sendOffer(
        appointmentId: state.appointmentId,
        sdp: offer.sdp ?? '',
        sdpType: offer.type ?? 'offer',
      );
    }
  }

  Future<void> handleOffer(String sdp, String type) async {
    await _peerConnection
        ?.setRemoteDescription(RTCSessionDescription(sdp, type));
    final answer = await _peerConnection?.createAnswer();
    if (answer != null) {
      await _peerConnection?.setLocalDescription(answer);
      await repository.sendAnswer(
        appointmentId: state.appointmentId,
        sdp: answer.sdp ?? '',
        sdpType: answer.type ?? 'answer',
      );
    }
  }

  Future<void> handleAnswer(String sdp, String type) async {
    await _peerConnection
        ?.setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> handleIceCandidate(
      String candidate, String? sdpMid, int? sdpMLineIndex) async {
    await _peerConnection
        ?.addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
  }

  void toggleAudio() {
    final audioTrack = _localStream?.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
      state = state.copyWith(isAudioMuted: !audioTrack.enabled);
    }
  }

  void toggleVideo() {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      videoTrack.enabled = !videoTrack.enabled;
      state = state.copyWith(isVideoEnabled: videoTrack.enabled);
    }
  }

  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
      state = state.copyWith(isFrontCamera: !state.isFrontCamera);
    }
  }

  Future<void> endCall() async {
    _durationTimer?.cancel();
    await _peerConnection?.close();
    _localStream?.getTracks().forEach((t) => t.stop());
    _remoteStream?.getTracks().forEach((t) => t.stop());
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    state = state.copyWith(state: CallState.ended);
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state =
          state.copyWith(duration: state.duration + const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _peerConnection?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}
