/// Tests unitaires de la couche pure du module appel vidéo.
///
/// `VideoCallNotifier` lui-même est très couplé à `flutter_webrtc` et
/// LiveKit, ce qui nécessite un harnais d'intégration pour être testé
/// proprement. Ce fichier teste à la place les briques pures qui
/// ancrent le state machine : enums [VideoCallType], [CallState],
/// [CallMediaPermissionState] et l'entité de state [VideoCallEntity]
/// (copyWith, derived getters, clear flags).
///
/// Ces tests sont stables (pas de platform channel) et couvrent les
/// invariants utilisés partout dans l'UI d'appel.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';

void main() {
  group('VideoCallType', () {
    test('fromRaw "AUDIO" → audio (insensible à la casse)', () {
      expect(VideoCallType.fromRaw('AUDIO'), VideoCallType.audio);
      expect(VideoCallType.fromRaw('audio'), VideoCallType.audio);
      expect(VideoCallType.fromRaw('Audio'), VideoCallType.audio);
    });

    test('fromRaw "VIDEO" / autre / null → video (défaut)', () {
      expect(VideoCallType.fromRaw('VIDEO'), VideoCallType.video);
      expect(VideoCallType.fromRaw('video'), VideoCallType.video);
      expect(VideoCallType.fromRaw('unknown'), VideoCallType.video);
      expect(VideoCallType.fromRaw(null), VideoCallType.video);
    });

    test('rawValue est round-trippable avec fromRaw', () {
      for (final type in VideoCallType.values) {
        expect(VideoCallType.fromRaw(type.rawValue), type);
      }
    });

    test('requiresVideo → true uniquement pour video', () {
      expect(VideoCallType.video.requiresVideo, isTrue);
      expect(VideoCallType.audio.requiresVideo, isFalse);
    });

    test('labelFr humain pour affichage', () {
      expect(VideoCallType.audio.labelFr, 'audio');
      expect(VideoCallType.video.labelFr, 'vidéo');
    });
  });

  group('CallState', () {
    test('contient les 9 états attendus du state machine', () {
      expect(CallState.values, hasLength(9));
      // L'ordre est volontairement préservé : modifier l'ordre est un
      // breaking change pour la persistance/serialisation.
      expect(CallState.values, containsAllInOrder(<CallState>[
        CallState.idle,
        CallState.resolvingSession,
        CallState.waitingHost,
        CallState.ringing,
        CallState.joining,
        CallState.connected,
        CallState.reconnecting,
        CallState.ended,
        CallState.error,
      ]));
    });
  });

  group('CallMediaPermissionState', () {
    test('inclut le cas permanentlyDenied (déclenche openSettings)', () {
      expect(CallMediaPermissionState.values,
          contains(CallMediaPermissionState.permanentlyDenied));
    });
  });

  group('VideoCallEntity', () {
    const appointment = 'appt-123';

    test('valeurs par défaut sensées', () {
      const entity = VideoCallEntity(appointmentId: appointment);

      expect(entity.appointmentId, appointment);
      expect(entity.state, CallState.idle);
      expect(entity.callType, VideoCallType.video);
      expect(entity.isAudioMuted, isFalse);
      expect(entity.isVideoEnabled, isTrue);
      expect(entity.isFrontCamera, isTrue);
      expect(entity.isSpeakerOn, isTrue);
      expect(entity.hasRemoteVideo, isFalse);
      expect(entity.duration, Duration.zero);
      expect(entity.errorMessage, isNull);
      expect(entity.mediaPermissionState, CallMediaPermissionState.unknown);
    });

    test('hasMediaPermissions est vrai uniquement quand granted', () {
      const granted = VideoCallEntity(
        appointmentId: appointment,
        mediaPermissionState: CallMediaPermissionState.granted,
      );
      const denied = VideoCallEntity(
        appointmentId: appointment,
        mediaPermissionState: CallMediaPermissionState.denied,
      );
      const unknown = VideoCallEntity(appointmentId: appointment);

      expect(granted.hasMediaPermissions, isTrue);
      expect(denied.hasMediaPermissions, isFalse);
      expect(unknown.hasMediaPermissions, isFalse);
    });

    test('isAudioOnly et requiresVideo dérivent du callType', () {
      const audio = VideoCallEntity(
        appointmentId: appointment,
        callType: VideoCallType.audio,
      );
      const video = VideoCallEntity(
        appointmentId: appointment,
        callType: VideoCallType.video,
      );

      expect(audio.isAudioOnly, isTrue);
      expect(audio.requiresVideo, isFalse);
      expect(video.isAudioOnly, isFalse);
      expect(video.requiresVideo, isTrue);
    });

    test(
        'shouldOpenPermissionSettings → uniquement quand permanentlyDenied',
        () {
      const perm = VideoCallEntity(
        appointmentId: appointment,
        mediaPermissionState: CallMediaPermissionState.permanentlyDenied,
      );
      const denied = VideoCallEntity(
        appointmentId: appointment,
        mediaPermissionState: CallMediaPermissionState.denied,
      );

      expect(perm.shouldOpenPermissionSettings, isTrue);
      expect(denied.shouldOpenPermissionSettings, isFalse);
    });

    test('copyWith met à jour les champs ciblés et garde le reste', () {
      const initial = VideoCallEntity(
        appointmentId: appointment,
        state: CallState.idle,
        isAudioMuted: false,
      );

      final updated = initial.copyWith(
        state: CallState.connected,
        isAudioMuted: true,
      );

      expect(updated.state, CallState.connected);
      expect(updated.isAudioMuted, isTrue);
      // Champs non modifiés
      expect(updated.appointmentId, appointment);
      expect(updated.isVideoEnabled, isTrue);
      expect(updated.callType, VideoCallType.video);
    });

    test('clearErrorMessage force errorMessage à null', () {
      const withErr = VideoCallEntity(
        appointmentId: appointment,
        state: CallState.error,
        errorMessage: 'LiveKit injoignable',
      );

      final cleared = withErr.copyWith(
        state: CallState.idle,
        clearErrorMessage: true,
      );

      expect(cleared.state, CallState.idle);
      expect(cleared.errorMessage, isNull);
    });

    test('clearMediaPermissionMessage force le message à null', () {
      const withMsg = VideoCallEntity(
        appointmentId: appointment,
        mediaPermissionMessage: 'Permission refusée',
      );

      final cleared = withMsg.copyWith(clearMediaPermissionMessage: true);
      expect(cleared.mediaPermissionMessage, isNull);
    });

    test('Equatable: même appointmentId + même state → équivalents', () {
      const a = VideoCallEntity(
        appointmentId: appointment,
        state: CallState.connected,
      );
      const b = VideoCallEntity(
        appointmentId: appointment,
        state: CallState.connected,
      );
      const c = VideoCallEntity(
        appointmentId: appointment,
        state: CallState.idle,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
