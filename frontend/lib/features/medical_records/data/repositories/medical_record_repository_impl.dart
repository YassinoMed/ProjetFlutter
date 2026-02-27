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
      final records = data
          .map((json) =>
              MedicalRecordModel.fromJson(json as Map<String, dynamic>))
          .toList();

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
