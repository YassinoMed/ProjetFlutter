import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/services/webrtc_service.dart';
import '../bloc/webrtc_bloc.dart';
import '../bloc/webrtc_event.dart';
import '../bloc/webrtc_state.dart';

class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String apiUrl;
  final String token;
  // Options for Echo server connectivity
  final String reverbHost;
  final String reverbPort;
  final String reverbAppKey;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.apiUrl,
    required this.token,
    required this.reverbHost,
    required this.reverbPort,
    required this.reverbAppKey,
  });

  @override
  VideoCallScreenState createState() => VideoCallScreenState();
}

class VideoCallScreenState extends State<VideoCallScreen> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late WebRTCBloc _webRTCBloc;
  WebSocketChannel? _echoChannel;

  @override
  void initState() {
    super.initState();
    _initRenderers();

    // Initialiser le BLoC et le Service
    _webRTCBloc = WebRTCBloc(
      webRTCService: WebRTCService(
        appointmentId: widget.appointmentId,
        apiUrl: widget.apiUrl,
        token: widget.token,
      ),
    );

    // Initialiser la connexion Reverb (Echo)
    _initEchoConnection();

    // Démarrer l'appel
    _webRTCBloc.add(StartCall());
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _initEchoConnection() {
    // Basic connection to Laravel Echo (implementation using bare WebSocket for simplified logic)
    // Connecting to ws socket
    final url = Uri.parse(
        'ws://${widget.reverbHost}:${widget.reverbPort}/app/${widget.reverbAppKey}?protocol=7&client=js&version=8.4.0-rc2&flash=false');

    _echoChannel = WebSocketChannel.connect(url);

    _echoChannel!.stream.listen((message) {
      if (message == null) return;
      try {
        final Map<String, dynamic> data = jsonDecode(message);
        final event = data['event'];
        // Parse pusher channel data and Reverb auth
        if (event == 'pusher:connection_established') {
          _subscribeToChannel();
        } else if (event == 'App\\Events\\WebRtcOfferSent') {
          final payload = jsonDecode(data['data']);
          _webRTCBloc.add(RemoteOfferReceived(
              {'type': payload['sdp_type'], 'sdp': payload['sdp']}));
        } else if (event == 'App\\Events\\WebRtcAnswerSent') {
          final payload = jsonDecode(data['data']);
          _webRTCBloc.add(RemoteAnswerReceived(
              {'type': payload['sdp_type'], 'sdp': payload['sdp']}));
        } else if (event == 'App\\Events\\WebRtcIceCandidateSent') {
          final payload = jsonDecode(data['data']);
          _webRTCBloc.add(RemoteIceCandidateReceived({
            'candidate': payload['candidate'],
            'sdpMid': payload['sdp_mid'],
            'sdpMLineIndex': payload['sdp_mline_index'],
          }));
        }
      } catch (e) {
        debugPrint("Echo Event Error: $e");
      }
    });
  }

  void _subscribeToChannel() {
    // Demande l'authentification auprès de Laravel si nécessaire,
    // puis s'abonne à la private channel 'consultations.appointmentId'
    final authMessage = jsonEncode({
      "event": "pusher:subscribe",
      "data": {
        "auth": widget
            .token, // This actually needs server signing for Pusher protocol
        "channel": "private-consultations.${widget.appointmentId}"
      }
    });
    _echoChannel?.sink.add(authMessage);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _echoChannel?.sink.close();
    _webRTCBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _webRTCBloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Consultation Vidéo'),
          backgroundColor: Colors.transparent,
        ),
        body: BlocConsumer<WebRTCBloc, WebRTCState>(
          listener: (context, state) {
            if (state is WebRTCEnded) {
              Navigator.of(context).pop();
            } else if (state is WebRTCError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: ${state.message}')),
              );
            } else if (state is WebRTCReady) {
              if (_localRenderer.srcObject != state.localStream) {
                _localRenderer.srcObject = state.localStream;
              }
              if (_remoteRenderer.srcObject != state.remoteStream) {
                _remoteRenderer.srcObject = state.remoteStream;
              }
            }
          },
          builder: (context, state) {
            if (state is WebRTCSettingUp || state is WebRTCInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final isReady = state is WebRTCReady;
            final isAudioMuted = isReady ? state.isAudioMuted : false;
            final isVideoMuted = isReady ? state.isVideoMuted : false;

            return Stack(
              children: [
                // Remote View (Full Screen)
                Positioned.fill(
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
                // Local View (Picture in Picture)
                Positioned(
                  bottom: 120.0,
                  right: 20.0,
                  width: 120.0,
                  height: 160.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
                // Control Panel
                Positioned(
                  bottom: 40.0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: "muteAudio",
                        backgroundColor:
                            isAudioMuted ? Colors.red : Colors.white,
                        child: Icon(
                          isAudioMuted ? Icons.mic_off : Icons.mic,
                          color: isAudioMuted ? Colors.white : Colors.black,
                        ),
                        onPressed: () => _webRTCBloc.add(ToggleAudio()),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        heroTag: "endCall",
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end, color: Colors.white),
                        onPressed: () => _webRTCBloc.add(EndCall()),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        heroTag: "muteVideo",
                        backgroundColor:
                            isVideoMuted ? Colors.red : Colors.white,
                        child: Icon(
                          isVideoMuted ? Icons.videocam_off : Icons.videocam,
                          color: isVideoMuted ? Colors.white : Colors.black,
                        ),
                        onPressed: () => _webRTCBloc.add(ToggleVideo()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
