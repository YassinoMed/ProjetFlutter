import '../../domain/entities/appointment_entity.dart';
import 'doctor_model.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.doctorId,
    required super.patientId,
    required super.dateTime,
    required super.status,
    super.type,
    super.notes,
    super.patientName,
    super.durationMinutes,
    super.doctor,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Parse patient name from nested patient object if available
    String? patientName;
    if (json['patient'] is Map<String, dynamic>) {
      final patient = json['patient'] as Map<String, dynamic>;
      final firstName = patient['first_name'] as String? ?? '';
      final lastName = patient['last_name'] as String? ?? '';
      patientName = '$firstName $lastName'.trim();
      if (patientName.isEmpty) {
        patientName = patient['name'] as String?;
      }
    }

    // Parse type
    final typeStr = json['type'] as String? ??
        json['consultation_type'] as String? ??
        'presential';

    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      doctorId: (json['doctor_user_id'] ?? json['doctor_id'])?.toString() ?? '',
      patientId:
          (json['patient_user_id'] ?? json['patient_id'])?.toString() ?? '',
      dateTime: DateTime.parse(json['starts_at_utc'] ??
          json['appointment_date'] ??
          json['date_time'] ??
          DateTime.now().toIso8601String()),
      status:
          AppointmentStatus.fromString(json['status'] as String? ?? 'pending'),
      type: AppointmentType.fromString(typeStr),
      notes: json['metadata_encrypted']?['notes'] as String? ??
          json['notes'] as String?,
      patientName: patientName,
      durationMinutes: (json['duration_minutes'] as int?) ?? 30,
      doctor: json['doctor'] != null
          ? DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'appointment_date': dateTime.toIso8601String(),
      'status': status.name.toUpperCase(),
      'type': type.name,
      'notes': notes,
    };
  }
}
