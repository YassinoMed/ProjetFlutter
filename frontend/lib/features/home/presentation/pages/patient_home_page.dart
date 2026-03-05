import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PatientHomePage extends ConsumerWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myAppointmentsProvider.future),
        child: CustomScrollView(
          slivers: [
            // ── App Bar with gradient ───────────────────
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Bonjour, ${user?.name ?? 'Patient'} 👋',
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
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 40,
                        bottom: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick Actions ───────────────────
                    _buildQuickActions(context),
                    const SizedBox(height: 28),

                    // ── Upcoming Appointments Section ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mes prochains rendez-vous',
                          style: AppTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.go(AppRoutes.patientAppointments),
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Appointments list ───────────────
                    appointmentsAsync.when(
                      data: (appointments) {
                        final upcoming = appointments
                            .where((a) => a.dateTime.isAfter(DateTime.now()))
                            .toList()
                          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                        if (upcoming.isEmpty) {
                          return _buildNoAppointment(context);
                        }

                        return Column(
                          children: upcoming
                              .take(3)
                              .map((a) => _AppointmentCard(appointment: a))
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

                    const SizedBox(height: 24),

                    // ── Recent / past appointments ──────
                    appointmentsAsync.when(
                      data: (appointments) {
                        final past = appointments
                            .where((a) => a.dateTime.isBefore(DateTime.now()))
                            .toList()
                          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

                        if (past.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rendez-vous passés',
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neutralGray600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...past.take(2).map((a) =>
                                _AppointmentCard(appointment: a, isPast: true)),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickAction(
          icon: Icons.search_rounded,
          label: 'Chercher\nun médecin',
          color: AppTheme.primaryColor,
          onTap: () => context.push(AppRoutes.doctorSearch),
        ),
        _QuickAction(
          icon: Icons.history_edu_rounded,
          label: 'Dossier\nmédical',
          color: const Color(0xFF10B981),
          onTap: () => context.push(AppRoutes.patientRecords),
        ),
        _QuickAction(
          icon: Icons.videocam_rounded,
          label: 'Télé-\nconsultation',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.go(AppRoutes.patientAppointments),
        ),
      ],
    );
  }

  Widget _buildNoAppointment(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 36,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pas de rendez-vous prévu',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Trouvez un médecin et prenez rendez-vous en quelques clics.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.neutralGray500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.doctorSearch),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Prendre rendez-vous'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment Card ────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isPast;

  const _AppointmentCard({required this.appointment, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctor;
    final dateStr =
        DateFormat('EEE d MMM', 'fr_FR').format(appointment.dateTime);
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);
    final isVideo = appointment.type == AppointmentType.video;

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
        onTap: () => context.push(
            AppRoutes.appointmentDetail.replaceFirst(':id', appointment.id)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppTheme.neutralGray100
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(appointment.dateTime),
                      style: AppTheme.titleLarge.copyWith(
                        color: isPast
                            ? AppTheme.neutralGray500
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'fr_FR')
                          .format(appointment.dateTime)
                          .toUpperCase(),
                      style: AppTheme.labelSmall.copyWith(
                        color: isPast
                            ? AppTheme.neutralGray400
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor?.fullName ?? 'Médecin',
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPast ? AppTheme.neutralGray500 : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor?.specialty ?? 'Généraliste',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.neutralGray500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14, color: AppTheme.neutralGray400),
                        const SizedBox(width: 4),
                        Text('$dateStr • $timeStr',
                            style: AppTheme.labelSmall
                                .copyWith(color: AppTheme.neutralGray500)),
                        const SizedBox(width: 12),
                        if (isVideo) ...[
                          Icon(Icons.videocam_rounded,
                              size: 14, color: const Color(0xFF8B5CF6)),
                          const SizedBox(width: 4),
                          Text('Vidéo',
                              style: AppTheme.labelSmall.copyWith(
                                  color: const Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status + video button
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
                          label: const Text('Rejoindre',
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

// ── Quick Action Button ─────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
