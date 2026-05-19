import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/features/medical_records/data/models/medical_record_model.dart';
import 'package:mediconnect_pro/features/medical_records/domain/entities/medical_record_entity.dart';
import 'package:mediconnect_pro/features/medical_records/domain/repositories/medical_record_repository.dart';

class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  final Dio dio;

  MedicalRecordRepositoryImpl({required this.dio});

  @override
  Future<Either<Failure, List<MedicalRecord>>> getRecords({
    String? category,
    String? cursor,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.medicalRecords,
        queryParameters: {
          'per_page': perPage,
          if (category != null) 'category': category,
          if (cursor != null) 'cursor': cursor,
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      // Déduplication par ID — défensif : certaines réponses paginées du
      // backend peuvent contenir des doublons lors de chevauchements de
      // curseurs (page n+1 inclut le dernier item de la page n). Sans
      // cette dédup, la page « Stockage local chiffré AES-256 » affichait
      // la même ordonnance deux fois à l'écran.
      final seen = <String>{};
      final records = <MedicalRecord>[];
      for (final json in data) {
        if (json is! Map<String, dynamic>) continue;
        final record = MedicalRecordModel.fromJson(json);
        if (seen.add(record.id)) {
          records.add(record);
        }
      }

      return Right(records);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicalRecord>> getRecord(String recordId) async {
    try {
      final url = ApiConstants.medicalRecordShow.replaceFirst('{id}', recordId);
      final response = await dio.get(url);

      return Right(MedicalRecordModel.fromJson(
          response.data['record'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicalRecord>> createRecord({
    required String category,
    required Map<String, dynamic> metadataEncrypted,
    required DateTime recordedAtUtc,
    String? patientUserId,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.medicalRecords,
        data: {
          'category': category,
          'metadata_encrypted': metadataEncrypted,
          'recorded_at_utc': recordedAtUtc.toUtc().toIso8601String(),
          if (patientUserId != null) 'patient_user_id': patientUserId,
        },
      );

      return Right(MedicalRecordModel.fromJson(
          response.data['record'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Create failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
