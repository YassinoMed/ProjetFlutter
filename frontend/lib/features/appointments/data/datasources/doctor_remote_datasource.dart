import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/features/appointments/domain/entities/doctor_entity.dart';

abstract class DoctorRemoteDataSource {
  Future<List<DoctorEntity>> searchDoctors({
    String? specialty,
    String? city,
    String? query,
    bool? videoOnly,
    int perPage = 20,
  });

  Future<DoctorEntity> getDoctor(String doctorUserId);

  Future<List<TimeSlot>> getAvailableSlots(String doctorUserId, DateTime date);

  Future<List<String>> getSpecialties();
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final Dio dio;

  DoctorRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<DoctorEntity>> searchDoctors({
    String? specialty,
    String? city,
    String? query,
    bool? videoOnly,
    int perPage = 20,
  }) async {
    final response = await dio.get(ApiConstants.doctors, queryParameters: {
      'per_page': perPage,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
      if (city != null && city.isNotEmpty) 'city': city,
      if (query != null && query.isNotEmpty) 'q': query,
      if (videoOnly == true) 'video_only': true,
    });

    final List<dynamic> data = response.data['data'] ?? [];
    return data
        .map((json) => DoctorEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DoctorEntity> getDoctor(String doctorUserId) async {
    final response = await dio.get(
      ApiConstants.doctorShow.replaceFirst('{id}', doctorUserId),
    );

    final json = response.data['doctor'] as Map<String, dynamic>;
    return DoctorEntity.fromJson(json);
  }

  @override
  Future<List<TimeSlot>> getAvailableSlots(
      String doctorUserId, DateTime date) async {
    final response = await dio.get(
      ApiConstants.doctorSlots.replaceFirst('{id}', doctorUserId),
      queryParameters: {
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      },
    );

    final List<dynamic> data = response.data['slots'] ?? [];
    return data
        .map((json) => TimeSlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getSpecialties() async {
    final response = await dio.get(ApiConstants.doctorSpecialties);
    final List<dynamic> data = response.data['specialties'] ?? [];
    return data.map((s) => s.toString()).toList();
  }
}
