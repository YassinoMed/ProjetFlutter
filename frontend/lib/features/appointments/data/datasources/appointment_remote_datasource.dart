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
    final response = await dio.get(ApiConstants.appointments);

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

    final Map<String, dynamic> data =
        (response.data is Map && response.data.containsKey('appointment'))
            ? response.data['appointment'] as Map<String, dynamic>
            : (response.data is Map && response.data.containsKey('data'))
                ? response.data['data'] as Map<String, dynamic>
                : response.data as Map<String, dynamic>;

    return AppointmentModel.fromJson(data);
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await dio.post(
      ApiConstants.appointmentCancel.replaceFirst('{id}', appointmentId),
    );
  }

  @override
  Future<AppointmentModel> getAppointmentDetail(String id) async {
    final response = await dio.get('${ApiConstants.appointments}/$id');

    final Map<String, dynamic> data =
        (response.data is Map && response.data.containsKey('data'))
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

    return AppointmentModel.fromJson(data);
  }
}
