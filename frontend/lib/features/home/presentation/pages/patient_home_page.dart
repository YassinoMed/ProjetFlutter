library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
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
    final doctorsAsync = ref.watch(doctorSearchProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myAppointmentsProvider);
            ref.invalidate(doctorSearchProvider);
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
                          'Bonjour, ${user?.name.split(' ').first ?? 'Patient'}',
                          style: AppTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Votre santé, notre priorité.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.neutralGray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClinicalAvatar(
                    name: user?.name ?? 'Patient',
                    imageUrl: user?.avatarUrl,
                    radius: 24,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              appointmentsAsync.when(
                data: (appointments) {
                  final upcoming = appointments
                      .where((item) => item.dateTime.isAfter(DateTime.now()))
                      .toList()
                    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  if (upcoming.isEmpty) {
                    return const ClinicalEmptyState(
                      icon: Icons.calendar_today_rounded,
                      title: 'Aucun rendez-vous à venir',
                      message:
                          'Vous pourrez retrouver ici vos prochaines consultations et téléconsultations.',
                    );
                  }

                  return _PatientHeroCard(appointment: upcoming.first);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => ErrorDisplay(
                  compact: true,
                  message: err.toString(),
                  onRetry: () => ref.invalidate(myAppointmentsProvider),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.search_rounded,
                      title: 'Trouver\nun médecin',
                      color: AppTheme.primaryColor,
                      onTap: () => context.push(AppRoutes.doctorSearch),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.folder_open_rounded,
                      title: 'Journal\npatient',
                      color: AppTheme.successColor,
                      onTap: () => context.push(AppRoutes.patientRecords),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Messages\nsécurisés',
                      color: AppTheme.chatColor,
                      onTap: () => context.go(AppRoutes.patientChat),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const ClinicalSectionHeader(title: 'Activité consultations'),
              const SizedBox(height: 12),
              ClinicalSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activité mensuelle',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.neutralGray500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _BarChartPlaceholder(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ClinicalSectionHeader(
                title: 'Médecins recommandés',
                actionLabel: 'Voir tout',
                onAction: () => context.push(AppRoutes.doctorSearch),
              ),
              const SizedBox(height: 12),
              doctorsAsync.when(
                data: (doctors) {
                  if (doctors.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    height: 198,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: doctors.length.clamp(0, 6),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return _RecommendedDoctorCard(
                          doctorName: doctor.fullName,
                          specialty: doctor.specialty ?? 'Médecine générale',
                          rating: doctor.rating,
                          avatarUrl: doctor.avatarUrl,
                          onTap: () => context.push(
                            AppRoutes.doctorDetail
                                .replaceFirst(':id', doctor.userId),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              const ClinicalSectionHeader(title: 'Historique récent'),
              const SizedBox(height: 12),
              appointmentsAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final recent = [...appointments]
                    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

                  return Column(
                    children: recent
                        .take(3)
                        .map((appointment) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PatientAppointmentCard(
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
}

class _PatientHeroCard extends StatelessWidget {
  final Appointment appointment;

  const _PatientHeroCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctor;
    final whenLabel =
        DateFormat('EEEE d MMMM • HH:mm', 'fr_FR').format(appointment.dateTime);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowPrimary,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ClinicalStatusChip(
              label: 'E2E CHIFFRÉ',
              color: Colors.white,
              icon: Icons.lock_rounded,
              compact: true,
            ),
            const SizedBox(height: 14),
            Text(
              'Prochain rendez-vous',
              style: AppTheme.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              doctor?.fullName ?? 'Médecin',
              style: AppTheme.headlineSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '${doctor?.specialty ?? 'Consultation'} • ${toBeginningOfSentenceCase(whenLabel)}',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.patientAppointments),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                    ),
                    child: const Text('Consulter'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      AppRoutes.appointmentDetail
                          .replaceFirst(':id', appointment.id),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text('Détails'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClinicalSurface(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.neutralGray700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedDoctorCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final double rating;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _RecommendedDoctorCard({
    required this.doctorName,
    required this.specialty,
    required this.rating,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: ClinicalSurface(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClinicalAvatar(
              name: doctorName,
              imageUrl: avatarUrl,
              radius: 28,
            ),
            const SizedBox(height: 12),
            Text(doctorName, style: AppTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              specialty,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (rating > 0)
              ClinicalStatusChip(
                label: rating.toStringAsFixed(1),
                color: AppTheme.successColor,
                icon: Icons.star_rounded,
                compact: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _PatientAppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _PatientAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctor;
    final dateLabel =
        DateFormat('dd MMM • HH:mm', 'fr_FR').format(appointment.dateTime);

    return ClinicalSurface(
      onTap: () => context.push(
        AppRoutes.appointmentDetail.replaceFirst(':id', appointment.id),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text(
                DateFormat('dd').format(appointment.dateTime),
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor?.fullName ?? 'Médecin', style: AppTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  doctor?.specialty ?? 'Consultation',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutralGray500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.neutralGray400,
                  ),
                ),
              ],
            ),
          ),
          ClinicalStatusChip(
            label:
                appointment.type == AppointmentType.video ? 'VIDÉO' : 'CABINET',
            color: appointment.type == AppointmentType.video
                ? AppTheme.primaryColor
                : AppTheme.successColor,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _BarChartPlaceholder extends StatelessWidget {
  const _BarChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    const heights = [36.0, 58.0, 44.0, 70.0, 40.0, 62.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(heights.length, (index) {
        final active = index == 3;

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
                        : AppTheme.secondaryLight.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM'][index],
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
