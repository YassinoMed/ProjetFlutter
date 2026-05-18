/// Entités domaine pour les ordonnances médicales numériques.
///
/// Le `Prescription` regroupe les métadonnées (médecin, patient, date) et
/// une liste de `PrescriptionItem` (médicaments avec dosage). Aucune
/// persistance backend pour la démo PFE — le `PrescriptionRepository`
/// (en mémoire) suffit pour la soutenance. Migrer vers une table dédiée
/// `prescriptions` + `prescription_items` est documenté dans
/// docs/project-evaluation-improvements.md.
library;

import 'package:equatable/equatable.dart';

class PrescriptionItem extends Equatable {
  final String name;
  final String dosage; // ex: "500mg"
  final String frequency; // ex: "3 fois par jour"
  final String duration; // ex: "7 jours"
  final String? notes;

  const PrescriptionItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.notes,
  });

  PrescriptionItem copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? notes,
  }) {
    return PrescriptionItem(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        if (notes != null) 'notes': notes,
      };

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      PrescriptionItem(
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as String,
        duration: json['duration'] as String,
        notes: json['notes'] as String?,
      );

  @override
  List<Object?> get props => [name, dosage, frequency, duration, notes];
}

class Prescription extends Equatable {
  final String id;
  final String doctorId;
  final String doctorName;
  final String? doctorSpeciality;
  final String? doctorLicenseNumber;
  final String patientId;
  final String patientName;
  final DateTime issuedAt;
  final List<PrescriptionItem> items;
  final String? additionalNotes;

  const Prescription({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpeciality,
    this.doctorLicenseNumber,
    required this.patientId,
    required this.patientName,
    required this.issuedAt,
    required this.items,
    this.additionalNotes,
  });

  Prescription copyWith({
    String? id,
    String? doctorName,
    String? doctorSpeciality,
    String? doctorLicenseNumber,
    String? patientName,
    DateTime? issuedAt,
    List<PrescriptionItem>? items,
    String? additionalNotes,
  }) {
    return Prescription(
      id: id ?? this.id,
      doctorId: doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpeciality: doctorSpeciality ?? this.doctorSpeciality,
      doctorLicenseNumber: doctorLicenseNumber ?? this.doctorLicenseNumber,
      patientId: patientId,
      patientName: patientName ?? this.patientName,
      issuedAt: issuedAt ?? this.issuedAt,
      items: items ?? this.items,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  /// Identifiant lisible pour le QR code / vérification.
  String get publicReference => 'MED-${id.substring(0, 8).toUpperCase()}';

  @override
  List<Object?> get props => [
        id,
        doctorId,
        doctorName,
        doctorSpeciality,
        doctorLicenseNumber,
        patientId,
        patientName,
        issuedAt,
        items,
        additionalNotes,
      ];
}
