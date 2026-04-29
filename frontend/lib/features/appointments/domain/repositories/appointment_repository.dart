import '../entities/appointment_entity.dart';
import '../entities/doctor_entity.dart';

abstract class AppointmentRepository {
  Future<List<DoctorEntity>> searchDoctors({String? query, String? speciality});
  Future<List<Appointment>> getMyAppointments();
  Future<Appointment> bookAppointment({
    required String doctorId,
    required DateTime dateTime,
    String? notes,
  });
  Future<void> cancelAppointment(String appointmentId);
  Future<Appointment> confirmAppointment(String appointmentId);
  Future<Appointment> rejectAppointment(String appointmentId);
  Future<Appointment> getAppointmentDetail(String id);
}
