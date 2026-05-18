/// Providers Riverpod pour la feature Ordonnances.
///
/// **Démo PFE** : stockage en mémoire (Map) — pas de backend pour cette
/// itération. Migrer vers `POST /api/prescriptions` est documenté dans
/// docs/project-evaluation-improvements.md (priorité 2.3 future sprint).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/prescription_pdf_service.dart';
import '../../domain/entities/prescription_entity.dart';

class PrescriptionStore extends StateNotifier<List<Prescription>> {
  PrescriptionStore() : super(const []);

  void save(Prescription prescription) {
    final filtered =
        state.where((p) => p.id != prescription.id).toList(growable: true)
          ..add(prescription);
    filtered.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    state = filtered;
  }

  Prescription? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Prescription> forPatient(String patientId) {
    return state.where((p) => p.patientId == patientId).toList();
  }

  List<Prescription> byDoctor(String doctorId) {
    return state.where((p) => p.doctorId == doctorId).toList();
  }
}

final prescriptionStoreProvider =
    StateNotifierProvider<PrescriptionStore, List<Prescription>>((ref) {
  return PrescriptionStore();
});

final prescriptionPdfServiceProvider = Provider<PrescriptionPdfService>((ref) {
  return const PrescriptionPdfService();
});
