import 'package:equatable/equatable.dart';

enum CallState {
  idle,
  joining,
  ringing,
  connected,
  reconnecting,
  ended,
  error,
}

class VideoCallEntity extends Equatable {
  final String appointmentId;
  final CallState state;
  final bool isAudioMuted;
  final bool isVideoEnabled;
  final bool isFrontCamera;
  final Duration duration;
  final String? errorMessage;

  const VideoCallEntity({
    required this.appointmentId,
    this.state = CallState.idle,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
    this.isFrontCamera = true,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  VideoCallEntity copyWith({
    CallState? state,
    bool? isAudioMuted,
    bool? isVideoEnabled,
    bool? isFrontCamera,
    Duration? duration,
    String? errorMessage,
  }) {
    return VideoCallEntity(
      appointmentId: appointmentId,
      state: state ?? this.state,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        appointmentId,
        state,
        isAudioMuted,
        isVideoEnabled,
        isFrontCamera,
        duration,
        errorMessage,
      ];
}
