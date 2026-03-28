import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';

import '../datasources/teleconsultation_remote_datasource.dart';
import '../models/teleconsultation_model.dart';

final teleconsultationRepositoryProvider =
    Provider<TeleconsultationRepositoryImpl>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = TeleconsultationRemoteDataSource(dio: dio);
  return TeleconsultationRepositoryImpl(dataSource: dataSource);
});

class TeleconsultationRepositoryImpl {
  final TeleconsultationRemoteDataSource dataSource;

  TeleconsultationRepositoryImpl({required this.dataSource});

  Future<List<TeleconsultationModel>> listTeleconsultations({
    String? status,
  }) {
    return dataSource.listTeleconsultations(status: status);
  }

  Future<TeleconsultationModel> getTeleconsultation(String id) {
    return dataSource.getTeleconsultation(id);
  }

  Future<List<TeleconsultationEventModel>> getEvents(String id) {
    return dataSource.getEvents(id);
  }

  Future<TeleconsultationModel> cancelTeleconsultation(String id) {
    return dataSource.cancelTeleconsultation(id);
  }
}
