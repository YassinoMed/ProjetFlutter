import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_pro/features/pre_consultation/domain/entities/pre_consultation_questionnaire.dart';

void main() {
  group('PreConsultationQuestionnaire', () {
    test('detects when clinical content has been provided', () {
      final empty = PreConsultationQuestionnaire(
        appointmentId: 'appointment-1',
        patientId: 'patient-1',
        reason: '',
        symptoms: '',
        symptomDuration: '',
        painLevel: 0,
        hasFever: false,
        medicationsTaken: '',
        allergies: '',
        freeMessage: '',
        updatedAt: DateTime.utc(2026, 5, 18),
      );

      expect(empty.hasClinicalContent, isFalse);
      expect(
        empty.copyWith(symptoms: 'Toux depuis 3 jours').hasClinicalContent,
        isTrue,
      );
      expect(
        empty.copyWith(linkedDocumentIds: const ['doc-1']).hasClinicalContent,
        isTrue,
      );
    });
  });
}
