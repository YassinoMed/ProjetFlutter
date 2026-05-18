import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../data/services/call_notification_service.dart';
import '../../domain/entities/call_status.dart';

class OutgoingCallPage extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final String? patientAvatarUrl;
  final Duration timeout;

  const OutgoingCallPage({
    super.key,
    required this.appointmentId,
    required this.patientName,
    this.patientAvatarUrl,
    this.timeout = CallNotificationService.defaultTimeout,
  });

  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage>
    with SingleTickerProviderStateMixin {
  final _notificationService = const CallNotificationService();
  late final AnimationController _pulseController;
  Timer? _timer;
  late Duration _remaining;
  CallStatus _status = CallStatus.ringing;
  String? _message;

  @override
  void initState() {
    super.initState();
    _remaining = widget.timeout;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _status != CallStatus.ringing) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _status = _notificationService.timeoutStatus(isIncoming: false);
          _message = _notificationService.timeoutMessage(isIncoming: false);
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRinging = _status == CallStatus.ringing;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  color: Colors.white70,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isRinging ? 1 + (_pulseController.value * 0.12) : 1,
                    child: Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: ClinicalAvatar(
                          name: widget.patientName,
                          imageUrl: widget.patientAvatarUrl,
                          radius: 54,
                          accentColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                widget.patientName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _status.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _message ??
                    (isRinging
                        ? 'Expiration dans ${_format(_remaining)}'
                        : 'Vous pouvez annuler ou entrer manuellement dans l’appel.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const Spacer(),
              if (_status == CallStatus.ringing) ...[
                FilledButton.icon(
                  onPressed: () =>
                      setState(() => _status = CallStatus.accepted),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Patient a répondu'),
                ),
                const SizedBox(height: 12),
              ],
              if (_status.canEnterCall) ...[
                FilledButton.icon(
                  onPressed: () => context.go(
                    AppRoutes.videoCall
                        .replaceFirst(':appointmentId', widget.appointmentId),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.video_camera_front_rounded),
                  label: const Text('Entrer dans l’appel'),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _status = CallStatus.cancelled);
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size.fromHeight(54),
                ),
                icon: const Icon(Icons.call_end_rounded),
                label: const Text('Annuler l’appel'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 99);
    return '00:${seconds.toString().padLeft(2, '0')}';
  }
}
