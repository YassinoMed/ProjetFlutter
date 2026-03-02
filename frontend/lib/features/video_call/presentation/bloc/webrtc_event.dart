import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class WebRTCEvent extends Equatable {
  const WebRTCEvent();

  @override
  List<Object?> get props => [];
}

class StartCall extends WebRTCEvent {}

class CallAccepted extends WebRTCEvent {}

class EndCall extends WebRTCEvent {}

class RemoteOfferReceived extends WebRTCEvent {
  final Map<String, dynamic> offer;
  const RemoteOfferReceived(this.offer);

  @override
  List<Object?> get props => [offer];
}

class RemoteAnswerReceived extends WebRTCEvent {
  final Map<String, dynamic> answer;
  const RemoteAnswerReceived(this.answer);

  @override
  List<Object?> get props => [answer];
}

class RemoteIceCandidateReceived extends WebRTCEvent {
  final Map<String, dynamic> candidate;
  const RemoteIceCandidateReceived(this.candidate);

  @override
  List<Object?> get props => [candidate];
}

class LocalStreamReady extends WebRTCEvent {
  final MediaStream stream;
  const LocalStreamReady(this.stream);

  @override
  List<Object?> get props => [stream.id];
}

class RemoteStreamReady extends WebRTCEvent {
  final MediaStream stream;
  const RemoteStreamReady(this.stream);

  @override
  List<Object?> get props => [stream.id];
}

class ToggleAudio extends WebRTCEvent {}

class ToggleVideo extends WebRTCEvent {}
