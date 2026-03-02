import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class WebRTCState extends Equatable {
  const WebRTCState();

  @override
  List<Object?> get props => [];
}

class WebRTCInitial extends WebRTCState {}

class WebRTCSettingUp extends WebRTCState {}

class WebRTCReady extends WebRTCState {
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final bool isAudioMuted;
  final bool isVideoMuted;

  const WebRTCReady({
    this.localStream,
    this.remoteStream,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
  });

  WebRTCReady copyWith({
    MediaStream? localStream,
    MediaStream? remoteStream,
    bool? isAudioMuted,
    bool? isVideoMuted,
  }) {
    return WebRTCReady(
      localStream: localStream ?? this.localStream,
      remoteStream: remoteStream ?? this.remoteStream,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
    );
  }

  @override
  List<Object?> get props => [
        localStream?.id,
        remoteStream?.id,
        isAudioMuted,
        isVideoMuted,
      ];
}

class WebRTCError extends WebRTCState {
  final String message;
  const WebRTCError(this.message);

  @override
  List<Object?> get props => [message];
}

class WebRTCEnded extends WebRTCState {}
