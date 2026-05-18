import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/core/network/websocket_service.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mediconnect_pro/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:mediconnect_pro/features/video_call/data/services/call_permission_service.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';
import 'package:mediconnect_pro/features/video_call/domain/repositories/video_call_repository.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  lk.Room? _liveKitRoom;
  lk.EventsListener<lk.RoomEvent>? _liveKitListener;
  lk.VideoTrack? _liveKitLocalVideoTrack;
  lk.VideoTrack? _liveKitRemoteVideoTrack;
  Timer? _durationTimer;
  VideoCallSessionContext? _sessionContext;
  String? _subscribedTeleconsultationId;
  String? _subscribedCallSessionId;
  String? _teleconsultationListenerId;
  String? _callSessionListenerId;
  bool _renderersInitialized = false;
  bool _joiningInProgress = false;
  bool _iceRestartInProgress = false;
  bool _offerInFlight = false;
  bool _isInitializingCall = false;
  bool _awaitingPermissionSettingsResult = false;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  lk.VideoTrack? get liveKitLocalVideoTrack => _liveKitLocalVideoTrack;

  lk.VideoTrack? get liveKitRemoteVideoTrack => _liveKitRemoteVideoTrack;

  bool get isUsingLiveKit => _liveKitRoom != null;

  VideoCallNotifier({
    required String appointmentId,
    required this.repository,
    required this.websocketService,
    required this.permissionService,
    required this.currentUserId,
    required this.isDoctor,
  }) : super(VideoCallEntity(appointmentId: appointmentId));

  VideoCallType? _desiredCallType;

  Future<void> initializeCall({
    bool requestPermissions = true,
    VideoCallType? desiredCallType,
  }) async {
    if (_isInitializingCall) {
      return;
    }

    _desiredCallType = desiredCallType ?? _desiredCallType;

    _isInitializingCall = true;
    state = state.copyWith(
      state: CallState.resolvingSession,
      mediaPermissionState: CallMediaPermissionState.checking,
      clearMediaPermissionMessage: true,
      clearErrorMessage: true,
    );

    try {
      await _ensureRenderersInitialized();
      final teleconsultationResult = await repository.ensureTeleconsultation(
        state.appointmentId,
        callType: _desiredCallType,
      );

      await teleconsultationResult.fold(
        (failure) async => _setError(failure.message),
        (teleconsultation) async {
          _applySessionContext(teleconsultation);

          // La souscription Reverb sert aux events temps réel (ringing, ended,
          // typing). Si Reverb est indisponible (mauvaise clé, serveur down),
          // on continue quand même: LiveKit a sa propre signalisation et
          // l'appel doit pouvoir s'établir sans Reverb.
          try {
            await _subscribeToTeleconsultation(
                teleconsultation.teleconsultationId);
          } catch (subscribeError) {
            debugPrint(
              'VideoCall: Reverb subscribe failed (non-blocking): $subscribeError',
            );
          }

          if (kIsWeb) {
            await _ensureLocalMedia(teleconsultation.callType);
            state = state.copyWith(
              mediaPermissionState: CallMediaPermissionState.granted,
              clearMediaPermissionMessage: true,
            );
          } else {
            final permissionResult =
                await permissionService.ensureMediaPermissions(
              requestIfNeeded: requestPermissions,
              requireVideo: teleconsultation.callType.requiresVideo,
            );

            _applyPermissionResult(permissionResult);
            if (!permissionResult.isGranted) {
              return;
            }

            _awaitingPermissionSettingsResult = false;

            final missingDeviceMessage = await _validateRequiredMediaDevices(
              requireVideo: teleconsultation.callType.requiresVideo,
            );
            if (missingDeviceMessage != null) {
              await _setError(missingDeviceMessage);
              return;
            }

            await _ensureLocalMedia(teleconsultation.callType);
          }

          var currentContext = teleconsultation;

          // Le médecin peut (re)démarrer la téléconsultation depuis un statut
          // non-actif: scheduled (jamais lancée), waiting, ended/expired (relance).
          // Backend accepte désormais ENDED/EXPIRED en réinitialisant.
          const startableStatuses = {'scheduled', 'waiting', 'ended', 'expired'};
          if (isDoctor &&
              startableStatuses.contains(
                  currentContext.teleconsultationStatus.toLowerCase())) {
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
    } on _LocalMediaAccessException catch (error) {
      if (error.permissionState != null) {
        state = state.copyWith(
          state: CallState.idle,
          mediaPermissionState: error.permissionState!,
          mediaPermissionMessage: error.userMessage,
          clearErrorMessage: true,
        );
      } else {
        await _setError(error.userMessage);
      }
    } catch (e) {
      await _setError(_resolveFriendlyCallError(e));
    } finally {
      _isInitializingCall = false;
    }
  }

  Future<void> retryJoin() async {
    if (!state.hasMediaPermissions) {
      await requestPermissionsAndRetry();
      return;
    }

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

  Future<void> requestPermissionsAndRetry() async {
    await initializeCall(requestPermissions: true);
  }

  Future<void> openPermissionSettings() async {
    _awaitingPermissionSettingsResult = true;
    await permissionService.openPermissionSettings();
  }

  Future<void> refreshPermissionsAfterSettings() async {
    if (kIsWeb) {
      if (_localStream == null) {
        await initializeCall(requestPermissions: false);
      }
      return;
    }

    final result = await permissionService.checkMediaPermissions(
      requireVideo: state.requiresVideo,
    );
    _applyPermissionResult(result);

    if (!result.isGranted) {
      return;
    }

    if (_localStream == null) {
      await initializeCall(requestPermissions: false);
    }
  }

  Future<void> createOffer({bool iceRestart = false}) async {
    if (_liveKitRoom != null) {
      return;
    }

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
        'offerToReceiveVideo': state.requiresVideo,
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
    if (_liveKitRoom != null) {
      return;
    }

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
    if (_liveKitRoom != null) {
      return;
    }

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
    if (_liveKitRoom != null) {
      return;
    }

    if (_peerConnection == null) {
      return;
    }

    await _peerConnection!
        .addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
  }

  void toggleAudio() {
    final liveKitParticipant = _liveKitRoom?.localParticipant;
    if (liveKitParticipant != null) {
      final nextMuted = !state.isAudioMuted;
      unawaited(liveKitParticipant.setMicrophoneEnabled(!nextMuted));
      state = state.copyWith(isAudioMuted: nextMuted);
      return;
    }

    final audioTracks = _localStream?.getAudioTracks() ?? const [];
    if (audioTracks.isEmpty) {
      return;
    }

    final audioTrack = audioTracks.first;
    audioTrack.enabled = !audioTrack.enabled;
    state = state.copyWith(isAudioMuted: !audioTrack.enabled);
  }

  void toggleVideo() {
    if (!state.requiresVideo) {
      return;
    }

    final liveKitParticipant = _liveKitRoom?.localParticipant;
    if (liveKitParticipant != null) {
      final nextEnabled = !state.isVideoEnabled;
      unawaited(liveKitParticipant.setCameraEnabled(nextEnabled).then((_) {
        _syncLiveKitTracks();
      }));
      state = state.copyWith(
        isVideoEnabled: nextEnabled,
        hasRemoteVideo: state.hasRemoteVideo,
      );
      return;
    }

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
    if (!kIsWeb) {
      await Helper.setSpeakerphoneOn(nextValue);
    }
    state = state.copyWith(isSpeakerOn: nextValue);
  }

  Future<void> switchCamera() async {
    if (!state.requiresVideo) {
      return;
    }

    final liveKitParticipant = _liveKitRoom?.localParticipant;
    if (liveKitParticipant != null) {
      final track = _firstLocalLiveKitVideoTrack(liveKitParticipant);
      if (track == null) {
        return;
      }

      await Helper.switchCamera(track.mediaStreamTrack);
      state = state.copyWith(isFrontCamera: !state.isFrontCamera);
      return;
    }

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

  Future<void> handleLifecycleChange(
      AppLifecycleState appLifecycleState) async {
    if (appLifecycleState == AppLifecycleState.resumed &&
        (_awaitingPermissionSettingsResult || !state.hasMediaPermissions) &&
        _localStream == null) {
      await refreshPermissionsAfterSettings();
      _awaitingPermissionSettingsResult = false;
    }

    final liveKitParticipant = _liveKitRoom?.localParticipant;
    if (liveKitParticipant != null) {
      if (appLifecycleState == AppLifecycleState.paused ||
          appLifecycleState == AppLifecycleState.inactive) {
        if (state.requiresVideo) {
          await liveKitParticipant.setCameraEnabled(false);
          _syncLiveKitTracks();
        }
        return;
      }

      if (appLifecycleState == AppLifecycleState.resumed &&
          state.requiresVideo &&
          state.isVideoEnabled) {
        await liveKitParticipant.setCameraEnabled(true);
        _syncLiveKitTracks();
      }
      return;
    }

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

      final result = await repository.joinTeleconsultation(
        teleconsultationId,
        cameraEnabled: state.requiresVideo ? state.isVideoEnabled : false,
        microphoneEnabled: !state.isAudioMuted,
      );

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
          final connectedWithLiveKit = await _ensureLiveKitRoom(context);
          if (!connectedWithLiveKit) {
            return;
          }

          if (context.callSessionId != null) {
            // Souscription non-bloquante: si Reverb échoue, on garde l'appel
            // actif. Les events temps réel manquants ne cassent pas la session.
            try {
              await _subscribeToCallSession(context.callSessionId!);
            } catch (subscribeError) {
              debugPrint(
                'VideoCall: Reverb call-session subscribe failed (non-blocking): $subscribeError',
              );
            }
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

  Future<void> _ensureLocalMedia(VideoCallType callType) async {
    if (_localStream != null) {
      return;
    }

    // Sur Web, navigator.mediaDevices n'existe que dans un secure context
    // (HTTPS ou localhost). Si l'app est servie depuis une IP locale en HTTP
    // (ex: http://192.168.1.173:8080), getUserMedia est tout simplement
    // indisponible. On lève un message clair plutôt qu'une exception cryptique.
    if (kIsWeb) {
      try {
        // Tentative d'accès — si le contexte n'est pas sécurisé, ça throw.
        // ignore: unnecessary_null_comparison
        if (navigator.mediaDevices == null) {
          throw const _LocalMediaAccessException(
            userMessage:
                'Caméra/micro indisponibles. Sur Web, l’app doit être servie via '
                'HTTPS ou localhost (contexte sécurisé). Accédez à l’app via '
                'http://localhost:<port> au lieu d’une IP réseau.',
          );
        }
      } catch (e) {
        if (e is _LocalMediaAccessException) rethrow;
      }
    }

    try {
      // Contraintes audio renforcées pour qualité d'appel:
      //   - echoCancellation : supprime l'écho hardware (haut-parleur -> micro)
      //   - noiseSuppression : filtre bruit ambiant (clavier, ventilo, rue)
      //   - autoGainControl  : normalise le volume voix
      //   - sampleRate 48000 + channelCount 1 : format Opus standard,
      //     latence/CPU minimaux, qualité voix optimale
      // Ces flags sont normalement actifs par défaut sur Chrome desktop mais
      // ne le sont PAS sur Chrome Android < 100 et plusieurs WebView. Forcer
      // explicitement évite des sessions noisy/echoey en production.
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': 48000,
          'channelCount': 1,
        },
        'video': callType.requiresVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280, 'max': 1920},
                'height': {'ideal': 720, 'max': 1080},
                'frameRate': {'ideal': 24, 'max': 30},
              }
            : false,
      });
    } catch (error) {
      throw await _mapLocalMediaError(error);
    }

    localRenderer.srcObject = _localStream;
    if (!kIsWeb) {
      await Helper.setSpeakerphoneOn(state.isSpeakerOn);
    }
  }

  Future<bool> _ensureLiveKitRoom(VideoCallSessionContext context) async {
    final callSessionId = context.callSessionId;
    if (callSessionId == null || callSessionId.isEmpty) {
      await _setError('Session d’appel introuvable.');
      return false;
    }

    if (_liveKitRoom != null && callSessionId == state.callSessionId) {
      return true;
    }

    final tokenResult = await repository.getLiveKitConnection(callSessionId);

    return tokenResult.fold(
      (failure) async {
        await _setError(failure.message);
        return false;
      },
      (connection) async {
        await _disconnectLiveKitRoom();
        await _releaseLocalPreviewStream();

        // RoomOptions optimisées pour qualité d'appel téléconsultation:
        //   - adaptiveStream : adapte la qualité reçue à la taille du renderer
        //     (économise bande passante quand la PiP locale est petite)
        //   - dynacast        : LiveKit coupe les layers simulcast non
        //     consommés, réduit le CPU/upload
        //   - defaultAudioPublishOptions:
        //       * dtx=true : Discontinuous Transmission, on n'envoie pas
        //         d'audio pendant les silences -> ~50% bande passante en moins
        //       * red=true : redundancy encoding, résilience aux pertes UDP
        //         (très utile sur 4G/WiFi instable)
        //   - defaultVideoPublishOptions:
        //       * simulcast=true : publie 3 layers (low/medium/high), le SFU
        //         distribue le bon layer selon les conditions réseau du
        //         destinataire -> moins de gel sur réseaux lents
        //       * videoEncoding plafonné à 720p @ 1.7 Mbps pour rester sous
        //         le quota Free Tier LiveKit Cloud et garder une marge UL
        const audioOptions = lk.AudioPublishOptions(
          dtx: true,
          red: true,
        );

        const videoOptions = lk.VideoPublishOptions(
          simulcast: true,
          videoEncoding: lk.VideoEncoding(
            maxBitrate: 1_700_000,
            maxFramerate: 30,
          ),
          videoSimulcastLayers: [
            lk.VideoParametersPresets.h180_169,
            lk.VideoParametersPresets.h360_169,
          ],
        );

        final room = lk.Room(
          roomOptions: const lk.RoomOptions(
            adaptiveStream: true,
            dynacast: true,
            defaultAudioPublishOptions: audioOptions,
            defaultVideoPublishOptions: videoOptions,
          ),
        );
        final listener = room.createListener();

        _liveKitRoom = room;
        _liveKitListener = listener;
        room.addListener(_syncLiveKitTracks);
        _setUpLiveKitListeners(listener);

        try {
          await room.connect(
            connection.url,
            connection.token,
            connectOptions: const lk.ConnectOptions(autoSubscribe: true),
          );

          await room.localParticipant?.setMicrophoneEnabled(
            !state.isAudioMuted,
          );

          if (context.callType.requiresVideo) {
            await room.localParticipant?.setCameraEnabled(
              state.isVideoEnabled,
            );
          }

          _syncLiveKitTracks();
          if (mounted) {
            state = state.copyWith(
              state: CallState.connected,
              teleconsultationStatus: 'active',
              clearErrorMessage: true,
            );
          }
          _startDurationTimer();
          // Empêche l'écran de se verrouiller pendant l'appel.
          // Sans ça, sur iOS et certains Android l'OS suspend caméra/micro
          // après le timeout d'inactivité, ce qui casse la session WebRTC.
          // Pas supporté sur Web (le navigateur gère son propre wake lock).
          if (!kIsWeb) {
            await WakelockPlus.enable().catchError((Object e) {
              debugPrint('VideoCall: wakelock enable failed (ignored): $e');
            });
          }

          return true;
        } catch (error) {
          await _disconnectLiveKitRoom();
          await _setError(_resolveFriendlyLiveKitError(error));
          return false;
        }
      },
    );
  }

  void _setUpLiveKitListeners(lk.EventsListener<lk.RoomEvent> listener) {
    listener
      ..on<lk.RoomReconnectingEvent>((_) {
        if (mounted) {
          state = state.copyWith(state: CallState.reconnecting);
        }
      })
      ..on<lk.RoomReconnectedEvent>((_) {
        if (mounted) {
          state = state.copyWith(
            state: CallState.connected,
            teleconsultationStatus: 'active',
          );
        }
        _startDurationTimer();
        _syncLiveKitTracks();
      })
      ..on<lk.RoomDisconnectedEvent>((_) {
        _durationTimer?.cancel();
        if (mounted && state.state != CallState.ended) {
          state = state.copyWith(
            state: CallState.ended,
            hasRemoteVideo: false,
          );
        }
      })
      ..on<lk.ParticipantEvent>((_) => _syncLiveKitTracks())
      ..on<lk.LocalTrackPublishedEvent>((_) => _syncLiveKitTracks())
      ..on<lk.LocalTrackUnpublishedEvent>((_) => _syncLiveKitTracks())
      ..on<lk.TrackSubscribedEvent>((_) => _syncLiveKitTracks())
      ..on<lk.TrackUnsubscribedEvent>((_) => _syncLiveKitTracks());
  }

  void _syncLiveKitTracks() {
    final room = _liveKitRoom;
    if (room == null) {
      _liveKitLocalVideoTrack = null;
      _liveKitRemoteVideoTrack = null;
      return;
    }

    _liveKitLocalVideoTrack = room.localParticipant == null
        ? null
        : _firstLocalLiveKitVideoTrack(room.localParticipant!);
    _liveKitRemoteVideoTrack = _firstRemoteLiveKitVideoTrack(room);

    if (!mounted) {
      return;
    }

    final isConnected = room.connectionState == lk.ConnectionState.connected;
    state = state.copyWith(
      state: isConnected ? CallState.connected : state.state,
      teleconsultationStatus:
          isConnected ? 'active' : state.teleconsultationStatus,
      hasRemoteVideo: state.requiresVideo && _liveKitRemoteVideoTrack != null,
    );
  }

  lk.VideoTrack? _firstLocalLiveKitVideoTrack(
    lk.LocalParticipant participant,
  ) {
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (track != null && !publication.muted) {
        return track;
      }
    }

    return null;
  }

  lk.VideoTrack? _firstRemoteLiveKitVideoTrack(lk.Room room) {
    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null && !publication.muted) {
          return track;
        }
      }
    }

    return null;
  }

  // Kept for the legacy peer-to-peer signaling path while LiveKit is the primary media provider.
  // ignore: unused_element
  Future<void> _ensurePeerConnection(VideoCallSessionContext context) async {
    if (_peerConnection != null &&
        context.callSessionId != null &&
        context.callSessionId == state.callSessionId) {
      return;
    }

    await _closePeerConnectionOnly();

    final config = {
      'iceServers': context.iceServers.isNotEmpty
          ? context.iceServers
              .map((server) => {
                    'urls': server.urls,
                    if (server.username != null) 'username': server.username,
                    if (server.credential != null)
                      'credential': server.credential,
                  })
              .toList()
          : [
              {'urls': 'stun:stun.l.google.com:19302'},
            ],
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
      state = state.copyWith(
        hasRemoteVideo: state.requiresVideo && event.track.kind == 'video',
      );
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
      await websocketService.unsubscribeTeleconsultation(
        _subscribedTeleconsultationId!,
        listenerId: _teleconsultationListenerId,
      );
    }

    _subscribedTeleconsultationId = teleconsultationId;
    _teleconsultationListenerId =
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
      await websocketService.unsubscribeCallSession(
        _subscribedCallSessionId!,
        listenerId: _callSessionListenerId,
      );
    }

    _subscribedCallSessionId = callSessionId;
    _callSessionListenerId = await websocketService.subscribeToCallSession(
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
          callSessionId: callSession['id']?.toString() ?? state.callSessionId,
          callType: VideoCallType.fromRaw(callSession['call_type']?.toString()),
          isVideoEnabled:
              VideoCallType.fromRaw(callSession['call_type']?.toString())
                      .requiresVideo
                  ? state.isVideoEnabled
                  : false,
        );
        break;
      case 'webrtc.accepted':
        final callSession = data['call_session'] as Map<String, dynamic>? ?? {};
        state = state.copyWith(
          state: CallState.joining,
          teleconsultationStatus: 'active',
          callSessionId: callSession['id']?.toString() ?? state.callSessionId,
          callType: VideoCallType.fromRaw(callSession['call_type']?.toString()),
          isVideoEnabled:
              VideoCallType.fromRaw(callSession['call_type']?.toString())
                      .requiresVideo
                  ? state.isVideoEnabled
                  : false,
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
    final callType = VideoCallType.fromRaw(
      teleconsultation['call_type']?.toString(),
    );

    state = state.copyWith(
      teleconsultationId: teleconsultationId ?? state.teleconsultationId,
      teleconsultationStatus: status ?? state.teleconsultationStatus,
      callSessionId: callSessionId ?? state.callSessionId,
      conversationId: conversationId ?? state.conversationId,
      callType: callType,
      isVideoEnabled: callType.requiresVideo ? state.isVideoEnabled : false,
      hasRemoteVideo: callType.requiresVideo ? state.hasRemoteVideo : false,
      state: _isTerminalTeleconsultationStatus(status)
          ? CallState.ended
          : (status == 'scheduled' && !isDoctor
              ? CallState.waitingHost
              : state.state),
    );

    if (_isTerminalTeleconsultationStatus(status)) {
      await _terminateFromRemote(_terminalStatusMessage(status));
      return;
    }

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
    return teleconsultationStatus == 'waiting' ||
        teleconsultationStatus == 'ringing' ||
        teleconsultationStatus == 'active';
  }

  bool _isTerminalTeleconsultationStatus(String? teleconsultationStatus) {
    return teleconsultationStatus == 'ended' ||
        teleconsultationStatus == 'cancelled' ||
        teleconsultationStatus == 'expired';
  }

  String? _terminalStatusMessage(String? teleconsultationStatus) {
    return switch (teleconsultationStatus) {
      'cancelled' => 'La téléconsultation a été annulée.',
      'expired' => 'La téléconsultation a expiré.',
      _ => null,
    };
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
      callType: context.callType,
      isVideoEnabled:
          context.callType.requiresVideo ? state.isVideoEnabled : false,
      hasRemoteVideo:
          context.callType.requiresVideo ? state.hasRemoteVideo : false,
      state: _stateForTeleconsultationStatus(context.teleconsultationStatus),
      clearErrorMessage: true,
    );
  }

  CallState _stateForTeleconsultationStatus(String status) {
    if (_isTerminalTeleconsultationStatus(status)) {
      return CallState.ended;
    }
    if (status == 'scheduled' && !isDoctor) {
      return CallState.waitingHost;
    }
    if (status == 'active') {
      return CallState.joining;
    }

    return CallState.ringing;
  }

  void _applyPermissionResult(CallPermissionResult result) {
    state = state.copyWith(
      state: result.isGranted ? state.state : CallState.idle,
      mediaPermissionState: result.state,
      mediaPermissionMessage: result.isGranted ? null : result.userMessage,
      clearMediaPermissionMessage: result.isGranted,
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

  String _resolveFriendlyLiveKitError(Object error) {
    final rawMessage = error.toString().toLowerCase();

    if (rawMessage.contains('401') ||
        rawMessage.contains('unauthorized') ||
        rawMessage.contains('token')) {
      return 'Le jeton LiveKit est invalide ou expiré. Relancez l’appel.';
    }

    if (rawMessage.contains('websocket') ||
        rawMessage.contains('connection') ||
        rawMessage.contains('failed host lookup') ||
        rawMessage.contains('xmlhttprequest') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('refused')) {
      return 'Serveur LiveKit injoignable. Vérifiez côté backend que LIVEKIT_URL '
          'pointe sur une instance accessible depuis le client '
          '(pas ws://127.0.0.1:7880 si l’app tourne dans le navigateur d’une autre machine).';
    }

    if (rawMessage.contains('notallowederror') ||
        rawMessage.contains('permission denied')) {
      return state.requiresVideo
          ? 'Autorisez la caméra et le microphone pour rejoindre l’appel vidéo.'
          : 'Autorisez le microphone pour rejoindre l’appel vocal.';
    }

    return state.requiresVideo
        ? 'Impossible de démarrer l’appel vidéo LiveKit. Détail: $error'
        : 'Impossible de démarrer l’appel vocal LiveKit. Détail: $error';
  }

  Future<_LocalMediaAccessException> _mapLocalMediaError(Object error) async {
    final rawMessage = error.toString().toLowerCase();
    final permissionResult = await permissionService.checkMediaPermissions(
      requireVideo: state.requiresVideo,
    );

    if (rawMessage.contains('notallowederror') ||
        rawMessage.contains('permission denied')) {
      final permissionState = permissionResult.isGranted
          ? CallMediaPermissionState.denied
          : permissionResult.state;
      final userMessage = permissionResult.isGranted
          ? state.requiresVideo
              ? 'L’accès à la caméra ou au microphone a été refusé par l’appareil. '
                  'Vérifiez les autorisations et les réglages de confidentialité, puis réessayez.'
              : 'L’accès au microphone a été refusé par l’appareil. '
                  'Vérifiez les autorisations et les réglages de confidentialité, puis réessayez.'
          : permissionResult.userMessage;

      return _LocalMediaAccessException(
        userMessage: userMessage,
        permissionState: permissionState,
      );
    }

    if (rawMessage.contains('notfounderror')) {
      return _LocalMediaAccessException(
        userMessage: state.requiresVideo
            ? 'Aucune caméra ou aucun microphone compatible n’a été détecté sur cet appareil.'
            : 'Aucun microphone compatible n’a été détecté sur cet appareil.',
      );
    }

    if (rawMessage.contains('notreadableerror') ||
        rawMessage.contains('trackstarterror')) {
      return _LocalMediaAccessException(
        userMessage: state.requiresVideo
            ? 'La caméra ou le microphone est déjà utilisé par une autre application. Fermez-la puis réessayez.'
            : 'Le microphone est déjà utilisé par une autre application. Fermez-la puis réessayez.',
      );
    }

    return _LocalMediaAccessException(
      userMessage: _resolveFriendlyCallError(error),
      permissionState:
          permissionResult.isGranted ? null : permissionResult.state,
    );
  }

  String _resolveFriendlyCallError(Object error) {
    final rawMessage = error.toString().toLowerCase();

    if (rawMessage.contains('notallowederror')) {
      return state.requiresVideo
          ? 'La caméra et le microphone sont nécessaires pour la téléconsultation.'
          : 'Le microphone est nécessaire pour l’appel vocal.';
    }

    if (rawMessage.contains('notreadableerror') ||
        rawMessage.contains('trackstarterror')) {
      return state.requiresVideo
          ? 'Impossible d’utiliser la caméra ou le microphone pour le moment. Fermez les autres applications qui les utilisent puis réessayez.'
          : 'Impossible d’utiliser le microphone pour le moment. Fermez les autres applications qui l’utilisent puis réessayez.';
    }

    if (rawMessage.contains('notfounderror')) {
      return state.requiresVideo
          ? 'Aucune caméra ou aucun microphone compatible n’a été détecté sur cet appareil.'
          : 'Aucun microphone compatible n’a été détecté sur cet appareil.';
    }

    return state.requiresVideo
        ? 'Impossible de démarrer la téléconsultation. Vérifiez la caméra et le microphone puis réessayez.'
        : 'Impossible de démarrer l’appel vocal. Vérifiez le microphone puis réessayez.';
  }

  Future<String?> _validateRequiredMediaDevices({
    required bool requireVideo,
  }) async {
    final devices = await navigator.mediaDevices.enumerateDevices();

    final hasCamera = devices.any((device) => device.kind == 'videoinput');
    final hasMicrophone = devices.any((device) => device.kind == 'audioinput');

    if (requireVideo && !hasCamera && !hasMicrophone) {
      return 'Aucune caméra ni aucun microphone ne sont disponibles sur cet appareil.';
    }

    if (requireVideo && !hasCamera) {
      return 'Aucune caméra disponible sur cet appareil pour la téléconsultation.';
    }

    if (!hasMicrophone) {
      return requireVideo
          ? 'Aucun microphone disponible sur cet appareil pour la téléconsultation.'
          : 'Aucun microphone disponible sur cet appareil pour l’appel vocal.';
    }

    return null;
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

  Future<void> _releaseLocalPreviewStream() async {
    final localTracks = _localStream?.getTracks() ?? const [];
    for (final track in localTracks) {
      track.stop();
    }

    await _localStream?.dispose();
    _localStream = null;
    localRenderer.srcObject = null;
  }

  Future<void> _disconnectLiveKitRoom() async {
    final room = _liveKitRoom;
    final listener = _liveKitListener;

    _liveKitRoom = null;
    _liveKitListener = null;
    _liveKitLocalVideoTrack = null;
    _liveKitRemoteVideoTrack = null;

    // Libère le verrou écran dès qu'on quitte la room (succès ou échec).
    // Sans ça l'écran resterait allumé jusqu'au dispose, ce qui draine la
    // batterie inutilement après la fin de l'appel.
    if (!kIsWeb) {
      await WakelockPlus.disable().catchError((Object e) {
        debugPrint('VideoCall: wakelock disable failed (ignored): $e');
      });
    }

    if (room == null) {
      await listener?.dispose();
      return;
    }

    room.removeListener(_syncLiveKitTracks);
    await room.disconnect();
    await listener?.dispose();
    await room.dispose();
  }

  Future<void> _teardownCallResources({
    required bool disposeRenderers,
  }) async {
    _durationTimer?.cancel();

    await _disconnectLiveKitRoom();

    if (_subscribedCallSessionId != null) {
      await websocketService.unsubscribeCallSession(
        _subscribedCallSessionId!,
        listenerId: _callSessionListenerId,
      );
      _subscribedCallSessionId = null;
      _callSessionListenerId = null;
    }

    if (_subscribedTeleconsultationId != null) {
      await websocketService.unsubscribeTeleconsultation(
        _subscribedTeleconsultationId!,
        listenerId: _teleconsultationListenerId,
      );
      _subscribedTeleconsultationId = null;
      _teleconsultationListenerId = null;
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

class _LocalMediaAccessException implements Exception {
  final String userMessage;
  final CallMediaPermissionState? permissionState;

  const _LocalMediaAccessException({
    required this.userMessage,
    this.permissionState,
  });
}
