import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/appointment_entity.dart';
import '../providers/appointment_providers.dart';

class AppointmentsPage extends ConsumerWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppRoutes.doctorSearch),
          ),
        ],
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myAppointmentsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _AppointmentCard(appointment: appointment);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.refresh(myAppointmentsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.doctorSearch),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.appointmentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 64,
              color: AppTheme.appointmentColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun rendez-vous',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Vous n\'avez pas encore de rendez-vous programmé.',
              textAlign: TextAlign.center,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.neutralGray500),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.doctorSearch),
            child: const Text('Prendre un rendez-vous'),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctor;
    final dateStr =
        DateFormat('dd MMMM yyyy', 'fr_FR').format(appointment.dateTime);
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push(
            AppRoutes.appointmentDetail.replaceFirst(':id', appointment.id)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: doctor?.avatarUrl != null
                    ? NetworkImage(doctor!.avatarUrl!)
                    : null,
                child: doctor?.avatarUrl == null
                    ? const Icon(Icons.person_rounded)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor?.fullName ?? 'Médecin',
                      style: AppTheme.titleMedium,
                    ),
                    Text(
                      doctor?.specialty ?? 'Généraliste',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.neutralGray500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(dateStr, style: AppTheme.bodySmall),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_rounded,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(timeStr, style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: appointment.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case AppointmentStatus.confirmed:
        color = Colors.green;
        label = 'Confirmé';
      case AppointmentStatus.pending:
        color = Colors.orange;
        label = 'En attente';
      case AppointmentStatus.cancelled:
        color = Colors.red;
        label = 'Annulé';
      case AppointmentStatus.completed:
        color = Colors.blue;
        label = 'Terminé';
      case AppointmentStatus.noShow:
        color = Colors.grey;
        label = 'Absent';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
