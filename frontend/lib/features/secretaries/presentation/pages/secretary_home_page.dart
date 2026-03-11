library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/doctor_secretary_delegation_entity.dart';
import '../providers/secretary_providers.dart';
import '../widgets/acting_doctor_banner.dart';

class SecretaryHomePage extends ConsumerWidget {
  const SecretaryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegationsAsync = ref.watch(myDelegationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace secrétaire'),
      ),
      body: Column(
        children: [
          const ActingDoctorBanner(),
          Expanded(
            child: delegationsAsync.when(
              data: (delegations) {
                if (delegations.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune délégation active ou suspendue n’est disponible pour ce compte.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myDelegationsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Text(
                        'Médecins rattachés',
                        style: AppTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...delegations.map(
                        (delegation) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DelegationContextCard(delegation: delegation),
                        ),
                      ),
                    ],
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

class _DelegationContextCard extends ConsumerWidget {
  final DoctorSecretaryDelegationEntity delegation;

  const _DelegationContextCard({required this.delegation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDelegation = ref.watch(secretaryContextProvider).valueOrNull;
    final isCurrent = activeDelegation?.id == delegation.id;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryColor : AppTheme.neutralGray200,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delegation.doctor?.fullName ?? 'Médecin',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delegation.doctor?.email ?? delegation.doctorUserId,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.neutralGray500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Contexte actif'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: delegation.permissions
                .map((permission) => Chip(label: Text(permission)))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: delegation.isActive
                      ? () async {
                          await ref
                              .read(secretaryContextProvider.notifier)
                              .switchDoctor(delegation);

                          if (context.mounted) {
                            context.go(AppRoutes.secretaryAppointments);
                          }
                        }
                      : null,
                  child: Text(isCurrent ? 'Continuer' : 'Agir pour ce médecin'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
