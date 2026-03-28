import 'package:equatable/equatable.dart';

enum CallState {
  idle,
  resolvingSession,
  waitingHost,
  ringing,
  joining,
  connected,
  reconnecting,
  ended,
  error,
}

class VideoCallIceServer extends Equatable {
  final List<String> urls;
  final String? username;
  final String? credential;

  const VideoCallIceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  @override
  List<Object?> get props => [urls, username, credential];
}

class VideoCallSessionContext extends Equatable {
  final String teleconsultationId;
  final String? callSessionId;
  final String? conversationId;
  final String? selfUserId;
  final String? remoteUserId;
  final String teleconsultationStatus;
  final List<VideoCallIceServer> iceServers;

  const VideoCallSessionContext({
    required this.teleconsultationId,
    required this.teleconsultationStatus,
    this.callSessionId,
    this.conversationId,
    this.selfUserId,
    this.remoteUserId,
    this.iceServers = const [],
  });

  VideoCallSessionContext copyWith({
    String? teleconsultationId,
    String? callSessionId,
    String? conversationId,
    String? selfUserId,
    String? remoteUserId,
    String? teleconsultationStatus,
    List<VideoCallIceServer>? iceServers,
  }) {
    return VideoCallSessionContext(
      teleconsultationId: teleconsultationId ?? this.teleconsultationId,
      callSessionId: callSessionId ?? this.callSessionId,
      conversationId: conversationId ?? this.conversationId,
      selfUserId: selfUserId ?? this.selfUserId,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      teleconsultationStatus:
          teleconsultationStatus ?? this.teleconsultationStatus,
      iceServers: iceServers ?? this.iceServers,
    );
  }

  @override
  List<Object?> get props => [
        teleconsultationId,
        callSessionId,
        conversationId,
        selfUserId,
        remoteUserId,
        teleconsultationStatus,
        iceServers,
      ];
}

class VideoCallEntity extends Equatable {
  final String appointmentId;
  final CallState state;
  final String? teleconsultationId;
  final String? callSessionId;
  final String? conversationId;
  final String? teleconsultationStatus;
  final bool isAudioMuted;
  final bool isVideoEnabled;
  final bool isFrontCamera;
  final bool isSpeakerOn;
  final bool hasRemoteVideo;
  final Duration duration;
  final String? errorMessage;

  const VideoCallEntity({
    required this.appointmentId,
    this.state = CallState.idle,
    this.teleconsultationId,
    this.callSessionId,
    this.conversationId,
    this.teleconsultationStatus,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
    this.isFrontCamera = true,
    this.isSpeakerOn = true,
    this.hasRemoteVideo = false,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  VideoCallEntity copyWith({
    CallState? state,
    String? teleconsultationId,
    String? callSessionId,
    String? conversationId,
    String? teleconsultationStatus,
    bool? isAudioMuted,
    bool? isVideoEnabled,
    bool? isFrontCamera,
    bool? isSpeakerOn,
    bool? hasRemoteVideo,
    Duration? duration,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return VideoCallEntity(
      appointmentId: appointmentId,
      state: state ?? this.state,
      teleconsultationId: teleconsultationId ?? this.teleconsultationId,
      callSessionId: callSessionId ?? this.callSessionId,
      conversationId: conversationId ?? this.conversationId,
      teleconsultationStatus:
          teleconsultationStatus ?? this.teleconsultationStatus,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      hasRemoteVideo: hasRemoteVideo ?? this.hasRemoteVideo,
      duration: duration ?? this.duration,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        appointmentId,
        state,
        teleconsultationId,
        callSessionId,
        conversationId,
        teleconsultationStatus,
        isAudioMuted,
        isVideoEnabled,
        isFrontCamera,
        isSpeakerOn,
        hasRemoteVideo,
        duration,
        errorMessage,
      ];
}
