import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/appointment_entity.dart';
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
  Widget build(BuildContext context) {
    final appointmentsState = ref.watch(myAppointmentsProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;

    final appointment = appointmentsState.valueOrNull?.firstWhere(
      (appt) => appt.id == widget.appointmentId,
    );

    final isDoctor = user?.role == 'doctor';
    final isVideo = appointment?.type == AppointmentType.video;
    final isPast =
        appointment != null && appointment.dateTime.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du rendez-vous'),
      ),
      body: appointment == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.neutralGray100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.search_off_rounded,
                        size: 40, color: AppTheme.neutralGray400),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rendez-vous introuvable',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Assurez-vous d\'avoir chargé vos rendez-vous.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.neutralGray500),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Retour'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Main Info Card ────────────────────
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor / Patient Avatar
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                backgroundImage: !isDoctor &&
                                        appointment.doctor?.avatarUrl != null
                                    ? NetworkImage(
                                        appointment.doctor!.avatarUrl!)
                                    : null,
                                child: Icon(
                                  isDoctor
                                      ? Icons.person
                                      : Icons.medical_services_rounded,
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
                                          ? appointment.patientName ?? 'Patient'
                                          : appointment.doctor?.fullName ??
                                              'Médecin',
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
                              _StatusBadge(status: appointment.status),
                            ],
                          ),
                          const Divider(height: 32),

                          // Date
                          _buildDetailRow(
                            context,
                            icon: Icons.calendar_today_rounded,
                            title: 'Date',
                            value: DateFormat('EEEE d MMMM yyyy', 'fr')
                                .format(appointment.dateTime),
                          ),
                          const SizedBox(height: 16),

                          // Time
                          _buildDetailRow(
                            context,
                            icon: Icons.access_time_rounded,
                            title: 'Heure',
                            value: DateFormat('HH:mm')
                                .format(appointment.dateTime),
                          ),
                          const SizedBox(height: 16),

                          // Duration
                          _buildDetailRow(
                            context,
                            icon: Icons.timer_outlined,
                            title: 'Durée',
                            value: '${appointment.durationMinutes} minutes',
                          ),
                          const SizedBox(height: 16),

                          // Type
                          _buildDetailRow(
                            context,
                            icon: isVideo
                                ? Icons.videocam_rounded
                                : Icons.place_rounded,
                            title: 'Type',
                            value: appointment.type.label,
                            valueColor: isVideo
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 16),

                          // Status
                          _buildDetailRow(
                            context,
                            icon: Icons.info_outline_rounded,
                            title: 'Statut',
                            value: _statusLabel(appointment.status),
                            valueColor:
                                _getStatusColor(appointment.status.name),
                          ),

                          // Notes
                          if (appointment.notes != null &&
                              appointment.notes!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              context,
                              icon: Icons.notes_rounded,
                              title: 'Notes',
                              value: appointment.notes!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Video Call Button (teleconsultation) ─
                  if (isVideo && !isPast)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            context.push(AppRoutes.videoCall.replaceFirst(
                                ':appointmentId', widget.appointmentId));
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.video_camera_front_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isDoctor
                                      ? 'Démarrer la téléconsultation'
                                      : 'Rejoindre la téléconsultation',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Regular video call button for presential ─
                  if (!isVideo && !isPast)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.videoCall.replaceFirst(
                            ':appointmentId', widget.appointmentId));
                      },
                      icon: const Icon(Icons.video_camera_front),
                      label: const Text('Démarrer une consultation vidéo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 32),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (valueColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, size: 18, color: valueColor ?? AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.labelSmall
                    .copyWith(color: AppTheme.neutralGray500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                      fontWeight: valueColor != null ? FontWeight.w600 : null,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.confirmed => 'Confirmé',
      AppointmentStatus.pending => 'En attente',
      AppointmentStatus.cancelled => 'Annulé',
      AppointmentStatus.completed => 'Terminé',
      AppointmentStatus.noShow => 'Absent',
    };
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
