/// Providers Riverpod pour la salle d'attente virtuelle.
///
/// Démo PFE : un store en mémoire orchestre les états patient↔médecin.
/// En production, remplacer par un repository qui POST/PATCH sur Laravel
/// et qui écoute les events Reverb `waiting-room.doctor.{id}.updated`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/waiting_room_session.dart';

class WaitingRoomStore extends StateNotifier<List<WaitingRoomSession>> {
  WaitingRoomStore() : super(const []);

  /// Patient rejoint la salle. Si une session waiting existe déjà pour
  /// cet appointment, on la réutilise (évite les doublons).
  WaitingRoomSession join({
    required String appointmentId,
    required String teleconsultationId,
    required String patientId,
    required String patientName,
    String? patientAvatarUrl,
    required String doctorId,
    required String doctorName,
    String? reason,
  }) {
    final existing = state.firstWhere(
      (s) => s.appointmentId == appointmentId && s.patientId == patientId,
      orElse: () => WaitingRoomSession(
        id: '',
        appointmentId: appointmentId,
        teleconsultationId: teleconsultationId,
        patientId: patientId,
        patientName: patientName,
        patientAvatarUrl: patientAvatarUrl,
        doctorId: doctorId,
        doctorName: doctorName,
        joinedAt: DateTime.now().toUtc(),
        reason: reason,
      ),
    );

    final session = existing.id.isEmpty
        ? WaitingRoomSession(
            id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
            appointmentId: appointmentId,
            teleconsultationId: teleconsultationId,
            patientId: patientId,
            patientName: patientName,
            patientAvatarUrl: patientAvatarUrl,
            doctorId: doctorId,
            doctorName: doctorName,
            joinedAt: DateTime.now().toUtc(),
            reason: reason,
          )
        : existing.status.isTerminal
            // Recréer une nouvelle session si la précédente est terminale.
            ? WaitingRoomSession(
                id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
                appointmentId: appointmentId,
                teleconsultationId: teleconsultationId,
                patientId: patientId,
                patientName: patientName,
                patientAvatarUrl: patientAvatarUrl,
                doctorId: doctorId,
                doctorName: doctorName,
                joinedAt: DateTime.now().toUtc(),
                reason: reason,
              )
            : existing;

    final updated = state
        .where((s) => s.id != session.id)
        .toList(growable: true)
      ..add(session);
    state = updated;
    return session;
  }

  void _replace(WaitingRoomSession session) {
    state = state.map((s) => s.id == session.id ? session : s).toList();
  }

  void admit(String sessionId) {
    final s = _byId(sessionId);
    if (s == null) return;
    _replace(s.copyWith(
      status: WaitingRoomStatus.admitted,
      processedAt: DateTime.now().toUtc(),
    ));
  }

  void reject(String sessionId, {String? reason}) {
    final s = _byId(sessionId);
    if (s == null) return;
    _replace(s.copyWith(
      status: WaitingRoomStatus.rejected,
      processedAt: DateTime.now().toUtc(),
      rejectionReason: reason,
    ));
  }

  void reschedule(String sessionId, {required DateTime to, String? reason}) {
    final s = _byId(sessionId);
    if (s == null) return;
    _replace(s.copyWith(
      status: WaitingRoomStatus.rejected, // = pas admis pour cet appel
      processedAt: DateTime.now().toUtc(),
      rejectionReason: reason ?? 'Reporté',
      rescheduledTo: to,
    ));
  }

  void cancel(String sessionId) {
    final s = _byId(sessionId);
    if (s == null) return;
    _replace(s.copyWith(
      status: WaitingRoomStatus.cancelled,
      processedAt: DateTime.now().toUtc(),
    ));
  }

  WaitingRoomSession? _byId(String id) {
    for (final s in state) {
      if (s.id == id) return s;
    }
    return null;
  }

  WaitingRoomSession? byId(String id) => _byId(id);

  List<WaitingRoomSession> waitingFor(String doctorId) {
    return state
        .where(
            (s) => s.doctorId == doctorId && s.status == WaitingRoomStatus.waiting)
        .toList();
  }

  WaitingRoomSession? activeForPatient(String patientId) {
    for (final s in state) {
      if (s.patientId == patientId && !s.status.isTerminal) {
        return s;
      }
    }
    return null;
  }
}

final waitingRoomStoreProvider =
    StateNotifierProvider<WaitingRoomStore, List<WaitingRoomSession>>((ref) {
  return WaitingRoomStore();
});

/// Watch la file d'attente d'un médecin (filtre status=waiting).
final waitingPatientsForDoctorProvider =
    Provider.family<List<WaitingRoomSession>, String>((ref, doctorId) {
  final all = ref.watch(waitingRoomStoreProvider);
  return all
      .where(
          (s) => s.doctorId == doctorId && s.status == WaitingRoomStatus.waiting)
      .toList()
    ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
});

/// Watch une session par id (utilisé par la page patient pour
/// déclencher l'auto-redirection vers l'appel à l'admission).
final waitingSessionByIdProvider =
    Provider.family<WaitingRoomSession?, String>((ref, sessionId) {
  final all = ref.watch(waitingRoomStoreProvider);
  for (final s in all) {
    if (s.id == sessionId) return s;
  }
  return null;
});
