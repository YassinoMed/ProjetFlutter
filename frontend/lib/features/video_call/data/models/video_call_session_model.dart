import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';

class VideoCallIceServerModel extends VideoCallIceServer {
  const VideoCallIceServerModel({
    required super.urls,
    super.username,
    super.credential,
  });

  factory VideoCallIceServerModel.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['urls'];
    final urls = rawUrls is List
        ? rawUrls.whereType<String>().toList()
        : rawUrls is String
            ? <String>[rawUrls]
            : const <String>[];

    return VideoCallIceServerModel(
      urls: urls,
      username: json['username']?.toString(),
      credential: json['credential']?.toString(),
    );
  }
}

class VideoCallSessionModel extends VideoCallSessionContext {
  const VideoCallSessionModel({
    required super.teleconsultationId,
    required super.teleconsultationStatus,
    super.callSessionId,
    super.conversationId,
    super.selfUserId,
    super.remoteUserId,
    super.iceServers,
  });

  factory VideoCallSessionModel.fromTeleconsultationJson(
      Map<String, dynamic> json) {
    final callSession =
        json['current_call_session'] as Map<String, dynamic>? ?? const {};

    return VideoCallSessionModel(
      teleconsultationId: json['id'].toString(),
      teleconsultationStatus:
          json['status']?.toString().toLowerCase() ?? 'scheduled',
      callSessionId: json['current_call_session_id']?.toString() ??
          callSession['id']?.toString(),
      conversationId: json['conversation_id']?.toString(),
    );
  }

  factory VideoCallSessionModel.fromJoinResponse(Map<String, dynamic> json) {
    final teleconsultation =
        json['teleconsultation'] as Map<String, dynamic>? ?? const {};
    final rtcConfiguration =
        json['rtc_configuration'] as Map<String, dynamic>? ?? const {};
    final iceServers = (rtcConfiguration['ice_servers'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VideoCallIceServerModel.fromJson)
        .toList();

    return VideoCallSessionModel(
      teleconsultationId: teleconsultation['id'].toString(),
      teleconsultationStatus:
          teleconsultation['status']?.toString().toLowerCase() ?? 'scheduled',
      callSessionId:
          json['call_session']?['id']?.toString() ??
              teleconsultation['current_call_session_id']?.toString(),
      conversationId: teleconsultation['conversation_id']?.toString(),
      selfUserId: json['self_user_id']?.toString(),
      remoteUserId: json['remote_user_id']?.toString(),
      iceServers: iceServers,
    );
  }
}
