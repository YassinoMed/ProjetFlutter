import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pre_consultation_questionnaire.dart';

class PreConsultationQuestionnaireStore
    extends StateNotifier<List<PreConsultationQuestionnaire>> {
  PreConsultationQuestionnaireStore() : super(const []);

  void save(PreConsultationQuestionnaire questionnaire) {
    state = [
      for (final item in state)
        if (item.appointmentId != questionnaire.appointmentId) item,
      questionnaire,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  PreConsultationQuestionnaire? byAppointment(String appointmentId) {
    for (final item in state) {
      if (item.appointmentId == appointmentId) {
        return item;
      }
    }
    return null;
  }

  List<PreConsultationQuestionnaire> forPatient(String patientId) {
    return state.where((item) => item.patientId == patientId).toList();
  }

  List<PreConsultationQuestionnaire> forDoctor(String doctorId) {
    return state.where((item) => item.doctorId == doctorId).toList();
  }
}

final preConsultationQuestionnaireStoreProvider = StateNotifierProvider<
    PreConsultationQuestionnaireStore,
    List<PreConsultationQuestionnaire>>((ref) {
  return PreConsultationQuestionnaireStore();
});

final preConsultationQuestionnaireByAppointmentProvider =
    Provider.family<PreConsultationQuestionnaire?, String>(
  (ref, appointmentId) {
    final items = ref.watch(preConsultationQuestionnaireStoreProvider);
    for (final item in items) {
      if (item.appointmentId == appointmentId) {
        return item;
      }
    }
    return null;
  },
);
