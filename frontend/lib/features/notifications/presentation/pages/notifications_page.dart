import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/features/appointments/domain/entities/appointment_entity.dart';
import 'package:mediconnect_pro/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:mediconnect_pro/features/chat/presentation/providers/chat_providers.dart';
import 'package:mediconnect_pro/features/teleconsultations/domain/entities/teleconsultation_entity.dart';
import 'package:mediconnect_pro/features/teleconsultations/presentation/providers/teleconsultation_providers.dart';

/// Page « Notifications récentes » — agrège ce qui est utile pour l’utilisateur :
///   • Rendez-vous à venir / récents
///   • Messages reçus non lus
///   • Téléconsultations / appels récents
///
/// S’appuie sur les providers existants pour éviter de dupliquer la source
/// de vérité. Le contenu est rafraîchi via pull-to-refresh.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final teleconsultationsAsync = ref.watch(teleconsultationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myAppointmentsProvider);
          ref.invalidate(conversationsProvider);
          ref.invalidate(teleconsultationsProvider);
          await Future.wait([
            ref.read(myAppointmentsProvider.future),
            ref.read(conversationsProvider.future),
            ref.read(teleconsultationsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _SectionHeader(
              icon: Icons.event_available_rounded,
              title: 'Rendez-vous récents',
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            appointmentsAsync.when(
              loading: () => const _SectionLoader(),
              error: (e, _) => _SectionError(message: e.toString()),
              data: (items) {
                final recent = _filterRecentAppointments(items);
                if (recent.isEmpty) {
                  return const _EmptySection(
                    text: 'Aucun rendez-vous récent.',
                  );
                }
                return Column(
                  children: recent.map((a) {
                    return _NotificationTile(
                      icon: a.type == AppointmentType.video
                          ? Icons.videocam_rounded
                          : Icons.medical_services_rounded,
                      color: _appointmentColor(a.status),
                      title: a.doctorName ?? a.patientName ?? 'Rendez-vous',
                      subtitle: _appointmentSubtitle(a),
                      timestamp: a.dateTime,
                      onTap: () => context.push(
                        AppRoutes.appointmentDetail.replaceFirst(':id', a.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              icon: Icons.mark_chat_unread_rounded,
              title: 'Messages reçus',
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 8),
            conversationsAsync.when(
              loading: () => const _SectionLoader(),
              error: (e, _) => _SectionError(message: e.toString()),
              data: (items) {
                final unread = items.where((c) => c.unreadCount > 0).toList()
                  ..sort(
                      (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
                if (unread.isEmpty) {
                  return const _EmptySection(text: 'Aucun message non lu.');
                }
                return Column(
                  children: unread.map((c) {
                    return _NotificationTile(
                      icon: Icons.lock_rounded,
                      color: AppTheme.successColor,
                      title: c.otherMemberName,
                      subtitle:
                          '${c.unreadCount} message(s) chiffré(s) E2EE non lu(s)',
                      timestamp: c.lastMessageTime,
                      badge: c.unreadCount.toString(),
                      onTap: () => context.push(
                        AppRoutes.chatDetail
                            .replaceFirst(':conversationId', c.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              icon: Icons.call_rounded,
              title: 'Appels récents',
              color: AppTheme.videoCallColor,
            ),
            const SizedBox(height: 8),
            teleconsultationsAsync.when(
              loading: () => const _SectionLoader(),
              error: (e, _) => _SectionError(message: e.toString()),
              data: (items) {
                final recent = _filterRecentCalls(items);
                if (recent.isEmpty) {
                  return const _EmptySection(text: 'Aucun appel récent.');
                }
                return Column(
                  children: recent.map((t) {
                    final isVideo = t.callType.toUpperCase() == 'VIDEO';
                    return _NotificationTile(
                      icon:
                          isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: AppTheme.videoCallColor,
                      title: isVideo ? 'Appel vidéo' : 'Appel vocal',
                      subtitle: _callSubtitle(t),
                      timestamp: t.startedAtUtc ??
                          t.scheduledStartsAtUtc ??
                          t.endedAtUtc,
                      onTap: () => context.push(
                        AppRoutes.teleconsultationDetail
                            .replaceFirst(':id', t.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Filtres ────────────────────────────────────────────────

  List<Appointment> _filterRecentAppointments(List<Appointment> items) {
    final now = DateTime.now();
    final cutoffPast = now.subtract(const Duration(days: 7));
    final cutoffFuture = now.add(const Duration(days: 30));

    final filtered = items
        .where((a) =>
            a.dateTime.isAfter(cutoffPast) && a.dateTime.isBefore(cutoffFuture))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return filtered.take(10).toList();
  }

  List<TeleconsultationEntity> _filterRecentCalls(
      List<TeleconsultationEntity> items) {
    final sorted = [...items]..sort((a, b) {
        final ad = a.startedAtUtc ??
            a.scheduledStartsAtUtc ??
            a.endedAtUtc ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.startedAtUtc ??
            b.scheduledStartsAtUtc ??
            b.endedAtUtc ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    return sorted.take(10).toList();
  }

  Color _appointmentColor(AppointmentStatus s) {
    return switch (s) {
      AppointmentStatus.confirmed => AppTheme.successColor,
      AppointmentStatus.pending => AppTheme.warningColor,
      AppointmentStatus.cancelled => AppTheme.errorColor,
      AppointmentStatus.completed => AppTheme.neutralGray500,
      AppointmentStatus.noShow => AppTheme.errorColor,
    };
  }

  String _appointmentSubtitle(Appointment a) {
    final statusLabel = switch (a.status) {
      AppointmentStatus.confirmed => 'Confirmé',
      AppointmentStatus.pending => 'En attente',
      AppointmentStatus.cancelled => 'Annulé',
      AppointmentStatus.completed => 'Terminé',
      AppointmentStatus.noShow => 'Absent',
    };
    return '${a.type.label} · $statusLabel';
  }

  String _callSubtitle(TeleconsultationEntity t) {
    final status = switch (t.status.toLowerCase()) {
      'scheduled' => 'Programmé',
      'in_progress' || 'in-progress' || 'active' => 'En cours',
      'completed' || 'ended' => 'Terminé',
      'cancelled' || 'canceled' => 'Annulé',
      'failed' => 'Échec',
      _ => t.status,
    };
    return status;
  }
}

// ── Aggregated unread counter — used by the bell badge ─────────

/// Compte le total d’éléments « non lus » visibles dans la page notifications.
/// Utilisé par l’icône cloche du shell pour afficher un badge.
final notificationsUnreadCountProvider = Provider<int>((ref) {
  final conversations =
      ref.watch(conversationsProvider).valueOrNull ?? const [];
  final unreadMessages =
      conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  final appointments =
      ref.watch(myAppointmentsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  final upcoming = appointments
      .where((a) =>
          a.dateTime.isAfter(now) &&
          a.dateTime.isBefore(now.add(const Duration(days: 2))) &&
          (a.status == AppointmentStatus.confirmed ||
              a.status == AppointmentStatus.pending))
      .length;

  return unreadMessages + upcoming;
});

// ── Widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  const _SectionError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        message,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.neutralGray500),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final String? badge;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.timestamp,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.neutralGray200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timestamp != null)
              Text(
                _formatRelativeTime(timestamp!),
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.neutralGray500),
              ),
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatRelativeTime(DateTime when) {
    final now = DateTime.now();
    final local = when.toLocal();
    final diff = now.difference(local);

    if (diff.inSeconds.abs() < 60) {
      return diff.isNegative ? 'bientôt' : 'à l’instant';
    }
    if (diff.inMinutes.abs() < 60) {
      return diff.isNegative
          ? 'dans ${-diff.inMinutes} min'
          : 'il y a ${diff.inMinutes} min';
    }
    if (diff.inHours.abs() < 24 && local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    if (diff.inDays.abs() < 7) {
      return DateFormat('EEE HH:mm', 'fr_FR').format(local);
    }
    return DateFormat('dd/MM/yyyy').format(local);
  }
}
