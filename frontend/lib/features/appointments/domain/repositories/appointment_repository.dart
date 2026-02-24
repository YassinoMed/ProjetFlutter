import '../entities/doctor_entity.dart';
import '../entities/appointment_entity.dart';

abstract class AppointmentRepository {
  Future<List<Doctor>> searchDoctors({String? query, String? speciality});
  Future<List<Appointment>> getMyAppointments();
  Future<Appointment> bookAppointment({
    required String doctorId,
    required DateTime dateTime,
    String? notes,
  });
  Future<void> cancelAppointment(String appointmentId);
  Future<Appointment> getAppointmentDetail(String id);
}
