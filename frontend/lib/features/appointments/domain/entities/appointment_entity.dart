import 'package:equatable/equatable.dart';
import 'doctor_entity.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow;

  static AppointmentStatus fromString(String status) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == status.toUpperCase(),
      orElse: () => AppointmentStatus.pending,
    );
  }
}

class Appointment extends Equatable {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? notes;
  final DoctorEntity? doctor;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
    this.notes,
    this.doctor,
  });

  @override
  List<Object?> get props =>
      [id, doctorId, patientId, dateTime, status, notes, doctor];
}
