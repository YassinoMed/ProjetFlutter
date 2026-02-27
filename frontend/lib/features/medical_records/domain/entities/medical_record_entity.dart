import 'package:equatable/equatable.dart';

class MedicalRecord extends Equatable {
  final String id;
  final String patientUserId;
  final String? doctorUserId;
  final String category;
  final Map<String, dynamic>? metadataEncrypted;
  final DateTime recordedAtUtc;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const MedicalRecord({
    required this.id,
    required this.patientUserId,
    this.doctorUserId,
    required this.category,
    this.metadataEncrypted,
    required this.recordedAtUtc,
    this.expiresAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientUserId,
        doctorUserId,
        category,
        recordedAtUtc,
      ];
}

/// Categories matching the CDC medical record classification
class MedicalRecordCategory {
  static const String consultation = 'consultation';
  static const String prescription = 'prescription';
  static const String labResult = 'lab_result';
  static const String imaging = 'imaging';
  static const String vaccination = 'vaccination';
  static const String allergy = 'allergy';
  static const String surgery = 'surgery';
  static const String other = 'other';

  static const List<String> all = [
    consultation,
    prescription,
    labResult,
    imaging,
    vaccination,
    allergy,
    surgery,
    other,
  ];

  static String label(String category) => switch (category) {
        consultation => 'Consultation',
        prescription => 'Ordonnance',
        labResult => 'Résultat de laboratoire',
        imaging => 'Imagerie',
        vaccination => 'Vaccination',
        allergy => 'Allergie',
        surgery => 'Chirurgie',
        other => 'Autre',
        _ => category,
      };
}
