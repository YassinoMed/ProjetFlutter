import 'dart:convert';

import '../../domain/entities/emergency_medical_info.dart';

class EmergencyQrService {
  const EmergencyQrService();

  String buildPayload(EmergencyMedicalInfo info) {
    final payload = <String, dynamic>{
      'source': 'MediConnect Pro',
      'type': 'emergency_medical_info',
      'patient': {
        'name': info.patientName,
      },
      'vital': {
        if (info.bloodType.trim().isNotEmpty)
          'blood_type': info.bloodType.trim(),
        if (info.importantAllergies.isNotEmpty)
          'important_allergies': info.importantAllergies,
        if (info.chronicConditions.isNotEmpty)
          'chronic_conditions': info.chronicConditions,
        if (info.criticalTreatments.isNotEmpty)
          'critical_treatments': info.criticalTreatments,
      },
      'emergency_contact': {
        if (info.emergencyContactName.trim().isNotEmpty)
          'name': info.emergencyContactName.trim(),
        if (info.emergencyContactPhone.trim().isNotEmpty)
          'phone': info.emergencyContactPhone.trim(),
      },
      'disclaimer': 'Informations fournies par le patient.',
      'updated_at_utc': info.updatedAt.toIso8601String(),
    };

    return jsonEncode(payload);
  }
}
