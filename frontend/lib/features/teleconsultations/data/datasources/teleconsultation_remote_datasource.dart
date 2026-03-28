import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';

import '../models/teleconsultation_model.dart';

class TeleconsultationRemoteDataSource {
  final Dio dio;

  TeleconsultationRemoteDataSource({required this.dio});

  Future<List<TeleconsultationModel>> listTeleconsultations({
    String? status,
  }) async {
    final response = await dio.get(
      ApiConstants.teleconsultations,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final data = response.data['data'] as List? ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(TeleconsultationModel.fromJson)
        .toList();
  }

  Future<TeleconsultationModel> getTeleconsultation(String id) async {
    final response = await dio.get(
      ApiConstants.teleconsultationShow.replaceFirst('{id}', id),
    );

    final data = (response.data['data'] as Map<String, dynamic>?)?['teleconsultation']
            as Map<String, dynamic>? ??
        const {};

    return TeleconsultationModel.fromJson(data);
  }

  Future<List<TeleconsultationEventModel>> getEvents(String id) async {
    final response = await dio.get(
      ApiConstants.teleconsultationEvents.replaceFirst('{id}', id),
    );

    final data = ((response.data['data'] as Map<String, dynamic>?)?['events']
            as List?) ??
        const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(TeleconsultationEventModel.fromJson)
        .toList();
  }

  Future<TeleconsultationModel> cancelTeleconsultation(String id) async {
    final response = await dio.post(
      ApiConstants.teleconsultationCancel.replaceFirst('{id}', id),
    );

    final data = (response.data['data'] as Map<String, dynamic>?)?['teleconsultation']
            as Map<String, dynamic>? ??
        const {};

    return TeleconsultationModel.fromJson(data);
  }
}
