import 'package:equatable/equatable.dart';
import 'doctor_entity.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow;

  static AppointmentStatus fromString(String status) {
    final normalized = status.trim().toLowerCase();

    if (normalized == 'requested' || normalized == 'draft') {
      return AppointmentStatus.pending;
    }
    if (normalized == 'no_show' || normalized == 'noshow') {
      return AppointmentStatus.noShow;
    }

    return AppointmentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => AppointmentStatus.pending,
    );
  }
}

enum AppointmentType {
  presential,
  video;

  static AppointmentType fromString(String type) {
    if (type.toLowerCase().contains('video') ||
        type.toLowerCase().contains('teleconsultation')) {
      return AppointmentType.video;
    }
    return AppointmentType.presential;
  }

  String get label => switch (this) {
        AppointmentType.presential => 'Présentiel',
        AppointmentType.video => 'Téléconsultation',
      };
}

class Appointment extends Equatable {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? notes;
  final String? patientName;
  final String? doctorName;
  final int durationMinutes;
  final DoctorEntity? doctor;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
    this.type = AppointmentType.presential,
    this.notes,
    this.patientName,
    this.doctorName,
    this.durationMinutes = 30,
    this.doctor,
  });

  @override
  List<Object?> get props => [
        id,
        doctorId,
        patientId,
        dateTime,
        status,
        type,
        notes,
        patientName,
        doctorName,
        doctor
      ];
}
