import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/features/video_call/domain/entities/video_call_entity.dart';
import 'package:mediconnect_pro/features/video_call/presentation/providers/video_call_providers.dart';
import 'package:mediconnect_pro/features/video_call/presentation/widgets/inline_call_chat_panel.dart';

class VideoCallPage extends ConsumerStatefulWidget {
  final String appointmentId;
  const VideoCallPage({super.key, required this.appointmentId});

  @override
  ConsumerState<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends ConsumerState<VideoCallPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  bool _showControls = true;
  bool _showChatPanel = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(videoCallNotifierProvider(widget.appointmentId).notifier)
        .handleLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    final callState =
        ref.watch(videoCallNotifierProvider(widget.appointmentId));
    final notifier =
        ref.read(videoCallNotifierProvider(widget.appointmentId).notifier);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _startControlsTimer();
        },
        child: Stack(
          children: [
            // ── Remote Video (Full screen) ──────────────────
            Positioned.fill(
              child: callState.state == CallState.connected &&
                      callState.hasRemoteVideo
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

            if (_showChatPanel)
              Positioned(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).padding.bottom + 104,
                height: 340,
                child: InlineCallChatPanel(
                  appointmentId: widget.appointmentId,
                  onClose: () => setState(() => _showChatPanel = false),
                ),
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
                    color: AppTheme.warningColor.withValues(alpha: 0.92),
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
      case CallState.resolvingSession:
        statusText = 'Connexion en cours…';
        statusIcon = Icons.wifi_calling_3_rounded;
      case CallState.waitingHost:
        statusText = 'En attente du médecin…';
        statusIcon = Icons.schedule_send_rounded;
      case CallState.ringing:
        statusText = 'Appel en cours…';
        statusIcon = Icons.ring_volume_rounded;
      case CallState.joining:
        statusText = 'Connexion a la session…';
        statusIcon = Icons.video_call_rounded;
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
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
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
                    color: AppTheme.primaryLight.withValues(alpha: 0.16),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.32),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    statusIcon,
                    size: 48,
                    color: AppTheme.primaryLight,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            statusText,
            style: AppTheme.titleLarge.copyWith(
              color: Colors.white70,
            ),
          ),
          if (callState.state == CallState.error) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          if (callState.state == CallState.waitingHost) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(videoCallNotifierProvider(widget.appointmentId)
                        .notifier)
                    .retryJoin();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.24), width: 1.4),
          boxShadow: AppTheme.shadowLg,
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
            Colors.black.withValues(alpha: 0.72),
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
                color: AppTheme.successColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
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
              color: AppTheme.successColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppTheme.successColor,
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
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 12,
        children: [
          _ControlBtn(
            icon: callState.isAudioMuted
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            label: callState.isAudioMuted ? 'Unmute' : 'Muet',
            isActive: !callState.isAudioMuted,
            onPressed: () => notifier.toggleAudio(),
          ),
          _ControlBtn(
            icon: callState.isVideoEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: callState.isVideoEnabled ? 'Caméra' : 'Caméra Off',
            isActive: callState.isVideoEnabled,
            onPressed: () => notifier.toggleVideo(),
          ),
          _ControlBtn(
            icon: Icons.call_end_rounded,
            label: 'Raccrocher',
            isDestructive: true,
            onPressed: () => _endCall(context),
          ),
          _ControlBtn(
            icon: callState.isSpeakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: callState.isSpeakerOn ? 'Haut-parleur' : 'Ecouteur',
            isActive: callState.isSpeakerOn,
            onPressed: () => notifier.toggleSpeaker(),
          ),
          _ControlBtn(
            icon: Icons.switch_camera_rounded,
            label: 'Retourner',
            isActive: true,
            onPressed: () => notifier.switchCamera(),
          ),
          _ControlBtn(
            icon: _showChatPanel
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            isActive: _showChatPanel,
            onPressed: () => setState(() => _showChatPanel = !_showChatPanel),
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
        ? AppTheme.errorColor
        : isActive
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.1);

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
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
