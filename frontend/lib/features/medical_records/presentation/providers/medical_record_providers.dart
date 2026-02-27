import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/features/medical_records/data/repositories/medical_record_repository_impl.dart';
import 'package:mediconnect_pro/features/medical_records/domain/entities/medical_record_entity.dart';
import 'package:mediconnect_pro/features/medical_records/domain/repositories/medical_record_repository.dart';

final medicalRecordRepositoryProvider =
    Provider<MedicalRecordRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MedicalRecordRepositoryImpl(dio: dio);
});

final medicalRecordsProvider =
    FutureProvider.family<List<MedicalRecord>, String?>((ref, category) async {
  final repo = ref.watch(medicalRecordRepositoryProvider);
  final result = await repo.getRecords(category: category);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (records) => records,
  );
});

final medicalRecordProvider =
    FutureProvider.family<MedicalRecord, String>((ref, recordId) async {
  final repo = ref.watch(medicalRecordRepositoryProvider);
  final result = await repo.getRecord(recordId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (record) => record,
  );
});
