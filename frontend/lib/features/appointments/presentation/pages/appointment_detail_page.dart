import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/appointment_providers.dart';

class AppointmentDetailPage extends ConsumerStatefulWidget {
  final String appointmentId;

  const AppointmentDetailPage({super.key, required this.appointmentId});

  @override
  ConsumerState<AppointmentDetailPage> createState() =>
      _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends ConsumerState<AppointmentDetailPage> {
  @override
  void initState() {
    super.initState();
    // In a real app we'd fetch the exact appointment detail here.
    // For now, we will rely on the appointments list already loaded,
    // or provide simple access to the video call button.
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsState = ref.watch(myAppointmentsProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;

    // Find the appointment from our local list to avoid extra fetching in this demo
    final appointment = appointmentsState.valueOrNull?.firstWhere(
      (appt) => appt.id == widget.appointmentId,
      // fallback if not found in list (e.g. direct deep link)
      // in production, you should handle this with a detail fetching provider
    );

    final isDoctor = user?.role == 'doctor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du rendez-vous'),
      ),
      body: appointment == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Détails du rendez-vous indisponibles. Assurez-vous d\'avoir chargé vos rendez-vous.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  isDoctor
                                      ? Icons.person
                                      : Icons.medical_services,
                                  color: AppTheme.primaryColor,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isDoctor
                                          ? 'Patient ID: ${appointment.patientId}'
                                          : appointment.doctor?.fullName ??
                                              'Médecin inconnu',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (!isDoctor &&
                                        appointment.doctor?.specialty != null)
                                      Text(
                                        appointment.doctor!.specialty!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: AppTheme.neutralGray500),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildDetailRow(
                            context,
                            icon: Icons.calendar_today,
                            title: 'Date',
                            value: DateFormat('EEEE d MMMM yyyy', 'fr')
                                .format(appointment.dateTime),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            context,
                            icon: Icons.access_time,
                            title: 'Heure',
                            value: DateFormat('HH:mm')
                                .format(appointment.dateTime),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            context,
                            icon: Icons.info_outline,
                            title: 'Statut',
                            value: appointment.status.name,
                            valueColor:
                                _getStatusColor(appointment.status.name),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.videoCall.replaceFirst(
                          ':appointmentId', widget.appointmentId));
                    },
                    icon: const Icon(Icons.video_camera_front),
                    label: const Text('Rejoindre la téléconsultation'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          '$title : ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.bold : null,
                ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
