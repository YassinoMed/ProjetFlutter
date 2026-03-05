import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DoctorHomePage extends ConsumerWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myAppointmentsProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Dr. ${user?.name ?? ''}',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.neutralWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -40,
                        top: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {},
                  tooltip: 'Notifications',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick Stats ─────────────────────
                    appointmentsAsync.when(
                      data: (appointments) =>
                          _buildQuickStats(context, appointments),
                      loading: () => _buildQuickStats(context, []),
                      error: (_, __) => _buildQuickStats(context, []),
                    ),
                    const SizedBox(height: 28),

                    // ── Today's Consultations ───────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Consultations du jour',
                          style: AppTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.go(AppRoutes.doctorAppointments),
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Planning'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    appointmentsAsync.when(
                      data: (appointments) {
                        final today = DateTime.now();
                        final todayAppts = appointments.where((a) {
                          return a.dateTime.year == today.year &&
                              a.dateTime.month == today.month &&
                              a.dateTime.day == today.day;
                        }).toList()
                          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                        if (todayAppts.isEmpty) {
                          return _buildNoAppointmentsToday(context);
                        }

                        return Column(
                          children: todayAppts
                              .map(
                                  (a) => _DoctorAppointmentCard(appointment: a))
                              .toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, st) => ErrorDisplay(
                        compact: true,
                        message: err.toString(),
                        onRetry: () => ref.refresh(myAppointmentsProvider),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Upcoming Appointments ───────────
                    appointmentsAsync.when(
                      data: (appointments) {
                        final today = DateTime.now();
                        final upcoming = appointments.where((a) {
                          final isFuture = a.dateTime.isAfter(today);
                          final isNotToday = !(a.dateTime.year == today.year &&
                              a.dateTime.month == today.month &&
                              a.dateTime.day == today.day);
                          return isFuture && isNotToday;
                        }).toList()
                          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                        if (upcoming.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prochains rendez-vous',
                              style: AppTheme.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...upcoming.take(5).map(
                                (a) => _DoctorAppointmentCard(appointment: a)),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
      BuildContext context, List<Appointment> appointments) {
    final today = DateTime.now();

    final todayCount = appointments.where((a) {
      return a.dateTime.year == today.year &&
          a.dateTime.month == today.month &&
          a.dateTime.day == today.day;
    }).length;

    final pendingCount =
        appointments.where((a) => a.status == AppointmentStatus.pending).length;

    final videoCount = appointments
        .where(
            (a) => a.type == AppointmentType.video && a.dateTime.isAfter(today))
        .length;

    return Row(
      children: [
        _StatCard(
          title: "Aujourd'hui",
          value: todayCount.toString(),
          icon: Icons.people_rounded,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: 'En attente',
          value: pendingCount.toString(),
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: 'Téléconsult.',
          value: videoCount.toString(),
          icon: Icons.videocam_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => context.go(AppRoutes.doctorAppointments),
        ),
      ],
    );
  }

  Widget _buildNoAppointmentsToday(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 36,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune consultation aujourd\'hui',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre planning est libre pour le moment.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.neutralGray500),
          ),
        ],
      ),
    );
  }
}

// ── Doctor Appointment Card ─────────────────────────────────

class _DoctorAppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _DoctorAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);
    final dateStr =
        DateFormat('EEE d MMM', 'fr_FR').format(appointment.dateTime);
    final isVideo = appointment.type == AppointmentType.video;
    final isPast = appointment.dateTime.isBefore(DateTime.now());

    // Get patient display name
    final patientName = appointment.patientName ?? 'Patient';
    final initials = patientName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPast ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPast
            ? BorderSide(color: AppTheme.neutralGray200)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.doctorAppointmentDetail
            .replaceFirst(':id', appointment.id)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time badge
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppTheme.neutralGray100
                      : isVideo
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      timeStr,
                      style: AppTheme.titleSmall.copyWith(
                        color: isPast
                            ? AppTheme.neutralGray500
                            : isVideo
                                ? const Color(0xFF8B5CF6)
                                : AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isVideo)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.videocam_rounded,
                            size: 14,
                            color: isPast
                                ? AppTheme.neutralGray400
                                : const Color(0xFF8B5CF6)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Patient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            initials.isNotEmpty ? initials : 'P',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          patientName,
                          style: AppTheme.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isPast ? AppTheme.neutralGray500 : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: AppTheme.neutralGray400),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: AppTheme.labelSmall
                              .copyWith(color: AppTheme.neutralGray500),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVideo
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                : const Color(0xFF10B981)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isVideo ? 'Vidéo' : 'Présentiel',
                            style: AppTheme.labelSmall.copyWith(
                              color: isVideo
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: appointment.status),
                  if (isVideo &&
                      !isPast &&
                      (appointment.status == AppointmentStatus.confirmed ||
                          appointment.status == AppointmentStatus.pending))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(AppRoutes.videoCall
                              .replaceFirst(':appointmentId', appointment.id)),
                          icon: const Icon(Icons.videocam, size: 16),
                          label: const Text('Démarrer',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status Chip ─────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case AppointmentStatus.confirmed:
        color = const Color(0xFF10B981);
        label = 'Confirmé';
      case AppointmentStatus.pending:
        color = const Color(0xFFF59E0B);
        label = 'En attente';
      case AppointmentStatus.cancelled:
        color = const Color(0xFFEF4444);
        label = 'Annulé';
      case AppointmentStatus.completed:
        color = const Color(0xFF3B82F6);
        label = 'Terminé';
      case AppointmentStatus.noShow:
        color = const Color(0xFF6B7280);
        label = 'Absent';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
