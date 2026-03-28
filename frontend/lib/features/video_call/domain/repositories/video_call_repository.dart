import 'package:dartz/dartz.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';

abstract class VideoCallRepository {
  Future<Either<Failure, VideoCallSessionContext>> ensureTeleconsultation(
      String appointmentId);

  Future<Either<Failure, VideoCallSessionContext>> startTeleconsultation(
      String teleconsultationId);

  Future<Either<Failure, VideoCallSessionContext>> joinTeleconsultation(
      String teleconsultationId);

  Future<Either<Failure, void>> endTeleconsultation(String teleconsultationId);

  Future<Either<Failure, void>> cancelTeleconsultation(
    String teleconsultationId, {
    String? reason,
  });

  Future<Either<Failure, void>> sendOffer({
    required String teleconsultationId,
    required String targetUserId,
    required String sdp,
    required String sdpType,
  });

  Future<Either<Failure, void>> sendAnswer({
    required String teleconsultationId,
    required String targetUserId,
    required String sdp,
    required String sdpType,
  });

  Future<Either<Failure, void>> sendIceCandidate({
    required String teleconsultationId,
    required String targetUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
    String? usernameFragment,
  });
}
