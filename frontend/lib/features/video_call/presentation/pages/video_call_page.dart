import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';
import 'package:mediconnect_pro/features/video_call/presentation/providers/video_call_providers.dart';

class VideoCallPage extends ConsumerStatefulWidget {
  final String appointmentId;
  const VideoCallPage({super.key, required this.appointmentId});

  @override
  ConsumerState<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends ConsumerState<VideoCallPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize the call
    Future.microtask(() {
      ref
          .read(videoCallNotifierProvider(widget.appointmentId).notifier)
          .initializeCall();
    });

    _startControlsTimer();
  }

  void _startControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState =
        ref.watch(videoCallNotifierProvider(widget.appointmentId));
    final notifier =
        ref.read(videoCallNotifierProvider(widget.appointmentId).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _startControlsTimer();
        },
        child: Stack(
          children: [
            // ── Remote Video (Full screen) ──────────────────
            Positioned.fill(
              child: callState.state == CallState.connected
                  ? RTCVideoView(
                      notifier.remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : _buildWaitingState(callState),
            ),

            // ── Local Video (PiP overlay) ───────────────────
            if (callState.isVideoEnabled)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                width: 110,
                height: 160,
                child: _buildLocalVideo(notifier),
              ),

            // ── Top bar (status + duration) ─────────────────
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(callState),
              ),

            // ── Bottom Controls ─────────────────────────────
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildControls(callState, notifier),
              ),

            // ── Connection Quality Indicator ────────────────
            if (callState.state == CallState.reconnecting)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reconnexion en cours…',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingState(VideoCallEntity callState) {
    String statusText;
    IconData statusIcon;

    switch (callState.state) {
      case CallState.idle:
      case CallState.joining:
        statusText = 'Connexion en cours…';
        statusIcon = Icons.wifi_calling_3_rounded;
      case CallState.ringing:
        statusText = 'Appel en cours…';
        statusIcon = Icons.ring_volume_rounded;
      case CallState.reconnecting:
        statusText = 'Reconnexion…';
        statusIcon = Icons.wifi_off_rounded;
      case CallState.error:
        statusText = callState.errorMessage ?? 'Erreur de connexion';
        statusIcon = Icons.error_outline_rounded;
      case CallState.ended:
        statusText = 'Appel terminé';
        statusIcon = Icons.call_end_rounded;
      default:
        statusText = 'En attente…';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E21), Color(0xFF1A1A2E)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.2),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(statusIcon, size: 48, color: Colors.blue[300]),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (callState.state == CallState.error) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalVideo(VideoCallNotifier notifier) {
    return GestureDetector(
      onDoubleTap: () => notifier.switchCamera(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: RTCVideoView(
          notifier.localRenderer,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }

  Widget _buildTopBar(VideoCallEntity callState) {
    final duration = callState.duration;
    final durationStr =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => _endCall(context),
          ),
          const Spacer(),
          if (callState.state == CallState.connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.green.withOpacity(0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    durationStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // E2E encryption badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.greenAccent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(VideoCallEntity callState, VideoCallNotifier notifier) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mic toggle
          _ControlBtn(
            icon: callState.isAudioMuted
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            label: callState.isAudioMuted ? 'Unmute' : 'Muet',
            isActive: !callState.isAudioMuted,
            onPressed: () => notifier.toggleAudio(),
          ),

          // Video toggle
          _ControlBtn(
            icon: callState.isVideoEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: callState.isVideoEnabled ? 'Caméra' : 'Caméra Off',
            isActive: callState.isVideoEnabled,
            onPressed: () => notifier.toggleVideo(),
          ),

          // End call
          _ControlBtn(
            icon: Icons.call_end_rounded,
            label: 'Raccrocher',
            isDestructive: true,
            onPressed: () => _endCall(context),
          ),

          // Switch camera
          _ControlBtn(
            icon: Icons.switch_camera_rounded,
            label: 'Retourner',
            isActive: true,
            onPressed: () => notifier.switchCamera(),
          ),
        ],
      ),
    );
  }

  Future<void> _endCall(BuildContext context) async {
    await ref
        .read(videoCallNotifierProvider(widget.appointmentId).notifier)
        .endCall();
    if (context.mounted) Navigator.pop(context);
  }
}

// ── Control Button Widget ───────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ControlBtn({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDestructive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDestructive
        ? Colors.red
        : isActive
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.1);

    final iconColor = isDestructive
        ? Colors.white
        : isActive
            ? Colors.white
            : Colors.white54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bgColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
