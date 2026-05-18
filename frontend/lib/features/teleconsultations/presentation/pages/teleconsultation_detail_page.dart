import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mediconnect_pro/features/consultation_reports/presentation/providers/consultation_report_providers.dart';
import 'package:mediconnect_pro/features/waiting_room/presentation/providers/waiting_room_providers.dart';

import '../providers/teleconsultation_providers.dart';

class TeleconsultationDetailPage extends ConsumerWidget {
  final String teleconsultationId;

  const TeleconsultationDetailPage({
    super.key,
    required this.teleconsultationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teleconsultationAsync =
        ref.watch(teleconsultationDetailProvider(teleconsultationId));
    final eventsAsync =
        ref.watch(teleconsultationEventsProvider(teleconsultationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail teleconsultation'),
      ),
      body: teleconsultationAsync.when(
        data: (teleconsultation) {
          final startLabel = teleconsultation.scheduledStartsAtUtc == null
              ? 'Non renseigne'
              : DateFormat('dd/MM/yyyy HH:mm')
                  .format(teleconsultation.scheduledStartsAtUtc!.toLocal());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statut: ${teleconsultation.status}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Type: ${teleconsultation.callType}'),
                      Text('Debut prevu: $startLabel'),
                      Text('Appointment: ${teleconsultation.appointmentId}'),
                      if (teleconsultation.currentCallSessionId != null)
                        Text(
                            'Call session: ${teleconsultation.currentCallSessionId}'),
                      if (teleconsultation.failureReason != null)
                        Text('Erreur: ${teleconsultation.failureReason}'),
                      if (teleconsultation.cancellationReason != null)
                        Text(
                            'Annulation: ${teleconsultation.cancellationReason}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Si l'utilisateur est le patient, on lui propose de rejoindre
              // d'abord la salle d'attente (le médecin doit l'admettre avant
              // que l'appel ne démarre). Sinon (médecin), accès direct à
              // l'appel.
              _PatientOrDoctorEntryButton(
                teleconsultation: teleconsultation,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: teleconsultation.status == 'completed' ||
                        teleconsultation.status == 'cancelled'
                    ? null
                    : () async {
                        await ref
                            .read(teleconsultationActionsProvider)
                            .cancel(teleconsultation.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teleconsultation annulee.'),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Annuler'),
              ),
              // Compte rendu post-consultation : visible uniquement pour
              // le médecin et seulement quand la téléconsultation est
              // terminée (statut ended/completed). Label/route adaptés
              // selon que le compte rendu existe déjà ou non.
              if (_canCreateReport(ref, teleconsultation)) ...[
                const SizedBox(height: 12),
                _ConsultationReportAction(
                  teleconsultationId: teleconsultation.id,
                  patientId: teleconsultation.patientUserId,
                  patientName: 'Patient ${teleconsultation.patientUserId}',
                  consultationAt: teleconsultation.endedAtUtc ??
                      teleconsultation.startedAtUtc,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Historique',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aucun evenement enregistre.'),
                      ),
                    );
                  }

                  return Column(
                    children: events
                        .map(
                          (event) => Card(
                            child: ListTile(
                              title: Text(event.eventName),
                              subtitle: Text(
                                event.occurredAtUtc == null
                                    ? 'Horodatage indisponible'
                                    : DateFormat('dd/MM/yyyy HH:mm:ss').format(
                                        event.occurredAtUtc!.toLocal(),
                                      ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(error.toString()),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  bool _canCreateReport(WidgetRef ref, dynamic teleconsultation) {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    if (user.id != teleconsultation.doctorUserId) return false;
    final s = teleconsultation.status?.toString().toLowerCase() ?? '';
    return s == 'ended' || s == 'completed';
  }
}

/// Bouton d'entrée dans l'appel adapté au rôle :
///   - Médecin : "Ouvrir l'appel" (accès direct)
///   - Patient : "Rejoindre la salle d'attente" → flux d'admission
class _PatientOrDoctorEntryButton extends ConsumerWidget {
  final dynamic teleconsultation;
  const _PatientOrDoctorEntryButton({required this.teleconsultation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDoctor =
        user != null && user.id == teleconsultation.doctorUserId;

    if (isDoctor) {
      return FilledButton.icon(
        onPressed: () => context.push(
          AppRoutes.videoCall.replaceFirst(
            ':appointmentId',
            teleconsultation.appointmentId,
          ),
        ),
        icon: const Icon(Icons.video_camera_front_rounded),
        label: const Text('Ouvrir l\'appel'),
      );
    }

    // Patient → flux salle d'attente
    return FilledButton.icon(
      onPressed: () {
        if (user == null) return;
        final session =
            ref.read(waitingRoomStoreProvider.notifier).join(
                  appointmentId: teleconsultation.appointmentId,
                  teleconsultationId: teleconsultation.id,
                  patientId: user.id,
                  patientName: user.name,
                  patientAvatarUrl: user.avatarUrl,
                  doctorId: teleconsultation.doctorUserId,
                  doctorName: 'Médecin', // backend pourra enrichir
                );
        context.push(
          AppRoutes.waitingRoomPatient
              .replaceFirst(':sessionId', session.id),
        );
      },
      icon: const Icon(Icons.event_seat_outlined),
      label: const Text('Rejoindre la salle d\'attente'),
    );
  }
}

class _ConsultationReportAction extends ConsumerWidget {
  final String teleconsultationId;
  final String patientId;
  final String patientName;
  final DateTime? consultationAt;

  const _ConsultationReportAction({
    required this.teleconsultationId,
    required this.patientId,
    required this.patientName,
    this.consultationAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(
      consultationReportByTeleconsultationProvider(teleconsultationId),
    );
    final hasReport = existing != null;

    return FilledButton.tonalIcon(
      onPressed: () {
        if (hasReport) {
          context.push(
            AppRoutes.consultationReportDetail
                .replaceFirst(':id', existing.id),
          );
        } else {
          context.push(
            AppRoutes.consultationReportCreate,
            extra: {
              'teleconsultationId': teleconsultationId,
              'patientId': patientId,
              'patientName': patientName,
              'consultationAt': consultationAt,
            },
          );
        }
      },
      icon: Icon(
        hasReport
            ? Icons.assignment_turned_in_outlined
            : Icons.assignment_add,
      ),
      label: Text(hasReport ? 'Voir le compte rendu' : 'Créer un compte rendu'),
    );
  }
}
