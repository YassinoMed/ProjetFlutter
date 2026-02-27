import 'package:dartz/dartz.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/features/medical_records/domain/entities/medical_record_entity.dart';

abstract class MedicalRecordRepository {
  Future<Either<Failure, List<MedicalRecord>>> getRecords({
    String? category,
    String? cursor,
    int perPage = 20,
  });

  Future<Either<Failure, MedicalRecord>> getRecord(String recordId);

  Future<Either<Failure, MedicalRecord>> createRecord({
    required String category,
    required Map<String, dynamic> metadataEncrypted,
    required DateTime recordedAtUtc,
    String? patientUserId,
  });
}
