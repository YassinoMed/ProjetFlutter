import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/appointment_repository_impl.dart';
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
  bool _isMutating = false;

  @override
  Widget build(BuildContext context) {
    final appointmentAsync =
        ref.watch(appointmentDetailProvider(widget.appointmentId));
    final cachedAppointments =
        ref.watch(myAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;

    Appointment? cachedAppointment;
    for (final item in cachedAppointments) {
      if (item.id == widget.appointmentId) {
        cachedAppointment = item;
        break;
      }
    }

    final appointment = appointmentAsync.valueOrNull ?? cachedAppointment;

    final isDoctor = user?.isDoctor == true;
    final isSecretary = user?.isSecretary == true;
    final isCareTeam = isDoctor || isSecretary;
    final isVideo = appointment?.type == AppointmentType.video;
    final isPast =
        appointment != null && appointment.dateTime.isBefore(DateTime.now());
    final canUseVideoCall = !isSecretary &&
        appointment?.status == AppointmentStatus.confirmed &&
        !isPast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du rendez-vous'),
      ),
      body: appointmentAsync.isLoading && appointment == null
          ? const Center(child: CircularProgressIndicator())
          : appointment == null
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
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
                                    backgroundImage: !isCareTeam &&
                                            appointment.doctor?.avatarUrl !=
                                                null
                                        ? NetworkImage(
                                            appointment.doctor!.avatarUrl!)
                                        : null,
                                    child: Icon(
                                      isCareTeam
                                          ? Icons.person
                                          : Icons.medical_services_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCareTeam
                                              ? appointment.patientName ??
                                                  'Patient'
                                              : appointment.doctor?.fullName ??
                                                  appointment.doctorName ??
                                                  'Médecin',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (!isCareTeam &&
                                            appointment.doctor?.specialty !=
                                                null)
                                          Text(
                                            appointment.doctor!.specialty!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color: AppTheme
                                                        .neutralGray500),
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

                      if (_canConfirm(appointment, isCareTeam))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: _isMutating
                                ? null
                                : () => _confirmAppointment(),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(
                              _isMutating
                                  ? 'Confirmation…'
                                  : 'Accepter le rendez-vous',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                      if (_canReject(appointment, isCareTeam))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OutlinedButton.icon(
                            onPressed:
                                _isMutating ? null : () => _rejectAppointment(),
                            icon: const Icon(Icons.block_rounded),
                            label: Text(
                              _isMutating ? 'Refus…' : 'Refuser le rendez-vous',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: AppTheme.errorColor,
                              side:
                                  const BorderSide(color: AppTheme.errorColor),
                            ),
                          ),
                        ),

                      if (_canCancel(appointment, user))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OutlinedButton.icon(
                            onPressed:
                                _isMutating ? null : () => _cancelAppointment(),
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(
                              _isMutating
                                  ? 'Annulation…'
                                  : user?.isPatient == true
                                      ? 'Annuler ma demande'
                                      : 'Annuler le rendez-vous',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: AppTheme.errorColor,
                              side:
                                  const BorderSide(color: AppTheme.errorColor),
                            ),
                          ),
                        ),

                      // ── Video Call Button (teleconsultation) ─
                      if (isVideo && canUseVideoCall)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.3),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
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
                      if (!isVideo && canUseVideoCall)
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

  bool _canConfirm(Appointment appointment, bool isDoctor) {
    return isDoctor && appointment.status == AppointmentStatus.pending;
  }

  bool _canReject(Appointment appointment, bool isCareTeam) {
    return isCareTeam && appointment.status == AppointmentStatus.pending;
  }

  bool _canCancel(Appointment appointment, User? user) {
    if (user?.isPatient == true) {
      return appointment.status == AppointmentStatus.pending;
    }

    if (user?.isDoctor == true || user?.isSecretary == true) {
      return appointment.status == AppointmentStatus.confirmed;
    }

    return false;
  }

  Future<void> _confirmAppointment() async {
    setState(() => _isMutating = true);

    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.confirmAppointment(widget.appointmentId);
      ref.invalidate(myAppointmentsProvider);
      ref.invalidate(appointmentDetailProvider(widget.appointmentId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous confirmé')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Confirmation impossible: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _rejectAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser ce rendez-vous ?'),
        content: const Text(
          'Le patient verra cette demande comme non confirmée et pourra choisir un autre créneau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isMutating = true);

    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.rejectAppointment(widget.appointmentId);
      ref.invalidate(myAppointmentsProvider);
      ref.invalidate(appointmentDetailProvider(widget.appointmentId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous refusé')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refus impossible: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler ce rendez-vous ?'),
        content: const Text(
          'Le patient et le médecin verront ce rendez-vous comme annulé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Annuler le RDV'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isMutating = true);

    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.cancelAppointment(widget.appointmentId);
      ref.invalidate(myAppointmentsProvider);
      ref.invalidate(appointmentDetailProvider(widget.appointmentId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous annulé')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Annulation impossible: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
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
