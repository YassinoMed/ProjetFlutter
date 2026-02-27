import 'package:dartz/dartz.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';

abstract class VideoCallRepository {
  /// Signal join to the consultation room
  Future<Either<Failure, void>> joinRoom(String appointmentId);

  /// Send WebRTC offer SDP
  Future<Either<Failure, void>> sendOffer({
    required String appointmentId,
    required String sdp,
    required String sdpType,
  });

  /// Send WebRTC answer SDP
  Future<Either<Failure, void>> sendAnswer({
    required String appointmentId,
    required String sdp,
    required String sdpType,
  });

  /// Send ICE candidate
  Future<Either<Failure, void>> sendIceCandidate({
    required String appointmentId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  });
}
