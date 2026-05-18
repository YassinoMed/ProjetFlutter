/// Session de salle d'attente virtuelle pour une téléconsultation.
///
/// Le patient crée une session quand il clique « Rejoindre la salle
/// d'attente ». Le médecin la voit dans sa liste et peut Admettre,
/// Refuser ou Reporter. À l'admission, l'UI patient redirige vers la
/// page d'appel correspondante.
///
/// Démo PFE : stockage en mémoire. Migration backend prévue : table
/// `waiting_room_sessions` + canal Reverb `waiting-room.doctor.{id}`
/// pour notification temps réel.
library;

import 'package:equatable/equatable.dart';

enum WaitingRoomStatus {
  /// Patient présent dans la salle d'attente, le médecin ne l'a pas
  /// encore traité.
  waiting,

  /// Le médecin a accepté le patient → l'appel peut démarrer.
  admitted,

  /// Le médecin a refusé.
  rejected,

  /// Le patient a quitté la salle d'attente avant traitement.
  cancelled,

  /// La session a expiré (TTL dépassé, par ex. 30 min sans action).
  expired;

  String get labelFr => switch (this) {
        waiting => 'En attente',
        admitted => 'Admis',
        rejected => 'Refusé',
        cancelled => 'Annulé',
        expired => 'Expiré',
      };

  bool get isTerminal =>
      this == rejected || this == cancelled || this == expired;
}

class WaitingRoomSession extends Equatable {
  final String id;
  final String appointmentId;
  final String teleconsultationId;
  final String patientId;
  final String patientName;
  final String? patientAvatarUrl;
  final String doctorId;
  final String doctorName;
  final WaitingRoomStatus status;
  final String? reason; // motif présenté par le patient
  final DateTime joinedAt;
  final DateTime? processedAt;
  final String? rejectionReason; // si le médecin refuse
  final DateTime? rescheduledTo; // si le médecin propose un report

  const WaitingRoomSession({
    required this.id,
    required this.appointmentId,
    required this.teleconsultationId,
    required this.patientId,
    required this.patientName,
    this.patientAvatarUrl,
    required this.doctorId,
    required this.doctorName,
    this.status = WaitingRoomStatus.waiting,
    this.reason,
    required this.joinedAt,
    this.processedAt,
    this.rejectionReason,
    this.rescheduledTo,
  });

  Duration get waitingDuration =>
      (processedAt ?? DateTime.now().toUtc()).difference(joinedAt);

  WaitingRoomSession copyWith({
    WaitingRoomStatus? status,
    DateTime? processedAt,
    String? rejectionReason,
    DateTime? rescheduledTo,
  }) {
    return WaitingRoomSession(
      id: id,
      appointmentId: appointmentId,
      teleconsultationId: teleconsultationId,
      patientId: patientId,
      patientName: patientName,
      patientAvatarUrl: patientAvatarUrl,
      doctorId: doctorId,
      doctorName: doctorName,
      status: status ?? this.status,
      reason: reason,
      joinedAt: joinedAt,
      processedAt: processedAt ?? this.processedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rescheduledTo: rescheduledTo ?? this.rescheduledTo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        teleconsultationId,
        patientId,
        patientName,
        patientAvatarUrl,
        doctorId,
        doctorName,
        status,
        reason,
        joinedAt,
        processedAt,
        rejectionReason,
        rescheduledTo,
      ];
}
