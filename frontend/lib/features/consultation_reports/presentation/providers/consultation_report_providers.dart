/// Providers Riverpod pour les comptes rendus de consultation.
///
/// Démo PFE : store en mémoire ([StateNotifier] sur une liste de
/// [ConsultationReport]). Migration backend prévue : table
/// `consultation_reports` avec `private_notes` chiffré côté serveur
/// (cf. project-evaluation-improvements).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/consultation_report_entity.dart';

class ConsultationReportStore
    extends StateNotifier<List<ConsultationReport>> {
  ConsultationReportStore() : super(const []);

  void save(ConsultationReport report) {
    final updated = state
        .where((r) => r.id != report.id)
        .toList(growable: true)
      ..add(report);
    updated.sort((a, b) => b.consultationAt.compareTo(a.consultationAt));
    state = updated;
  }

  ConsultationReport? byId(String id) {
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  ConsultationReport? byTeleconsultation(String teleconsultationId) {
    for (final r in state) {
      if (r.teleconsultationId == teleconsultationId) return r;
    }
    return null;
  }

  List<ConsultationReport> forPatient(String patientId) {
    return state.where((r) => r.patientId == patientId).toList();
  }

  List<ConsultationReport> forDoctor(String doctorId) {
    return state.where((r) => r.doctorId == doctorId).toList();
  }
}

final consultationReportStoreProvider = StateNotifierProvider<
    ConsultationReportStore, List<ConsultationReport>>((ref) {
  return ConsultationReportStore();
});

/// Watch un compte rendu par teleconsultationId. Retourne `null` s'il n'y
/// en a pas encore. Pratique pour conditionner l'UI « Créer compte rendu »
/// vs « Voir compte rendu » sur la page détail téléconsultation.
final consultationReportByTeleconsultationProvider =
    Provider.family<ConsultationReport?, String>((ref, teleconsultationId) {
  final reports = ref.watch(consultationReportStoreProvider);
  for (final r in reports) {
    if (r.teleconsultationId == teleconsultationId) return r;
  }
  return null;
});
