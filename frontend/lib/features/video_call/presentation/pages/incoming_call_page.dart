import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../data/services/call_notification_service.dart';
import '../../domain/entities/call_status.dart';

class IncomingVideoCallPage extends StatefulWidget {
  final String appointmentId;
  final String doctorName;
  final String specialty;
  final String? doctorAvatarUrl;
  final Duration timeout;

  const IncomingVideoCallPage({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.specialty,
    this.doctorAvatarUrl,
    this.timeout = CallNotificationService.defaultTimeout,
  });

  @override
  State<IncomingVideoCallPage> createState() => _IncomingVideoCallPageState();
}

class _IncomingVideoCallPageState extends State<IncomingVideoCallPage>
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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _status != CallStatus.ringing) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _status = _notificationService.timeoutStatus(isIncoming: true);
          _message = _notificationService.timeoutMessage(isIncoming: true);
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
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isRinging ? 1 + (_pulseController.value * 0.10) : 1,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: ClinicalAvatar(
                          name: widget.doctorName,
                          imageUrl: widget.doctorAvatarUrl,
                          radius: 56,
                          accentColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                widget.doctorName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.specialty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                _message ??
                    (isRinging
                        ? 'Appel entrant · expiration dans ${_format(_remaining)}'
                        : _status.label),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              const Spacer(),
              if (isRinging) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() => _status = CallStatus.rejected);
                          context.pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        icon: const Icon(Icons.call_end_rounded),
                        label: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go(
                          AppRoutes.videoCall.replaceFirst(
                            ':appointmentId',
                            widget.appointmentId,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        icon: const Icon(Icons.call_rounded),
                        label: const Text('Répondre'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour'),
                ),
              ],
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
