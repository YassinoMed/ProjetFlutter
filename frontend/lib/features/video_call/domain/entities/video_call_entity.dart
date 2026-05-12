import 'package:equatable/equatable.dart';

enum VideoCallType {
  video,
  audio;

  static VideoCallType fromRaw(String? raw) {
    return raw?.toUpperCase() == 'AUDIO'
        ? VideoCallType.audio
        : VideoCallType.video;
  }

  String get rawValue => this == VideoCallType.audio ? 'AUDIO' : 'VIDEO';

  bool get requiresVideo => this == VideoCallType.video;

  String get labelFr => this == VideoCallType.audio ? 'audio' : 'vidéo';
}

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

enum CallMediaPermissionState {
  unknown,
  checking,
  granted,
  denied,
  permanentlyDenied,
  restricted,
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

class LiveKitConnectionInfo extends Equatable {
  final String url;
  final String token;
  final String room;
  final DateTime? expiresAtUtc;

  const LiveKitConnectionInfo({
    required this.url,
    required this.token,
    required this.room,
    this.expiresAtUtc,
  });

  @override
  List<Object?> get props => [url, token, room, expiresAtUtc];
}

class VideoCallSessionContext extends Equatable {
  final String teleconsultationId;
  final String? callSessionId;
  final String? conversationId;
  final String? selfUserId;
  final String? remoteUserId;
  final String teleconsultationStatus;
  final VideoCallType callType;
  final List<VideoCallIceServer> iceServers;

  const VideoCallSessionContext({
    required this.teleconsultationId,
    required this.teleconsultationStatus,
    this.callType = VideoCallType.video,
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
    VideoCallType? callType,
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
      callType: callType ?? this.callType,
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
        callType,
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
  final VideoCallType callType;
  final bool isAudioMuted;
  final bool isVideoEnabled;
  final bool isFrontCamera;
  final bool isSpeakerOn;
  final bool hasRemoteVideo;
  final Duration duration;
  final String? errorMessage;
  final CallMediaPermissionState mediaPermissionState;
  final String? mediaPermissionMessage;

  const VideoCallEntity({
    required this.appointmentId,
    this.state = CallState.idle,
    this.teleconsultationId,
    this.callSessionId,
    this.conversationId,
    this.teleconsultationStatus,
    this.callType = VideoCallType.video,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
    this.isFrontCamera = true,
    this.isSpeakerOn = true,
    this.hasRemoteVideo = false,
    this.duration = Duration.zero,
    this.errorMessage,
    this.mediaPermissionState = CallMediaPermissionState.unknown,
    this.mediaPermissionMessage,
  });

  bool get hasMediaPermissions =>
      mediaPermissionState == CallMediaPermissionState.granted;

  bool get isAudioOnly => !callType.requiresVideo;

  bool get requiresVideo => callType.requiresVideo;

  bool get shouldOpenPermissionSettings =>
      mediaPermissionState == CallMediaPermissionState.permanentlyDenied;

  VideoCallEntity copyWith({
    CallState? state,
    String? teleconsultationId,
    String? callSessionId,
    String? conversationId,
    String? teleconsultationStatus,
    VideoCallType? callType,
    bool? isAudioMuted,
    bool? isVideoEnabled,
    bool? isFrontCamera,
    bool? isSpeakerOn,
    bool? hasRemoteVideo,
    Duration? duration,
    String? errorMessage,
    CallMediaPermissionState? mediaPermissionState,
    String? mediaPermissionMessage,
    bool clearErrorMessage = false,
    bool clearMediaPermissionMessage = false,
  }) {
    return VideoCallEntity(
      appointmentId: appointmentId,
      state: state ?? this.state,
      teleconsultationId: teleconsultationId ?? this.teleconsultationId,
      callSessionId: callSessionId ?? this.callSessionId,
      conversationId: conversationId ?? this.conversationId,
      teleconsultationStatus:
          teleconsultationStatus ?? this.teleconsultationStatus,
      callType: callType ?? this.callType,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      hasRemoteVideo: hasRemoteVideo ?? this.hasRemoteVideo,
      duration: duration ?? this.duration,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      mediaPermissionState: mediaPermissionState ?? this.mediaPermissionState,
      mediaPermissionMessage: clearMediaPermissionMessage
          ? null
          : (mediaPermissionMessage ?? this.mediaPermissionMessage),
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
        callType,
        isAudioMuted,
        isVideoEnabled,
        isFrontCamera,
        isSpeakerOn,
        hasRemoteVideo,
        duration,
        errorMessage,
        mediaPermissionState,
        mediaPermissionMessage,
      ];
}
