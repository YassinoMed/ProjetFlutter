import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';

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
              FilledButton.icon(
                onPressed: () => context.push(
                  AppRoutes.videoCall.replaceFirst(
                    ':appointmentId',
                    teleconsultation.appointmentId,
                  ),
                ),
                icon: const Icon(Icons.video_camera_front_rounded),
                label: const Text('Ouvrir l appel'),
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
}
