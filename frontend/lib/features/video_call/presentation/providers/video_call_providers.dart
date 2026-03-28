import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/core/network/websocket_service.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mediconnect_pro/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:mediconnect_pro/features/video_call/data/services/call_permission_service.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';
import 'package:mediconnect_pro/features/video_call/domain/repositories/video_call_repository.dart';

final videoCallRepositoryProvider = Provider<VideoCallRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VideoCallRepositoryImpl(dio: dio);
});

final callPermissionServiceProvider = Provider<CallPermissionService>((ref) {
  return const CallPermissionService();
});

final videoCallNotifierProvider = StateNotifierProvider.autoDispose
    .family<VideoCallNotifier, VideoCallEntity, String>(
  (ref, appointmentId) {
    final repository = ref.watch(videoCallRepositoryProvider);
    final websocketService = ref.watch(websocketServiceProvider);
    final permissionService = ref.watch(callPermissionServiceProvider);
    final authState = ref.watch(authNotifierProvider).valueOrNull;

    return VideoCallNotifier(
      appointmentId: appointmentId,
      repository: repository,
      websocketService: websocketService,
      permissionService: permissionService,
      currentUserId: authState?.user?.id,
      isDoctor: authState?.user?.isDoctor ?? false,
    );
  },
);

class VideoCallNotifier extends StateNotifier<VideoCallEntity> {
  final VideoCallRepository repository;
  final WebSocketService websocketService;
  final CallPermissionService permissionService;
  final String? currentUserId;
  final bool isDoctor;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  Timer? _durationTimer;
  VideoCallSessionContext? _sessionContext;
  String? _subscribedTeleconsultationId;
  String? _subscribedCallSessionId;
  bool _renderersInitialized = false;
  bool _joiningInProgress = false;
  bool _iceRestartInProgress = false;
  bool _offerInFlight = false;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  VideoCallNotifier({
    required String appointmentId,
    required this.repository,
    required this.websocketService,
    required this.permissionService,
    required this.currentUserId,
    required this.isDoctor,
  }) : super(VideoCallEntity(appointmentId: appointmentId));

  Future<void> initializeCall() async {
    state = state.copyWith(
      state: CallState.resolvingSession,
      clearErrorMessage: true,
    );

    try {
      await _ensureRenderersInitialized();
      await permissionService.ensureMediaPermissions();
      await _ensureLocalMedia();

      final teleconsultationResult =
          await repository.ensureTeleconsultation(state.appointmentId);

      await teleconsultationResult.fold(
        (failure) async => _setError(failure.message),
        (teleconsultation) async {
          _applySessionContext(teleconsultation);
          await _subscribeToTeleconsultation(teleconsultation.teleconsultationId);

          var currentContext = teleconsultation;

          if (isDoctor &&
              currentContext.teleconsultationStatus == 'scheduled') {
            final startResult = await repository.startTeleconsultation(
              currentContext.teleconsultationId,
            );

            final startedContext = await startResult.fold(
              (failure) async {
                await _setError(failure.message);
                return null;
              },
              (value) async => value,
            );

            if (startedContext == null) {
              return;
            }

            currentContext = startedContext;
            _applySessionContext(currentContext);
          }

          if (isDoctor) {
            await _joinTeleconsultation(currentContext.teleconsultationId);
            return;
          }

          if (_canAttemptJoin(currentContext.teleconsultationStatus)) {
            await _joinTeleconsultation(currentContext.teleconsultationId);
            return;
          }

          state = state.copyWith(
            state: CallState.waitingHost,
            clearErrorMessage: true,
          );
        },
      );
    } catch (e) {
      await _setError(e.toString());
    }
  }

  Future<void> retryJoin() async {
    if (state.teleconsultationId == null) {
      await initializeCall();
      return;
    }

    if (_canAttemptJoin(state.teleconsultationStatus)) {
      await _joinTeleconsultation(state.teleconsultationId!);
      return;
    }

    state = state.copyWith(state: CallState.waitingHost);
  }

  Future<void> createOffer({bool iceRestart = false}) async {
    if (_offerInFlight ||
        _peerConnection == null ||
        _sessionContext?.remoteUserId == null ||
        state.teleconsultationId == null) {
      return;
    }

    try {
      _offerInFlight = true;
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
        if (iceRestart) 'iceRestart': true,
      });

      await _peerConnection!.setLocalDescription(offer);

      final result = await repository.sendOffer(
        teleconsultationId: state.teleconsultationId!,
        targetUserId: _sessionContext!.remoteUserId!,
        sdp: offer.sdp ?? '',
        sdpType: offer.type ?? 'offer',
      );

