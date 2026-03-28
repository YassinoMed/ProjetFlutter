import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/features/video_call/data/models/video_call_session_model.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';
import 'package:mediconnect_pro/features/video_call/domain/repositories/video_call_repository.dart';

class VideoCallRepositoryImpl implements VideoCallRepository {
  final Dio dio;

  VideoCallRepositoryImpl({required this.dio});

  @override
  Future<Either<Failure, VideoCallSessionContext>> ensureTeleconsultation(
      String appointmentId) async {
    try {
      final response = await dio.post(
        ApiConstants.teleconsultations,
        data: {'appointment_id': appointmentId},
      );

      final data = (response.data['data'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final teleconsultation =
          data['teleconsultation'] as Map<String, dynamic>? ?? const {};

      return Right(
          VideoCallSessionModel.fromTeleconsultationJson(teleconsultation));
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ??
              'Teleconsultation bootstrap failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoCallSessionContext>> startTeleconsultation(
      String teleconsultationId) async {
    try {
      final response = await dio.post(
        ApiConstants.teleconsultationStart
            .replaceFirst('{id}', teleconsultationId),
      );

      final data = (response.data['data'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final teleconsultation =
          data['teleconsultation'] as Map<String, dynamic>? ?? const {};

      return Right(
          VideoCallSessionModel.fromTeleconsultationJson(teleconsultation));
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ??
              'Teleconsultation start failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoCallSessionContext>> joinTeleconsultation(
      String teleconsultationId) async {
    try {
      final response = await dio.post(
        ApiConstants.teleconsultationJoin
            .replaceFirst('{id}', teleconsultationId),
      );

      final data = (response.data['data'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};

      return Right(VideoCallSessionModel.fromJoinResponse(data));
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Join failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endTeleconsultation(
      String teleconsultationId) async {
    try {
      await dio.post(
        ApiConstants.teleconsultationEnd.replaceFirst('{id}', teleconsultationId),
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'End failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTeleconsultation(
    String teleconsultationId, {
    String? reason,
  }) async {
    try {
      await dio.post(
        ApiConstants.teleconsultationCancel
            .replaceFirst('{id}', teleconsultationId),
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Cancel failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendOffer({
    required String teleconsultationId,
    required String targetUserId,
    required String sdp,
    required String sdpType,
  }) async {
    try {
      await dio.post(
        ApiConstants.teleconsultationOffer
            .replaceFirst('{id}', teleconsultationId),
        data: {
          'target_user_id': targetUserId,
          'sdp': {'type': sdpType, 'sdp': sdp},
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ?? 'Offer failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendAnswer({
    required String teleconsultationId,
    required String targetUserId,
    required String sdp,
    required String sdpType,
  }) async {
    try {
      await dio.post(
        ApiConstants.teleconsultationAnswer
            .replaceFirst('{id}', teleconsultationId),
        data: {
          'target_user_id': targetUserId,
          'sdp': {'type': sdpType, 'sdp': sdp},
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Answer failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendIceCandidate({
    required String teleconsultationId,
    required String targetUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
    String? usernameFragment,
  }) async {
    try {
      await dio.post(
        ApiConstants.teleconsultationIce.replaceFirst('{id}', teleconsultationId),
        data: {
          'target_user_id': targetUserId,
          'candidate': {
            'candidate': candidate,
            if (sdpMid != null) 'sdpMid': sdpMid,
            if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
            if (usernameFragment != null) 'usernameFragment': usernameFragment,
          },
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ?? 'ICE failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
