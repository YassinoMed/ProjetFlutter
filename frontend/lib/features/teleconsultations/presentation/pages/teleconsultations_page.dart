import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';

import '../providers/teleconsultation_providers.dart';

class TeleconsultationsPage extends ConsumerWidget {
  const TeleconsultationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teleconsultationsAsync = ref.watch(teleconsultationsProvider);
    final selectedStatus = ref.watch(teleconsultationStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teleconsultations'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String?>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filtrer par statut',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(value: 'scheduled', child: Text('Planifiee')),
                DropdownMenuItem(value: 'ringing', child: Text('En sonnerie')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'completed', child: Text('Terminee')),
                DropdownMenuItem(value: 'cancelled', child: Text('Annulee')),
                DropdownMenuItem(value: 'missed', child: Text('Manquee')),
                DropdownMenuItem(value: 'expired', child: Text('Expiree')),
              ],
              onChanged: (value) {
                ref.read(teleconsultationStatusFilterProvider.notifier).state =
                    value;
              },
            ),
          ),
          Expanded(
            child: teleconsultationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Aucune teleconsultation disponible.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(teleconsultationsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final startLabel = item.scheduledStartsAtUtc == null
                          ? 'Horaire indisponible'
                          : DateFormat('dd/MM/yyyy HH:mm')
                              .format(item.scheduledStartsAtUtc!.toLocal());

                      return Card(
                        child: ListTile(
                          title: Text('Session ${item.callType}'),
                          subtitle: Text('$startLabel\nStatut: ${item.status}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(
                            AppRoutes.teleconsultationDetail
                                .replaceFirst(':id', item.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
