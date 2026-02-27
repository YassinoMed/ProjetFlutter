import 'package:mediconnect_pro/features/medical_records/domain/entities/medical_record_entity.dart';

class MedicalRecordModel extends MedicalRecord {
  const MedicalRecordModel({
    required super.id,
    required super.patientUserId,
    super.doctorUserId,
    required super.category,
    super.metadataEncrypted,
    required super.recordedAtUtc,
    super.expiresAt,
    required super.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id']?.toString() ?? '',
      patientUserId: json['patient_user_id']?.toString() ?? '',
      doctorUserId: json['doctor_user_id']?.toString(),
      category: json['category']?.toString() ?? 'other',
      metadataEncrypted: json['metadata_encrypted'] as Map<String, dynamic>?,
      recordedAtUtc: DateTime.parse(
          json['recorded_at_utc'] ?? DateTime.now().toIso8601String()),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'metadata_encrypted': metadataEncrypted,
        'recorded_at_utc': recordedAtUtc.toUtc().toIso8601String(),
      };
}
