library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/genui/genui_prompt_panel.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../waiting_room/presentation/providers/waiting_room_providers.dart';

class DoctorHomePage extends ConsumerWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;
    final appointmentsAsync = ref.watch(myAppointmentsProvider);
    final appointments = appointmentsAsync.valueOrNull ?? const <Appointment>[];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myAppointmentsProvider);
            await ref.read(myAppointmentsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, Dr. ${user?.name.split(' ').last ?? ''}',
                          style: AppTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vue rapide de votre activité clinique.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.neutralGray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NotificationsBell(ref: ref),
                  const SizedBox(width: 8),
                  ClinicalAvatar(
                    name: user?.name ?? 'Médecin',
                    imageUrl: user?.avatarUrl,
                    radius: 24,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              appointmentsAsync.when(
                data: (appointments) {
                  final today = DateTime.now();
                  final todayAppointments = appointments.where((item) {
                    return item.dateTime.year == today.year &&
                        item.dateTime.month == today.month &&
                        item.dateTime.day == today.day;
                  }).toList()
                    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  final pendingAppointments = appointments
                      .where((item) => item.status == AppointmentStatus.pending)
                      .length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DoctorMetricCard(
                              value: '${todayAppointments.length}',
                              label: 'RDV aujourd’hui',
                              color: AppTheme.primaryColor,
                              icon: Icons.calendar_today_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DoctorMetricCard(
                              value: '$pendingAppointments',
                              label: 'En attente',
                              color: AppTheme.successColor,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.shadowPrimary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+14%',
                                      style: AppTheme.headlineMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Performance hebdo',
                                      style: AppTheme.labelSmall.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.86),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const ClinicalSectionHeader(
                        title: 'En attente',
                        eyebrow: 'Flux du jour',
                      ),
                      const SizedBox(height: 12),
                      if (todayAppointments.isEmpty)
                        const ClinicalEmptyState(
                          icon: Icons.event_busy_outlined,
                          title: 'Aucune consultation aujourd’hui',
                          message: 'Votre agenda du jour est encore libre.',
                        )
                      else
                        Column(
                          children: todayAppointments
                              .take(2)
                              .map((appointment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _DoctorQueueCard(
                                      appointment: appointment,
                                    ),
                                  ))
                              .toList(),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => ErrorDisplay(
                  compact: true,
                  message: err.toString(),
                  onRetry: () => ref.invalidate(myAppointmentsProvider),
                ),
              ),
              const SizedBox(height: 24),
              // Actions rapides « Salle d'attente » + « Ordonnance »
              Row(
                children: [
                  Expanded(
                    child: _WaitingRoomQuickAction(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.prescriptionCreate),
                      icon: const Icon(Icons.medical_information_outlined),
                      label: const Text('Ordonnance'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GenUiPromptPanel(
                sessionId: 'doctor-home-${user?.id ?? 'anonymous'}',
                role: user?.role ?? AppConstants.roleDoctor,
                title: 'Brief clinique',
                prompt:
                    'Génère un briefing médecin pour l’écran d’accueil avec MetricCard, AppointmentCard pour les prochains rendez-vous, Checklist et ActionButton. '
                    'Ne donne aucun diagnostic.',
                contextData: _doctorHomeContext(user, appointments),
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(height: 24),
              const ClinicalSectionHeader(title: 'Volume de consultations'),
              const SizedBox(height: 12),
              const ClinicalSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClinicalStatusChip(
                          label: 'JOUR',
                          color: AppTheme.neutralGray500,
                          compact: true,
                        ),
                        SizedBox(width: 8),
                        ClinicalStatusChip(
                          label: 'SEMAINE',
                          color: AppTheme.primaryColor,
                          compact: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _DoctorBarChart(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ClinicalSectionHeader(
                title: 'Agenda du jour',
                actionLabel: 'Planning',
                onAction: () => context.go(AppRoutes.doctorAppointments),
              ),
              const SizedBox(height: 12),
              appointmentsAsync.when(
                data: (appointments) {
                  final today = DateTime.now();
                  final todayAppointments = appointments.where((item) {
                    return item.dateTime.year == today.year &&
                        item.dateTime.month == today.month &&
                        item.dateTime.day == today.day;
                  }).toList()
                    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  if (todayAppointments.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: todayAppointments
                        .map((appointment) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DoctorAgendaCard(
                                appointment: appointment,
                              ),
                            ))
                        .toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _doctorHomeContext(
    dynamic user,
    List<Appointment> appointments,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayAppointments = appointments.where((appointment) {
      final day = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      return day == today;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return {
      'user': {
        'name': user?.name,
        'role': user?.role,
        'speciality': user?.speciality,
      },
      'counts': {
        'todayAppointments': todayAppointments.length,
        'pendingAppointments': appointments
            .where((item) => item.status == AppointmentStatus.pending)
            .length,
      },
      'todayQueue': todayAppointments.take(5).map((appointment) {
        return {
          'appointmentId': appointment.id,
          'patientName': appointment.patientName,
          'dateTime': appointment.dateTime.toIso8601String(),
          'status': appointment.status.name,
          'type': appointment.type == AppointmentType.video
              ? 'teleconsultation'
              : 'consultation',
        };
      }).toList(growable: false),
    };
  }
}

class _DoctorMetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _DoctorMetricCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 14),
          Text(
            value,
            style:
                AppTheme.headlineSmall.copyWith(color: AppTheme.neutralGray900),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(color: AppTheme.neutralGray400),
          ),
        ],
      ),
    );
  }
}

class _DoctorQueueCard extends StatelessWidget {
  final Appointment appointment;

  const _DoctorQueueCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final patientName = appointment.patientName ?? 'Patient';

    return ClinicalSurface(
      child: Row(
        children: [
          ClinicalAvatar(name: patientName, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName, style: AppTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Arrivée ${DateFormat('HH:mm').format(appointment.dateTime)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutralGray500,
                  ),
                ),
              ],
            ),
          ),
          ClinicalStatusChip(
            label: _statusLabel(appointment.status).toUpperCase(),
            color: _statusColor(appointment.status),
            compact: true,
          ),
        ],
      ),
    );
  }

  static String _statusLabel(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.confirmed => 'Confirmé',
      AppointmentStatus.pending => 'Urgent',
      AppointmentStatus.cancelled => 'Annulé',
      AppointmentStatus.completed => 'Terminé',
      AppointmentStatus.noShow => 'Absent',
    };
  }

  static Color _statusColor(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.confirmed => AppTheme.successColor,
      AppointmentStatus.pending => AppTheme.errorColor,
      AppointmentStatus.cancelled => AppTheme.errorColor,
      AppointmentStatus.completed => AppTheme.primaryColor,
      AppointmentStatus.noShow => AppTheme.neutralGray500,
    };
  }
}

class _DoctorAgendaCard extends StatelessWidget {
  final Appointment appointment;

  const _DoctorAgendaCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('HH:mm').format(appointment.dateTime);
    final patientName = appointment.patientName ?? 'Patient';

    return ClinicalSurface(
      onTap: () => context.push(
        AppRoutes.doctorAppointmentDetail.replaceFirst(':id', appointment.id),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              dateLabel,
              style: AppTheme.titleSmall.copyWith(
                color: AppTheme.neutralGray600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.type == AppointmentType.video
                      ? 'Téléconsultation'
                      : 'Consultation cabinet',
                  style: AppTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  patientName,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutralGray500,
                  ),
                ),
              ],
            ),
          ),
          if (appointment.type == AppointmentType.video)
            const Icon(
              Icons.videocam_rounded,
              color: AppTheme.primaryColor,
            ),
        ],
      ),
    );
  }
}

