import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PatientHomePage extends ConsumerWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Bonjour, ${user?.name ?? 'Patient'}',
                style: AppTheme.headlineSmall
                    .copyWith(color: AppTheme.neutralWhite),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
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
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prochains rendez-vous', style: AppTheme.titleLarge),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.patientAppointments),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  appointmentsAsync.when(
                    data: (appointments) {
                      if (appointments.isEmpty) {
                        return _buildNoAppointment(context);
                      }
                      final next = appointments
                          .where((a) => a.dateTime.isAfter(DateTime.now()))
                          .toList();
                      if (next.isEmpty) return _buildNoAppointment(context);

                      return Column(
                        children: next
                            .take(2)
                            .map((a) => _buildAppointmentItem(context, a))
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => ErrorDisplay(
                      compact: true,
                      message: err.toString(),
                      onRetry: () => ref.refresh(myAppointmentsProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickAction(
          icon: Icons.search_rounded,
          label: 'Chercher',
          onTap: () => context.push(AppRoutes.doctorSearch),
        ),
        _QuickAction(
          icon: Icons.history_edu_rounded,
          label: 'Dossiers',
          onTap: () => context.push(AppRoutes.patientRecords),
        ),
        _QuickAction(
          icon: Icons.videocam_rounded,
          label: 'Vidéo',
          onTap: () {}, // TODO
        ),
      ],
    );
  }

  Widget _buildNoAppointment(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 48, color: AppTheme.neutralGray300),
            const SizedBox(height: 8),
            const Text('Pas de rendez-vous prévu'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.doctorSearch),
              child: const Text('Prendre rendez-vous'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, dynamic appointment) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
        ),
        title: Text(appointment.doctor?.fullName ?? 'Médecin'),
        subtitle: Text(appointment.dateTime.toString()),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(
            AppRoutes.appointmentDetail.replaceFirst(':id', appointment.id)),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.labelLarge),
        ],
      ),
    );
  }
}
