import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/features/video_call/domain/repositories/video_call_repository.dart';

class VideoCallRepositoryImpl implements VideoCallRepository {
  final Dio dio;

  VideoCallRepositoryImpl({required this.dio});

  @override
  Future<Either<Failure, void>> joinRoom(String appointmentId) async {
    try {
      await dio
          .post(ApiConstants.webrtcJoin.replaceFirst('{id}', appointmentId));
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ?? 'Join failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendOffer({
    required String appointmentId,
    required String sdp,
    required String sdpType,
  }) async {
    try {
      await dio.post(
        ApiConstants.webrtcOffer.replaceFirst('{id}', appointmentId),
        data: {'sdp': sdp, 'sdp_type': sdpType},
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
    required String appointmentId,
    required String sdp,
    required String sdpType,
  }) async {
    try {
      await dio.post(
        ApiConstants.webrtcAnswer.replaceFirst('{id}', appointmentId),
        data: {'sdp': sdp, 'sdp_type': sdpType},
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
    required String appointmentId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    try {
      await dio.post(
        ApiConstants.webrtcIce.replaceFirst('{id}', appointmentId),
        data: {
          'candidate': candidate,
          if (sdpMid != null) 'sdp_mid': sdpMid,
          if (sdpMLineIndex != null) 'sdp_mline_index': sdpMLineIndex,
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