class _DoctorBarChart extends StatelessWidget {
  const _DoctorBarChart();

  @override
  Widget build(BuildContext context) {
    const heights = [30.0, 44.0, 70.0, 52.0, 28.0, 60.0, 36.0];
    const labels = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(heights.length, (index) {
        final active = index == 2;

        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: index == heights.length - 1 ? 0 : 8),
            child: Column(
              children: [
                Container(
                  height: heights[index],
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.primaryLight
                        : AppTheme.secondaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[index],
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.neutralGray400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Cloche de notifications avec badge non lus, ouvre la page Notifications.
class _NotificationsBell extends StatelessWidget {
  final WidgetRef ref;
  const _NotificationsBell({required this.ref});

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(notificationsUnreadCountProvider);
    return IconButton(
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: AppTheme.errorColor,
        child: const Icon(Icons.notifications_rounded),
      ),
      onPressed: () => context.push(AppRoutes.notifications),
    );
  }
}

/// Bouton « Salle d'attente » avec compteur live du nombre de patients
/// en attente pour le médecin connecté.
class _WaitingRoomQuickAction extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final waiting = user == null
        ? const []
        : ref.watch(waitingPatientsForDoctorProvider(user.id));
    final count = waiting.length;
    return FilledButton.tonalIcon(
      onPressed: () => context.push(AppRoutes.waitingRoomDoctor),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppTheme.errorColor,
        child: const Icon(Icons.event_seat_outlined),
      ),
      label: const Text('Salle d\'attente'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}
