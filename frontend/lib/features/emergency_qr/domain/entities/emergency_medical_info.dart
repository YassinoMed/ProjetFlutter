import 'package:equatable/equatable.dart';

class EmergencyMedicalInfo extends Equatable {
  final String patientId;
  final String patientName;
  final bool enabled;
  final String bloodType;
  final List<String> importantAllergies;
  final List<String> chronicConditions;
  final List<String> criticalTreatments;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final DateTime updatedAt;

  const EmergencyMedicalInfo({
    required this.patientId,
    required this.patientName,
    this.enabled = false,
    this.bloodType = '',
    this.importantAllergies = const [],
    this.chronicConditions = const [],
    this.criticalTreatments = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    required this.updatedAt,
  });

  bool get hasVitalData =>
      bloodType.trim().isNotEmpty ||
      importantAllergies.isNotEmpty ||
      chronicConditions.isNotEmpty ||
      criticalTreatments.isNotEmpty ||
      emergencyContactName.trim().isNotEmpty ||
      emergencyContactPhone.trim().isNotEmpty;

  EmergencyMedicalInfo copyWith({
    String? patientId,
    String? patientName,
    bool? enabled,
    String? bloodType,
    List<String>? importantAllergies,
    List<String>? chronicConditions,
    List<String>? criticalTreatments,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? updatedAt,
  }) {
    return EmergencyMedicalInfo(
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      enabled: enabled ?? this.enabled,
      bloodType: bloodType ?? this.bloodType,
      importantAllergies: importantAllergies ?? this.importantAllergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      criticalTreatments: criticalTreatments ?? this.criticalTreatments,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        patientId,
        patientName,
        enabled,
        bloodType,
        importantAllergies,
        chronicConditions,
        criticalTreatments,
        emergencyContactName,
        emergencyContactPhone,
        updatedAt,
      ];
}
