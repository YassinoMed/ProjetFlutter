import 'package:equatable/equatable.dart';

class PreConsultationQuestionnaire extends Equatable {
  final String appointmentId;
  final String patientId;
  final String? doctorId;
  final String reason;
  final String symptoms;
  final String symptomDuration;
  final int painLevel;
  final bool hasFever;
  final String medicationsTaken;
  final String allergies;
  final List<String> linkedDocumentIds;
  final String freeMessage;
  final DateTime updatedAt;

  const PreConsultationQuestionnaire({
    required this.appointmentId,
    required this.patientId,
    this.doctorId,
    required this.reason,
    required this.symptoms,
    required this.symptomDuration,
    required this.painLevel,
    required this.hasFever,
    required this.medicationsTaken,
    required this.allergies,
    this.linkedDocumentIds = const [],
    required this.freeMessage,
    required this.updatedAt,
  });

  bool get hasClinicalContent =>
      reason.trim().isNotEmpty ||
      symptoms.trim().isNotEmpty ||
      symptomDuration.trim().isNotEmpty ||
      medicationsTaken.trim().isNotEmpty ||
      allergies.trim().isNotEmpty ||
      freeMessage.trim().isNotEmpty ||
      linkedDocumentIds.isNotEmpty;

  PreConsultationQuestionnaire copyWith({
    String? appointmentId,
    String? patientId,
    String? doctorId,
    String? reason,
    String? symptoms,
    String? symptomDuration,
    int? painLevel,
    bool? hasFever,
    String? medicationsTaken,
    String? allergies,
    List<String>? linkedDocumentIds,
    String? freeMessage,
    DateTime? updatedAt,
  }) {
    return PreConsultationQuestionnaire(
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      reason: reason ?? this.reason,
      symptoms: symptoms ?? this.symptoms,
      symptomDuration: symptomDuration ?? this.symptomDuration,
      painLevel: painLevel ?? this.painLevel,
      hasFever: hasFever ?? this.hasFever,
      medicationsTaken: medicationsTaken ?? this.medicationsTaken,
      allergies: allergies ?? this.allergies,
      linkedDocumentIds: linkedDocumentIds ?? this.linkedDocumentIds,
      freeMessage: freeMessage ?? this.freeMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        appointmentId,
        patientId,
        doctorId,
        reason,
        symptoms,
        symptomDuration,
        painLevel,
        hasFever,
        medicationsTaken,
        allergies,
        linkedDocumentIds,
        freeMessage,
        updatedAt,
      ];
}
