import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';

import '../providers/teleconsultation_providers.dart';

class IncomingCallPage extends ConsumerStatefulWidget {
  final String teleconsultationId;
  final Map<String, dynamic>? payload;

  const IncomingCallPage({
    super.key,
    required this.teleconsultationId,
    this.payload,
  });

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    final expiresAtRaw = widget.payload?['expires_at_utc']?.toString();
    final expiresAt =
        expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw);

    if (expiresAt == null) {
      return;
    }

    void update() {
      final delta = expiresAt.difference(DateTime.now().toUtc());
      setState(() {
        _remaining = delta.isNegative ? Duration.zero : delta;
      });
    }

    update();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  @override
  Widget build(BuildContext context) {
    final teleconsultationAsync =
        ref.watch(teleconsultationDetailProvider(widget.teleconsultationId));

    final callerName =
        widget.payload?['caller_name']?.toString() ?? 'Votre médecin';
    final callType = widget.payload?['call_type']?.toString() ?? 'VIDEO';

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: teleconsultationAsync.when(
        data: (teleconsultation) {
          final appointmentId = teleconsultation.appointmentId;
          final scheduledAt = teleconsultation.scheduledStartsAtUtc == null
              ? null
              : DateFormat('dd/MM/yyyy HH:mm')
                  .format(teleconsultation.scheduledStartsAtUtc!.toLocal());

          final isStillJoinable = teleconsultation.status == 'ringing' ||
              teleconsultation.status == 'scheduled' ||
              teleconsultation.status == 'active';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.15),
                        child: Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.video_camera_front_rounded,
                            color: Colors.white,
                            size: 62,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    callerName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appel entrant en ${callType.toLowerCase()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  if (scheduledAt != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Prévu à $scheduledAt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                    ),
                  ],
                  if (_remaining != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _remaining == Duration.zero
                          ? 'La sonnerie a expiré'
                          : 'Expiration dans ${_formatDuration(_remaining!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: !isStillJoinable
                              ? null
                              : () async {
                                  await ref
                                      .read(teleconsultationActionsProvider)
                                      .cancel(widget.teleconsultationId);
                                  if (context.mounted) {
                                    context.go(AppRoutes.teleconsultations);
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          icon: const Icon(Icons.call_end_rounded),
                          label: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: !isStillJoinable
                              ? null
                              : () {
                                  context.go(
                                    AppRoutes.videoCall.replaceFirst(
                                      ':appointmentId',
                                      appointmentId,
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_disabled_rounded,
                    color: Colors.white70, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger l’appel entrant.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
