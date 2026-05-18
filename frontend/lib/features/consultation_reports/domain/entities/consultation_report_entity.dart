/// Compte rendu médical structuré rédigé par le médecin après une
/// téléconsultation/consultation.
///
/// Distingue la **partie partagée** avec le patient (motif, résumé,
/// conclusion, traitement, recommandations, date de contrôle) et les
/// **notes privées médecin** qui ne sont JAMAIS exposées au patient.
///
/// Cette séparation est appliquée :
///   - côté UI : `ConsultationReportDetailPage` filtre selon le rôle
///   - côté domaine : le getter [toPatientView] retourne une copie sans
///     les notes privées (utile pour partage / export PDF patient)
///
/// Stockage local en mémoire pour la démo PFE (cf. provider). Migration
/// backend planifiée : table `consultation_reports` avec
/// `private_notes` chiffré côté serveur.
library;

import 'package:equatable/equatable.dart';

class ConsultationReport extends Equatable {
  final String id;
  final String teleconsultationId;
  final String doctorId;
  final String doctorName;
  final String? doctorSpeciality;
  final String patientId;
  final String patientName;
  final DateTime consultationAt;

  // ── Partie partagée avec le patient ──────────────────────────
  final String reason; // motif
  final String summary; // résumé consultation
  final String? conclusion; // conclusion médicale (pas un diagnostic ferme)
  final String? treatment; // traitement recommandé
  final String? recommendations; // hygiène de vie, suivi, etc.
  final DateTime? followUpAt; // date de contrôle suggérée

  // ── Réservé au médecin ──────────────────────────────────────
  final String? privateNotes;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConsultationReport({
    required this.id,
    required this.teleconsultationId,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpeciality,
    required this.patientId,
    required this.patientName,
    required this.consultationAt,
    required this.reason,
    required this.summary,
    this.conclusion,
    this.treatment,
    this.recommendations,
    this.followUpAt,
    this.privateNotes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Retourne une copie sans les notes privées — à utiliser pour toute
  /// projection visible par le patient (UI, export, partage).
  ConsultationReport toPatientView() {
    if (privateNotes == null) return this;
    return ConsultationReport(
      id: id,
      teleconsultationId: teleconsultationId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpeciality: doctorSpeciality,
      patientId: patientId,
      patientName: patientName,
      consultationAt: consultationAt,
      reason: reason,
      summary: summary,
      conclusion: conclusion,
      treatment: treatment,
      recommendations: recommendations,
      followUpAt: followUpAt,
      // privateNotes intentionnellement omis.
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ConsultationReport copyWith({
    String? id,
    String? doctorName,
    String? doctorSpeciality,
    String? patientName,
    DateTime? consultationAt,
    String? reason,
    String? summary,
    String? conclusion,
    String? treatment,
    String? recommendations,
    DateTime? followUpAt,
    String? privateNotes,
    DateTime? updatedAt,
  }) {
    return ConsultationReport(
      id: id ?? this.id,
      teleconsultationId: teleconsultationId,
      doctorId: doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpeciality: doctorSpeciality ?? this.doctorSpeciality,
      patientId: patientId,
      patientName: patientName ?? this.patientName,
      consultationAt: consultationAt ?? this.consultationAt,
      reason: reason ?? this.reason,
      summary: summary ?? this.summary,
      conclusion: conclusion ?? this.conclusion,
      treatment: treatment ?? this.treatment,
      recommendations: recommendations ?? this.recommendations,
      followUpAt: followUpAt ?? this.followUpAt,
      privateNotes: privateNotes ?? this.privateNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get publicReference => 'CR-${id.substring(0, 8).toUpperCase()}';

  @override
  List<Object?> get props => [
        id,
        teleconsultationId,
        doctorId,
        doctorName,
        doctorSpeciality,
        patientId,
        patientName,
        consultationAt,
        reason,
        summary,
        conclusion,
        treatment,
        recommendations,
        followUpAt,
        privateNotes,
        createdAt,
        updatedAt,
      ];
}
