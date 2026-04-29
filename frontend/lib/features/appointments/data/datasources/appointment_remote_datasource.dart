import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/appointment_model.dart';
import '../models/doctor_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<DoctorModel>> searchDoctors({String? query, String? speciality});
  Future<List<AppointmentModel>> getMyAppointments();
  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required DateTime dateTime,
    String? notes,
  });
  Future<void> cancelAppointment(String appointmentId);
  Future<AppointmentModel> confirmAppointment(String appointmentId);
  Future<AppointmentModel> rejectAppointment(String appointmentId);
  Future<AppointmentModel> getAppointmentDetail(String id);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final Dio dio;

  AppointmentRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<DoctorModel>> searchDoctors(
      {String? query, String? speciality}) async {
    final response = await dio.get(
      ApiConstants.doctors,
      queryParameters: {
        if (query != null) 'query': query,
        if (speciality != null) 'speciality': speciality,
      },
    );

    final List<dynamic> data =
        (response.data is Map && response.data.containsKey('data'))
            ? response.data['data'] as List<dynamic>
            : response.data as List<dynamic>;

    return data
        .map((json) => DoctorModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AppointmentModel>> getMyAppointments() async {
    final response = await dio.get(
      ApiConstants.appointments,
      queryParameters: {'per_page': 20},
    );

    final List<dynamic> data =
        (response.data is Map && response.data.containsKey('data'))
            ? response.data['data'] as List<dynamic>
            : response.data as List<dynamic>;

    return data
        .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required DateTime dateTime,
    String? notes,
  }) async {
    final response = await dio.post(
      ApiConstants.appointmentCreate,
      data: {
        'doctor_user_id': doctorId,
        'starts_at_utc': dateTime.toUtc().toIso8601String(),
        'ends_at_utc':
            dateTime.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
        if (notes != null) 'metadata_encrypted': {'notes': notes},
      },
    );

    return AppointmentModel.fromJson(_extractAppointmentMap(response.data));
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await dio.post(
      ApiConstants.appointmentCancel.replaceFirst('{id}', appointmentId),
    );
  }

  @override
  Future<AppointmentModel> confirmAppointment(String appointmentId) async {
    final response = await dio.post(
      ApiConstants.appointmentConfirm.replaceFirst('{id}', appointmentId),
    );

    return AppointmentModel.fromJson(_extractAppointmentMap(response.data));
  }

  @override
  Future<AppointmentModel> rejectAppointment(String appointmentId) async {
    final response = await dio.post(
      ApiConstants.appointmentReject.replaceFirst('{id}', appointmentId),
      data: {'cancel_reason': 'Refusé par le cabinet médical'},
    );

    return AppointmentModel.fromJson(_extractAppointmentMap(response.data));
  }

  @override
  Future<AppointmentModel> getAppointmentDetail(String id) async {
    final response = await dio.get('${ApiConstants.appointments}/$id');

    return AppointmentModel.fromJson(_extractAppointmentMap(response.data));
  }

  Map<String, dynamic> _extractAppointmentMap(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return const <String, dynamic>{};
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final appointment = data['appointment'];
      if (appointment is Map<String, dynamic>) {
        return appointment;
      }
      return data;
    }

    final appointment = payload['appointment'];
    if (appointment is Map<String, dynamic>) {
      return appointment;
    }

    return payload;
  }
}
