import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_pro/features/emergency_qr/data/services/emergency_qr_service.dart';
import 'package:mediconnect_pro/features/emergency_qr/domain/entities/emergency_medical_info.dart';

void main() {
  group('EmergencyQrService', () {
    test('builds a limited emergency payload without full medical record data',
        () {
      final info = EmergencyMedicalInfo(
        patientId: 'patient-1',
        patientName: 'Samira Ben Ali',
        bloodType: 'A+',
        importantAllergies: const ['Pénicilline'],
        chronicConditions: const ['Asthme sévère'],
        criticalTreatments: const ['Ventoline'],
        emergencyContactName: 'Youssef',
        emergencyContactPhone: '+21600000000',
        enabled: true,
        updatedAt: DateTime.utc(2026, 5, 18),
      );

      final payload = jsonDecode(const EmergencyQrService().buildPayload(info))
          as Map<String, dynamic>;

      expect(payload['source'], 'MediConnect Pro');
      expect(payload['type'], 'emergency_medical_info');
      expect(payload['disclaimer'], 'Informations fournies par le patient.');
      expect(payload['patient'], {'name': 'Samira Ben Ali'});
      expect(payload.containsKey('appointments'), isFalse);
      expect(payload.containsKey('documents'), isFalse);
      expect(payload.containsKey('prescriptions'), isFalse);
    });
  });
}