      result.fold((failure) => _setError(failure.message), (_) {});
    } catch (e) {
      await _setError('Failed to create WebRTC offer: $e');
    } finally {
      _offerInFlight = false;
    }
  }

  Future<void> handleOffer(String sdp, String type) async {
    if (_peerConnection == null ||
        _sessionContext?.remoteUserId == null ||
        state.teleconsultationId == null) {
      return;
    }

    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(sdp, type));
    final answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);

    final result = await repository.sendAnswer(
      teleconsultationId: state.teleconsultationId!,
      targetUserId: _sessionContext!.remoteUserId!,
      sdp: answer.sdp ?? '',
      sdpType: answer.type ?? 'answer',
    );

    result.fold((failure) => _setError(failure.message), (_) {});
  }

  Future<void> handleAnswer(String sdp, String type) async {
    if (_peerConnection == null) {
      return;
    }

    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> handleIceCandidate(
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    if (_peerConnection == null) {
      return;
    }

    await _peerConnection!
        .addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
  }

  void toggleAudio() {
    final audioTracks = _localStream?.getAudioTracks() ?? const [];
    if (audioTracks.isEmpty) {
      return;
    }

    final audioTrack = audioTracks.first;
    audioTrack.enabled = !audioTrack.enabled;
    state = state.copyWith(isAudioMuted: !audioTrack.enabled);
  }

  void toggleVideo() {
    final videoTracks = _localStream?.getVideoTracks() ?? const [];
    if (videoTracks.isEmpty) {
      return;
    }

    final videoTrack = videoTracks.first;
    videoTrack.enabled = !videoTrack.enabled;
    state = state.copyWith(isVideoEnabled: videoTrack.enabled);
  }

  Future<void> toggleSpeaker() async {
    final nextValue = !state.isSpeakerOn;
    await Helper.setSpeakerphoneOn(nextValue);
    state = state.copyWith(isSpeakerOn: nextValue);
  }

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? const [];
    if (videoTracks.isEmpty) {
      return;
    }

    await Helper.switchCamera(videoTracks.first);
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  Future<void> endCall() async {
    final teleconsultationId = state.teleconsultationId;

    if (teleconsultationId != null) {
      if (state.state == CallState.connected ||
          state.teleconsultationStatus == 'active') {
        await repository.endTeleconsultation(teleconsultationId);
      } else {
        await repository.cancelTeleconsultation(teleconsultationId);
      }
    }

    await _teardownCallResources(disposeRenderers: false);
    state = state.copyWith(state: CallState.ended, hasRemoteVideo: false);
  }

  Future<void> handleLifecycleChange(AppLifecycleState appLifecycleState) async {
    final videoTracks = _localStream?.getVideoTracks() ?? const [];
    final videoTrack = videoTracks.isNotEmpty ? videoTracks.first : null;

    if (appLifecycleState == AppLifecycleState.paused ||
        appLifecycleState == AppLifecycleState.inactive) {
      if (videoTrack != null) {
        videoTrack.enabled = false;
      }
      return;
    }

    if (appLifecycleState == AppLifecycleState.resumed) {
      if (videoTrack != null && state.isVideoEnabled) {
        videoTrack.enabled = true;
      }

      if (state.state == CallState.reconnecting) {
        await _attemptIceRestart();
      }
    }
  }

  Future<void> _joinTeleconsultation(String teleconsultationId) async {
    if (_joiningInProgress) {
      return;
    }

    try {
      _joiningInProgress = true;
      state = state.copyWith(
        state: isDoctor ? CallState.ringing : CallState.joining,
        clearErrorMessage: true,
      );

      final result = await repository.joinTeleconsultation(teleconsultationId);

      await result.fold(
        (failure) async {
          if (!isDoctor && failure.message.toLowerCase().contains('not been')) {
            state = state.copyWith(state: CallState.waitingHost);
            return;
          }

          await _setError(failure.message);
        },
        (context) async {
          _sessionContext = context;
          _applySessionContext(context);
          await _ensurePeerConnection(context);

          if (context.callSessionId != null) {
            await _subscribeToCallSession(context.callSessionId!);
          }

          if (isDoctor && context.teleconsultationStatus == 'active') {
            await createOffer();
          }
        },
      );
    } finally {
      _joiningInProgress = false;
    }
  }

  Future<void> _ensureRenderersInitialized() async {
    if (_renderersInitialized) {
      return;
    }

    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersInitialized = true;
  }

  Future<void> _ensureLocalMedia() async {
    if (_localStream != null) {
      return;
    }

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });

    localRenderer.srcObject = _localStream;
    await Helper.setSpeakerphoneOn(state.isSpeakerOn);
  }

  Future<void> _ensurePeerConnection(VideoCallSessionContext context) async {
    if (_peerConnection != null &&
        context.callSessionId != null &&
        context.callSessionId == state.callSessionId) {
      return;
    }

    await _closePeerConnectionOnly();

    final config = {
      'iceServers': context.iceServers
          .map((server) => {
                'urls': server.urls,
                if (server.username != null) 'username': server.username,
                if (server.credential != null) 'credential': server.credential,
              })
          .toList(),
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(config);

    final localTracks = _localStream?.getTracks() ?? const [];
    for (final track in localTracks) {
      await _peerConnection?.addTrack(track, _localStream!);
    }

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isEmpty) {
        return;
      }

      _remoteStream = event.streams.first;
      remoteRenderer.srcObject = _remoteStream;
      state = state.copyWith(hasRemoteVideo: true);
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      final remoteUserId = _sessionContext?.remoteUserId;
      final teleconsultationId = state.teleconsultationId;

      if (remoteUserId == null ||
          teleconsultationId == null ||
          (candidate.candidate ?? '').isEmpty) {
        return;
      }

      repository.sendIceCandidate(
        teleconsultationId: teleconsultationId,
        targetUserId: remoteUserId,
        candidate: candidate.candidate ?? '',
        sdpMid: candidate.sdpMid,
        sdpMLineIndex: candidate.sdpMLineIndex,
      );
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState pcs) {
      if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        state = state.copyWith(
          state: CallState.connected,
          teleconsultationStatus: 'active',
        );
        _startDurationTimer();
      } else if (pcs ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        state = state.copyWith(state: CallState.reconnecting);
        _attemptIceRestart();
      } else if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        state = state.copyWith(state: CallState.reconnecting);
        _attemptIceRestart();
      } else if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _durationTimer?.cancel();
      }
    };
  }

  Future<void> _subscribeToTeleconsultation(String teleconsultationId) async {
    if (_subscribedTeleconsultationId == teleconsultationId) {
      return;
    }

    if (_subscribedTeleconsultationId != null) {
      await websocketService
          .unsubscribeTeleconsultation(_subscribedTeleconsultationId!);
    }

    _subscribedTeleconsultationId = teleconsultationId;

    await websocketService.subscribeToTeleconsultation(
      teleconsultationId,
      _handleRealtimeEvent,
    );
  }

  Future<void> _subscribeToCallSession(String callSessionId) async {
    if (_subscribedCallSessionId == callSessionId) {
      return;
    }

    if (_subscribedCallSessionId != null) {
      await websocketService.unsubscribeCallSession(_subscribedCallSessionId!);
    }

    _subscribedCallSessionId = callSessionId;

    await websocketService.subscribeToCallSession(
      callSessionId,
      _handleRealtimeEvent,
    );
  }

  Future<void> _handleRealtimeEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {
    switch (eventName) {
      case 'teleconsultation.updated':
        final teleconsultation =
            data['teleconsultation'] as Map<String, dynamic>? ?? const {};
        await _handleTeleconsultationUpdate(teleconsultation);
        break;
      case 'webrtc.ringing':
        final callSession = data['call_session'] as Map<String, dynamic>? ?? {};
        state = state.copyWith(
          state: CallState.ringing,
          callSessionId:
              callSession['id']?.toString() ?? state.callSessionId,
        );
        break;
      case 'webrtc.accepted':
        final callSession = data['call_session'] as Map<String, dynamic>? ?? {};
        state = state.copyWith(
          state: CallState.joining,
          teleconsultationStatus: 'active',
          callSessionId:
              callSession['id']?.toString() ?? state.callSessionId,
        );
        if (isDoctor) {
          await createOffer();
        }
        break;
      case 'webrtc.offer':
        if (_isTargetedToCurrentUser(data)) {
          final sdp = data['sdp'] as Map<String, dynamic>? ?? const {};
          await handleOffer(
            sdp['sdp']?.toString() ?? '',
            sdp['type']?.toString() ?? 'offer',
          );
        }
        break;
      case 'webrtc.answer':
        if (_isTargetedToCurrentUser(data)) {
          final sdp = data['sdp'] as Map<String, dynamic>? ?? const {};
          await handleAnswer(
            sdp['sdp']?.toString() ?? '',
            sdp['type']?.toString() ?? 'answer',
          );
        }
        break;
      case 'webrtc.ice_candidate':
        if (_isTargetedToCurrentUser(data)) {
          final candidate =
              data['candidate'] as Map<String, dynamic>? ?? const {};
          await handleIceCandidate(
            candidate['candidate']?.toString() ?? '',
            candidate['sdpMid']?.toString(),
            candidate['sdpMLineIndex'] as int?,
          );
        }
        break;
      case 'webrtc.rejected':
        await _terminateFromRemote('The teleconsultation was rejected.');
        break;
      case 'webrtc.timeout':
        await _terminateFromRemote('The teleconsultation timed out.');
        break;
      case 'webrtc.ended':
        await _terminateFromRemote(null);
        break;
    }
  }

  Future<void> _handleTeleconsultationUpdate(
      Map<String, dynamic> teleconsultation) async {
    if (teleconsultation.isEmpty) {
      return;
    }

    final teleconsultationId = teleconsultation['id']?.toString();
    final status = teleconsultation['status']?.toString().toLowerCase();
    final callSessionId =
        teleconsultation['current_call_session_id']?.toString();
    final conversationId = teleconsultation['conversation_id']?.toString();

    state = state.copyWith(
      teleconsultationId: teleconsultationId ?? state.teleconsultationId,
      teleconsultationStatus: status ?? state.teleconsultationStatus,
      callSessionId: callSessionId ?? state.callSessionId,
      conversationId: conversationId ?? state.conversationId,
      state: status == 'scheduled' && !isDoctor
          ? CallState.waitingHost
          : state.state,
    );

    if (!isDoctor &&
        teleconsultationId != null &&
        _canAttemptJoin(status) &&
        state.state != CallState.connected) {
      await _joinTeleconsultation(teleconsultationId);
    }

    if (callSessionId != null) {
      await _subscribeToCallSession(callSessionId);
    }
  }

  bool _canAttemptJoin(String? teleconsultationStatus) {
    return teleconsultationStatus == 'ringing' ||
        teleconsultationStatus == 'active';
  }

  bool _isTargetedToCurrentUser(Map<String, dynamic> data) {
    final targetUserId = data['target_user_id']?.toString();
    final selfUserId = _sessionContext?.selfUserId ?? currentUserId;

    return targetUserId != null &&
        selfUserId != null &&
        targetUserId == selfUserId;
  }

  void _applySessionContext(VideoCallSessionContext context) {
    _sessionContext = context;
    state = state.copyWith(
      teleconsultationId: context.teleconsultationId,
      callSessionId: context.callSessionId,
      conversationId: context.conversationId,
      teleconsultationStatus: context.teleconsultationStatus,
      state: context.teleconsultationStatus == 'scheduled' && !isDoctor
          ? CallState.waitingHost
          : (context.teleconsultationStatus == 'active'
              ? CallState.joining
              : CallState.ringing),
      clearErrorMessage: true,
    );
  }

  Future<void> _attemptIceRestart() async {
    if (!isDoctor ||
        _iceRestartInProgress ||
        _peerConnection == null ||
        state.teleconsultationId == null ||
        _sessionContext?.remoteUserId == null) {
      return;
    }

    try {
      _iceRestartInProgress = true;
      await createOffer(iceRestart: true);
    } finally {
      _iceRestartInProgress = false;
    }
  }

  Future<void> _terminateFromRemote(String? message) async {
    await _teardownCallResources(disposeRenderers: false);
    state = state.copyWith(
      state: CallState.ended,
      hasRemoteVideo: false,
      errorMessage: message,
    );
  }

  Future<void> _setError(String message) async {
    state = state.copyWith(
      state: CallState.error,
      errorMessage: message,
    );
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state =
          state.copyWith(duration: state.duration + const Duration(seconds: 1));
    });
  }

  Future<void> _closePeerConnectionOnly() async {
    _durationTimer?.cancel();
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStream = null;
    remoteRenderer.srcObject = null;
  }

  Future<void> _teardownCallResources({
    required bool disposeRenderers,
  }) async {
    _durationTimer?.cancel();

    if (_subscribedCallSessionId != null) {
      await websocketService.unsubscribeCallSession(_subscribedCallSessionId!);
      _subscribedCallSessionId = null;
    }

    if (_subscribedTeleconsultationId != null) {
      await websocketService
          .unsubscribeTeleconsultation(_subscribedTeleconsultationId!);
      _subscribedTeleconsultationId = null;
    }

    await _peerConnection?.close();
    _peerConnection = null;

    final localTracks = _localStream?.getTracks() ?? const [];
    for (final track in localTracks) {
      track.stop();
    }

    final remoteTracks = _remoteStream?.getTracks() ?? const [];
    for (final track in remoteTracks) {
      track.stop();
    }

    await _localStream?.dispose();
    await _remoteStream?.dispose();

    _localStream = null;
    _remoteStream = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    if (disposeRenderers) {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    }
  }

  @override
  void dispose() {
    unawaited(_teardownCallResources(disposeRenderers: true));
    super.dispose();
  }
}
