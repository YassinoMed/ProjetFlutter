/// Page « Vous êtes en attente du Dr X » côté patient.
///
/// - Animation pulse autour de l'avatar
/// - Compteur du temps d'attente
/// - Bouton « Quitter la salle d'attente »
/// - Surveillance du statut : si admis, redirection automatique vers
///   `/video-call/[appointmentId]` ; si refusé/reporté, message clair +
///   retour à la liste des RDV.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/waiting_room_session.dart';
import '../providers/waiting_room_providers.dart';

class WaitingRoomPatientPage extends ConsumerStatefulWidget {
  final String sessionId;
  const WaitingRoomPatientPage({super.key, required this.sessionId});

  @override
  ConsumerState<WaitingRoomPatientPage> createState() =>
      _WaitingRoomPatientPageState();
}

class _WaitingRoomPatientPageState extends ConsumerState<WaitingRoomPatientPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _handledTerminal = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final session =
          ref.read(waitingSessionByIdProvider(widget.sessionId));
      if (session != null) {
        setState(() {
          _elapsed = DateTime.now().toUtc().difference(session.joinedAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onTerminal(WaitingRoomSession session) {
    if (_handledTerminal) return;
    _handledTerminal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (session.status == WaitingRoomStatus.admitted) {
        // Redirection automatique vers l'appel.
        context.pushReplacement(
          AppRoutes.videoCall
              .replaceFirst(':appointmentId', session.appointmentId),
        );
      } else {
        // Refusé / reporté / annulé / expiré → on reste sur la page
        // mais on affiche l'état final via le widget below.
      }
    });
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter la salle d\'attente ?'),
        content: const Text(
          'Vous perdrez votre place. Vous pourrez la rejoindre à nouveau '
          'depuis votre rendez-vous.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rester'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(waitingRoomStoreProvider.notifier).cancel(widget.sessionId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(waitingSessionByIdProvider(widget.sessionId));

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Salle d\'attente')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Session introuvable. Elle a peut-être expiré ou été annulée.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Si le statut devient terminal pendant qu'on regarde, on déclenche
    // la transition.
    if (session.status.isTerminal ||
        session.status == WaitingRoomStatus.admitted) {
      _onTerminal(session);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salle d\'attente'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _PulsingAvatar(controller: _pulse, name: session.doctorName),
              const SizedBox(height: 28),
              Text(
                _statusTitle(session),
                style: AppTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _statusSubtitle(session),
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.neutralGray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (session.status == WaitingRoomStatus.waiting)
                _WaitingTimer(elapsed: _elapsed)
              else
                _TerminalBanner(session: session),
              const Spacer(),
              if (session.status == WaitingRoomStatus.waiting)
                OutlinedButton.icon(
                  onPressed: _leave,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Quitter la salle d\'attente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    minimumSize: const Size.fromHeight(48),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusTitle(WaitingRoomSession s) {
    return switch (s.status) {
      WaitingRoomStatus.waiting => 'En attente du Dr ${s.doctorName}',
      WaitingRoomStatus.admitted => 'Vous êtes admis · démarrage de l\'appel…',
      WaitingRoomStatus.rejected => 'Votre demande a été refusée',
      WaitingRoomStatus.cancelled => 'Vous avez quitté la salle',
      WaitingRoomStatus.expired => 'Session expirée',
    };
  }

  String _statusSubtitle(WaitingRoomSession s) {
    return switch (s.status) {
      WaitingRoomStatus.waiting =>
        'Votre médecin vous accueillera dans quelques instants.',
      WaitingRoomStatus.admitted => 'Connexion en cours…',
      WaitingRoomStatus.rejected => s.rescheduledTo != null
          ? 'Votre médecin propose un report.'
          : (s.rejectionReason ??
              'Votre médecin n\'est pas disponible pour cet appel.'),
      WaitingRoomStatus.cancelled =>
        'Vous pouvez rejoindre à nouveau depuis votre rendez-vous.',
      WaitingRoomStatus.expired => 'La session a expiré (>30 min sans réponse).',
    };
  }
}

class _PulsingAvatar extends StatelessWidget {
  final AnimationController controller;
  final String name;
  const _PulsingAvatar({required this.controller, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty
        ? '?'
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p.isEmpty ? '' : p[0])
            .join()
            .toUpperCase();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Container(
          width: 160 + 40 * t,
          height: 160 + 40 * t,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withValues(alpha: 0.18 * (1 - t)),
          ),
          child: Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.32),
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaitingTimer extends StatelessWidget {
  final Duration elapsed;
  const _WaitingTimer({required this.elapsed});

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined,
                size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Temps d\'attente · ${_format(elapsed)}',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalBanner extends StatelessWidget {
  final WaitingRoomSession session;
  const _TerminalBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final color = switch (session.status) {
      WaitingRoomStatus.admitted => AppTheme.successColor,
      WaitingRoomStatus.rejected => AppTheme.errorColor,
      _ => AppTheme.neutralGray500,
    };
    final icon = switch (session.status) {
      WaitingRoomStatus.admitted => Icons.check_circle_outline_rounded,
      WaitingRoomStatus.rejected => Icons.cancel_outlined,
      _ => Icons.info_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              session.status.labelFr,
              style: AppTheme.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
