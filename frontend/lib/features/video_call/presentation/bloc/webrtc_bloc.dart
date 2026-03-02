import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../data/services/webrtc_service.dart';
import 'webrtc_event.dart';
import 'webrtc_state.dart';

class WebRTCBloc extends Bloc<WebRTCEvent, WebRTCState> {
  final WebRTCService _webRTCService;

  WebRTCBloc({required WebRTCService webRTCService})
      : _webRTCService = webRTCService,
        super(WebRTCInitial()) {
    on<StartCall>(_onStartCall);
    on<LocalStreamReady>(_onLocalStreamReady);
    on<RemoteStreamReady>(_onRemoteStreamReady);
    on<RemoteOfferReceived>(_onRemoteOfferReceived);
    on<RemoteAnswerReceived>(_onRemoteAnswerReceived);
    on<RemoteIceCandidateReceived>(_onRemoteIceCandidateReceived);
    on<ToggleAudio>(_onToggleAudio);
    on<ToggleVideo>(_onToggleVideo);
    on<EndCall>(_onEndCall);
  }

  Future<void> _onStartCall(StartCall event, Emitter<WebRTCState> emit) async {
    emit(WebRTCSettingUp());
    try {
      await _webRTCService.initialize();

      _webRTCService.onAddRemoteStream = (stream) {
        if (!isClosed) add(RemoteStreamReady(stream));
      };

      _webRTCService.onConnectionClosed = () {
        if (!isClosed) add(EndCall());
      };

      if (_webRTCService.localStream != null) {
        add(LocalStreamReady(_webRTCService.localStream!));
      }

      await _webRTCService.createOffer();
    } catch (e) {
      emit(WebRTCError(e.toString()));
    }
  }

  void _onLocalStreamReady(LocalStreamReady event, Emitter<WebRTCState> emit) {
    if (state is WebRTCReady) {
      emit((state as WebRTCReady).copyWith(localStream: event.stream));
    } else {
      emit(WebRTCReady(localStream: event.stream));
    }
  }

  void _onRemoteStreamReady(
      RemoteStreamReady event, Emitter<WebRTCState> emit) {
    if (state is WebRTCReady) {
      emit((state as WebRTCReady).copyWith(remoteStream: event.stream));
    }
  }

  Future<void> _onRemoteOfferReceived(
      RemoteOfferReceived event, Emitter<WebRTCState> emit) async {
    final offerData = event.offer;
    final rtcOffer = RTCSessionDescription(offerData['sdp'], offerData['type']);
    await _webRTCService.createAnswer(rtcOffer);
  }

  Future<void> _onRemoteAnswerReceived(
      RemoteAnswerReceived event, Emitter<WebRTCState> emit) async {
    final answerData = event.answer;
    final rtcAnswer =
        RTCSessionDescription(answerData['sdp'], answerData['type']);
    await _webRTCService.handleRemoteAnswer(rtcAnswer);
  }

  Future<void> _onRemoteIceCandidateReceived(
      RemoteIceCandidateReceived event, Emitter<WebRTCState> emit) async {
    try {
      final candidateData = event.candidate;
      final rtcCandidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await _webRTCService.handleRemoteIceCandidate(rtcCandidate);
    } catch (e) {
      // Ignore if candidate parsing fails or RTCPeerConnection not ready
    }
  }

  void _onToggleAudio(ToggleAudio event, Emitter<WebRTCState> emit) {
    if (state is WebRTCReady) {
      final currentState = state as WebRTCReady;
      final isMuted = !currentState.isAudioMuted;
      _webRTCService.toggleAudio(!isMuted);
      emit(currentState.copyWith(isAudioMuted: isMuted));
    }
  }

  void _onToggleVideo(ToggleVideo event, Emitter<WebRTCState> emit) {
    if (state is WebRTCReady) {
      final currentState = state as WebRTCReady;
      final isVideoMuted = !currentState.isVideoMuted;
      _webRTCService.toggleVideo(!isVideoMuted);
      emit(currentState.copyWith(isVideoMuted: isVideoMuted));
    }
  }

  Future<void> _onEndCall(EndCall event, Emitter<WebRTCState> emit) async {
    await _webRTCService.dispose();
    emit(WebRTCEnded());
  }

  @override
  Future<void> close() {
    _webRTCService.dispose();
    return super.close();
  }
}
