/// Page médecin « Patients en attente ».
///
/// Liste live des sessions `waiting` adressées au médecin connecté, avec
/// 3 actions sur chaque ligne :
///   - **Admettre** : le patient est redirigé automatiquement vers l'appel
///   - **Refuser** : demande un motif (court) puis fixe le status `rejected`
///   - **Reporter** : demande une nouvelle date, puis fixe `rejected` avec
///     `rescheduledTo` non-null (le patient verra « Votre médecin propose
///     un report »).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/waiting_room_session.dart';
import '../providers/waiting_room_providers.dart';

class WaitingRoomDoctorPage extends ConsumerWidget {
  const WaitingRoomDoctorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isDoctor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Salle d\'attente')),
        body: const Center(child: Text('Accès réservé aux médecins.')),
      );
    }
    final patients = ref.watch(waitingPatientsForDoctorProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Patients en attente'),
            const SizedBox(width: 8),
            if (patients.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${patients.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: patients.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                return _PatientCard(session: patients[i]);
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: AppTheme.neutralGray500.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Personne en salle d\'attente',
              style: AppTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Quand un patient rejoindra la salle d\'attente avant un '
              'rendez-vous, il apparaîtra ici en temps réel.',
              style: AppTheme.bodyMedium
                  .copyWith(color: AppTheme.neutralGray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends ConsumerWidget {
  final WaitingRoomSession session;
  const _PatientCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitedFor = DateTime.now().toUtc().difference(session.joinedAt);
    final waitLabel = waitedFor.inMinutes >= 1
        ? '${waitedFor.inMinutes} min ${waitedFor.inSeconds % 60}s'
        : '${waitedFor.inSeconds}s';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.warningColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    _initials(session.patientName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.patientName,
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rejoint il y a $waitLabel · '
                        '${DateFormat('HH:mm').format(session.joinedAt.toLocal())}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.neutralGray500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.warningColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EN ATTENTE',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (session.reason != null && session.reason!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.neutralGray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Motif : ${session.reason}',
                  style: AppTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(waitingRoomStoreProvider.notifier).admit(session.id),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Admettre'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmReschedule(context, ref, session),
                  icon: const Icon(Icons.event_repeat_rounded, size: 18),
                  label: const Text('Reporter'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmReject(context, ref, session),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side:
                        const BorderSide(color: AppTheme.errorColor, width: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    if (name.isEmpty) return '?';
    return name
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p.isEmpty ? '' : p[0])
        .join()
        .toUpperCase();
  }

  Future<void> _confirmReject(
      BuildContext context, WidgetRef ref, WaitingRoomSession s) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motif du refus'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optionnel — affiché au patient',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    ref
        .read(waitingRoomStoreProvider.notifier)
        .reject(s.id, reason: reason.isEmpty ? null : reason);
  }

  Future<void> _confirmReschedule(
      BuildContext context, WidgetRef ref, WaitingRoomSession s) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    final newDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref
        .read(waitingRoomStoreProvider.notifier)
        .reschedule(s.id, to: newDate, reason: 'Proposition de report');
  }
}
