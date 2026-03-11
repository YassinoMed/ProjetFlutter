import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../secretaries/presentation/providers/secretary_providers.dart';
import '../../../secretaries/presentation/widgets/acting_doctor_banner.dart';
import '../../domain/entities/appointment_entity.dart';
import '../providers/appointment_providers.dart';

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isSecretary = user?.role == AppConstants.roleSecretary;
    final isManagementView =
        user?.role == AppConstants.roleDoctor || isSecretary;
    final secretaryContext = isSecretary
        ? ref.watch(secretaryContextProvider)
        : const AsyncValue.data(null);
    final hasSecretaryContext = !isSecretary || secretaryContext.valueOrNull != null;
    final appointmentsAsync = hasSecretaryContext
        ? ref.watch(myAppointmentsProvider)
        : const AsyncValue.data(<Appointment>[]);

    return Scaffold(
      appBar: AppBar(
        title: Text(isManagementView ? 'Planning médical' : 'Mes Rendez-vous'),
        actions: [
          if (!isManagementView)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push(AppRoutes.doctorSearch),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Passés'),
            Tab(text: 'Tous'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (isSecretary) const ActingDoctorBanner(compact: true),
          // ── Status filter chips ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tous',
                    isSelected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Confirmé',
                    color: const Color(0xFF10B981),
                    isSelected: _statusFilter == 'confirmed',
                    onTap: () => setState(() => _statusFilter = 'confirmed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'En attente',
                    color: const Color(0xFFF59E0B),
                    isSelected: _statusFilter == 'pending',
                    onTap: () => setState(() => _statusFilter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Téléconsult.',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.videocam_rounded,
                    isSelected: _statusFilter == 'video',
                    onTap: () => setState(() => _statusFilter = 'video'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Annulé',
                    color: const Color(0xFFEF4444),
                    isSelected: _statusFilter == 'cancelled',
                    onTap: () => setState(() => _statusFilter = 'cancelled'),
                  ),
                ],
              ),
            ),
          ),

          // ── Appointments list ───────────────────
          Expanded(
            child: isSecretary && !hasSecretaryContext
                ? _buildSecretaryContextEmptyState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList(
                          appointmentsAsync, isManagementView, 'upcoming'),
                      _buildAppointmentsList(
                          appointmentsAsync, isManagementView, 'past'),
                      _buildAppointmentsList(
                          appointmentsAsync, isManagementView, 'all'),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: isManagementView
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.doctorSearch),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau RDV'),
            ),
    );
  }

  Widget _buildAppointmentsList(AsyncValue<List<Appointment>> appointmentsAsync,
      bool isManagementView, String tab) {
    return appointmentsAsync.when(
      data: (appointments) {
        var filtered = appointments.toList();

        // Tab filter
        final now = DateTime.now();
        switch (tab) {
          case 'upcoming':
            filtered = filtered.where((a) => a.dateTime.isAfter(now)).toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
            break;
          case 'past':
            filtered = filtered.where((a) => a.dateTime.isBefore(now)).toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
            break;
          default:
            filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
            break;
        }

        // Status/type filter
        if (_statusFilter != null) {
          if (_statusFilter == 'video') {
            filtered =
                filtered.where((a) => a.type == AppointmentType.video).toList();
          } else {
            filtered = filtered
                .where((a) => a.status.name.toLowerCase() == _statusFilter)
                .toList();
          }
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myAppointmentsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final appointment = filtered[index];
              return _AppointmentCard(
                appointment: appointment,
                isDoctor: isManagementView,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorDisplay(
        message: err.toString(),
        onRetry: () => ref.refresh(myAppointmentsProvider),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: AppTheme.primaryColor,
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
              'Aucun rendez-vous ne correspond aux filtres sélectionnés.',
              textAlign: TextAlign.center,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.neutralGray500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretaryContextEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 48,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('Choisissez un médecin actif', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Le contexte de délégation doit être sélectionné avant d’accéder au planning.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.neutralGray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appointment Card ────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isDoctor;

  const _AppointmentCard({required this.appointment, required this.isDoctor});

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctor;
    final dateStr =
        DateFormat('EEE d MMMM yyyy', 'fr_FR').format(appointment.dateTime);
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);
    final isVideo = appointment.type == AppointmentType.video;
    final isPast = appointment.dateTime.isBefore(DateTime.now());

    final routeDetail = isDoctor
        ? AppRoutes.doctorAppointmentDetail
        : AppRoutes.appointmentDetail;

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
        onTap: () =>
            context.push(routeDetail.replaceFirst(':id', appointment.id)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar / Doctor icon
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: !isDoctor && doctor?.avatarUrl != null
                    ? NetworkImage(doctor!.avatarUrl!)
                    : null,
                child: !isDoctor && doctor?.avatarUrl == null
                    ? const Icon(Icons.person_rounded,
                        color: AppTheme.primaryColor)
                    : isDoctor
                        ? Text(
                            (appointment.patientName ?? 'P')
                                .split(' ')
                                .where((p) => p.isNotEmpty)
                                .take(2)
                                .map((p) => p[0].toUpperCase())
                                .join(),
                            style: AppTheme.titleSmall.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDoctor
                          ? appointment.patientName ?? 'Patient'
                          : doctor?.fullName ?? 'Médecin',
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isDoctor && doctor?.specialty != null)
                      Text(
                        doctor!.specialty!,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.neutralGray500),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined,
                            size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(dateStr,
                              style: AppTheme.labelSmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(timeStr, style: AppTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVideo
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                : const Color(0xFF10B981)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVideo
                                    ? Icons.videocam_rounded
                                    : Icons.place_rounded,
                                size: 12,
                                color: isVideo
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                appointment.type.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isVideo
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: appointment.status),
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
                          label: Text(isDoctor ? 'Démarrer' : 'Rejoindre',
                              style: const TextStyle(fontSize: 11)),
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

// ── Status Badge ────────────────────────────────────────────

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
        break;
      case AppointmentStatus.pending:
        color = const Color(0xFFF59E0B);
        label = 'En attente';
        break;
      case AppointmentStatus.cancelled:
        color = const Color(0xFFEF4444);
        label = 'Annulé';
        break;
      case AppointmentStatus.completed:
        color = const Color(0xFF3B82F6);
        label = 'Terminé';
        break;
      case AppointmentStatus.noShow:
        color = const Color(0xFF6B7280);
        label = 'Absent';
        break;
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

// ── Filter Chip ─────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.color,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14, color: isSelected ? Colors.white : chipColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
