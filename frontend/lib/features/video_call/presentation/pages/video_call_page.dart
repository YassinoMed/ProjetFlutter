import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallPage extends StatefulWidget {
  final String appointmentId;
  const VideoCallPage({super.key, required this.appointmentId});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _isMicOn = true;
  bool _isCamOn = true;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _setupMedia();
  }

  Future<void> _setupMedia() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    _localRenderer.srcObject = stream;
    setState(() {});
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
          // Local Video (Small Overlay)
          Positioned(
            top: 40,
            right: 20,
            width: 120,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: RTCVideoView(_localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),
          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  onPressed: () => setState(() => _isMicOn = !_isMicOn),
                  color: _isMicOn ? Colors.white24 : Colors.red,
                ),
                _ControlButton(
                  icon: Icons.call_end_rounded,
                  onPressed: () => Navigator.pop(context),
                  color: Colors.red,
                  iconSize: 32,
                ),
                _ControlButton(
                  icon: _isCamOn
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  onPressed: () => setState(() => _isCamOn = !_isCamOn),
                  color: _isCamOn ? Colors.white24 : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double iconSize;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: color,
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}
