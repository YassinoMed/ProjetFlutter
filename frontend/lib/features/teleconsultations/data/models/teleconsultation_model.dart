import '../../domain/entities/teleconsultation_entity.dart';

class TeleconsultationParticipantModel extends TeleconsultationParticipantEntity {
  const TeleconsultationParticipantModel({
    required super.userId,
    required super.role,
    super.invitedAtUtc,
    super.joinedAtUtc,
    super.leftAtUtc,
  });

  factory TeleconsultationParticipantModel.fromJson(Map<String, dynamic> json) {
    return TeleconsultationParticipantModel(
      userId: json['user_id'].toString(),
      role: json['role']?.toString() ?? 'UNKNOWN',
      invitedAtUtc: DateTime.tryParse(json['invited_at_utc']?.toString() ?? ''),
      joinedAtUtc: DateTime.tryParse(json['joined_at_utc']?.toString() ?? ''),
      leftAtUtc: DateTime.tryParse(json['left_at_utc']?.toString() ?? ''),
    );
  }
}

class TeleconsultationEventModel extends TeleconsultationEventEntity {
  const TeleconsultationEventModel({
    required super.id,
    required super.eventName,
    super.occurredAtUtc,
    super.actorUserId,
    super.targetUserId,
    super.payload,
  });

  factory TeleconsultationEventModel.fromJson(Map<String, dynamic> json) {
    return TeleconsultationEventModel(
      id: json['id'] as int? ?? 0,
      eventName: json['event_name']?.toString() ?? 'unknown',
      occurredAtUtc:
          DateTime.tryParse(json['occurred_at_utc']?.toString() ?? ''),
      actorUserId: json['actor_user_id']?.toString(),
      targetUserId: json['target_user_id']?.toString(),
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

class TeleconsultationModel extends TeleconsultationEntity {
  const TeleconsultationModel({
    required super.id,
    required super.appointmentId,
    required super.patientUserId,
    required super.doctorUserId,
    required super.callType,
    required super.status,
    super.conversationId,
    super.currentCallSessionId,
    super.scheduledStartsAtUtc,
    super.scheduledEndsAtUtc,
    super.startedAtUtc,
    super.endedAtUtc,
    super.expiresAtUtc,
    super.cancellationReason,
    super.failureReason,
    super.participants,
  });

  factory TeleconsultationModel.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TeleconsultationParticipantModel.fromJson)
        .toList();

    return TeleconsultationModel(
      id: json['id'].toString(),
      appointmentId: json['appointment_id'].toString(),
      conversationId: json['conversation_id']?.toString(),
      currentCallSessionId: json['current_call_session_id']?.toString(),
      patientUserId: json['patient_user_id'].toString(),
      doctorUserId: json['doctor_user_id'].toString(),
      callType: json['call_type']?.toString() ?? 'VIDEO',
      status: json['status']?.toString() ?? 'scheduled',
      scheduledStartsAtUtc:
          DateTime.tryParse(json['scheduled_starts_at_utc']?.toString() ?? ''),
      scheduledEndsAtUtc:
          DateTime.tryParse(json['scheduled_ends_at_utc']?.toString() ?? ''),
      startedAtUtc: DateTime.tryParse(json['started_at_utc']?.toString() ?? ''),
      endedAtUtc: DateTime.tryParse(json['ended_at_utc']?.toString() ?? ''),
      expiresAtUtc: DateTime.tryParse(json['expires_at_utc']?.toString() ?? ''),
      cancellationReason: json['cancellation_reason']?.toString(),
      failureReason: json['failure_reason']?.toString(),
      participants: participants,
    );
  }
}
