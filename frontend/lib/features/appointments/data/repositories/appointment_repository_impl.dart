import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Doctor>> searchDoctors({String? query, String? speciality}) {
    return remoteDataSource.searchDoctors(query: query, speciality: speciality);
  }

  @override
  Future<List<Appointment>> getMyAppointments() {
    return remoteDataSource.getMyAppointments();
  }

  @override
  Future<Appointment> bookAppointment({
    required String doctorId,
    required DateTime dateTime,
    String? notes,
  }) {
    return remoteDataSource.bookAppointment(
      doctorId: doctorId,
      dateTime: dateTime,
      notes: notes,
    );
  }

  @override
  Future<void> cancelAppointment(String appointmentId) {
    return remoteDataSource.cancelAppointment(appointmentId);
  }

  @override
  Future<Appointment> getAppointmentDetail(String id) {
    return remoteDataSource.getAppointmentDetail(id);
  }
}

// Providers
final appointmentRemoteDataSourceProvider =
    Provider<AppointmentRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AppointmentRemoteDataSourceImpl(dio: dio);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final remoteDataSource = ref.watch(appointmentRemoteDataSourceProvider);
  return AppointmentRepositoryImpl(remoteDataSource: remoteDataSource);
});
