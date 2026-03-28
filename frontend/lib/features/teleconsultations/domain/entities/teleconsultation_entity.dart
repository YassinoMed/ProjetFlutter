import 'package:equatable/equatable.dart';

class TeleconsultationParticipantEntity extends Equatable {
  final String userId;
  final String role;
  final DateTime? invitedAtUtc;
  final DateTime? joinedAtUtc;
  final DateTime? leftAtUtc;

  const TeleconsultationParticipantEntity({
    required this.userId,
    required this.role,
    this.invitedAtUtc,
    this.joinedAtUtc,
    this.leftAtUtc,
  });

  @override
  List<Object?> get props => [userId, role, invitedAtUtc, joinedAtUtc, leftAtUtc];
}

class TeleconsultationEventEntity extends Equatable {
  final int id;
  final String eventName;
  final DateTime? occurredAtUtc;
  final String? actorUserId;
  final String? targetUserId;
  final Map<String, dynamic> payload;

  const TeleconsultationEventEntity({
    required this.id,
    required this.eventName,
    this.occurredAtUtc,
    this.actorUserId,
    this.targetUserId,
    this.payload = const {},
  });

  @override
  List<Object?> get props => [
        id,
        eventName,
        occurredAtUtc,
        actorUserId,
        targetUserId,
        payload,
      ];
}

class TeleconsultationEntity extends Equatable {
  final String id;
  final String appointmentId;
  final String? conversationId;
  final String? currentCallSessionId;
  final String patientUserId;
  final String doctorUserId;
  final String callType;
  final String status;
  final DateTime? scheduledStartsAtUtc;
  final DateTime? scheduledEndsAtUtc;
  final DateTime? startedAtUtc;
  final DateTime? endedAtUtc;
  final DateTime? expiresAtUtc;
  final String? cancellationReason;
  final String? failureReason;
  final List<TeleconsultationParticipantEntity> participants;

  const TeleconsultationEntity({
    required this.id,
    required this.appointmentId,
    required this.patientUserId,
    required this.doctorUserId,
    required this.callType,
    required this.status,
    this.conversationId,
    this.currentCallSessionId,
    this.scheduledStartsAtUtc,
    this.scheduledEndsAtUtc,
    this.startedAtUtc,
    this.endedAtUtc,
    this.expiresAtUtc,
    this.cancellationReason,
    this.failureReason,
    this.participants = const [],
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        conversationId,
        currentCallSessionId,
        patientUserId,
        doctorUserId,
        callType,
        status,
        scheduledStartsAtUtc,
        scheduledEndsAtUtc,
        startedAtUtc,
        endedAtUtc,
        expiresAtUtc,
        cancellationReason,
        failureReason,
        participants,
      ];
}
