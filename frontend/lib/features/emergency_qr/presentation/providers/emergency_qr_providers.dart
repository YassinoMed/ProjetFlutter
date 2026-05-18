import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/emergency_qr_service.dart';
import '../../domain/entities/emergency_medical_info.dart';

class EmergencyMedicalInfoStore
    extends StateNotifier<Map<String, EmergencyMedicalInfo>> {
  EmergencyMedicalInfoStore() : super(const {});

  EmergencyMedicalInfo getOrCreate({
    required String patientId,
    required String patientName,
  }) {
    return state[patientId] ??
        EmergencyMedicalInfo(
          patientId: patientId,
          patientName: patientName,
          updatedAt: DateTime.now().toUtc(),
        );
  }

  void save(EmergencyMedicalInfo info) {
    state = {
      ...state,
      info.patientId: info.copyWith(updatedAt: DateTime.now().toUtc()),
    };
  }
}

final emergencyMedicalInfoStoreProvider = StateNotifierProvider<
    EmergencyMedicalInfoStore, Map<String, EmergencyMedicalInfo>>((ref) {
  return EmergencyMedicalInfoStore();
});

final emergencyQrServiceProvider = Provider<EmergencyQrService>((ref) {
  return const EmergencyQrService();
});

final emergencyMedicalInfoProvider =
    Provider.family<EmergencyMedicalInfo?, String>((ref, patientId) {
  return ref.watch(emergencyMedicalInfoStoreProvider)[patientId];
});
