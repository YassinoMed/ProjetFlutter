library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/doctor_secretary_delegation_entity.dart';
import '../providers/secretary_providers.dart';

class DoctorSecretariesPage extends ConsumerWidget {
  const DoctorSecretariesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegationsAsync = ref.watch(doctorSecretariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secrétaires'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Inviter'),
      ),
      body: delegationsAsync.when(
        data: (delegations) {
          if (delegations.isEmpty) {
            return const _EmptySecretariesState();
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(doctorSecretariesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: delegations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final delegation = delegations[index];
                return _DelegationCard(delegation: delegation);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final selectedPermissions = <String>{
      'MANAGE_APPOINTMENTS',
      'MANAGE_SCHEDULE',
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Inviter une secrétaire'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Permissions', style: AppTheme.titleSmall),
                    ),
                    const SizedBox(height: 8),
                    ...allSecretaryPermissions.map(
                      (permission) => CheckboxListTile(
                        value: selectedPermissions.contains(permission),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_permissionLabel(permission)),
                        onChanged: (enabled) {
                          setState(() {
                            if (enabled == true) {
                              selectedPermissions.add(permission);
                            } else {
                              selectedPermissions.remove(permission);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref.read(secretaryActionsProvider).invite(
                          email: emailController.text.trim(),
                          firstName: firstNameController.text.trim(),
                          lastName: lastNameController.text.trim(),
                          permissions: selectedPermissions.toList(),
                        );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invitation envoyée'),
                        ),
                      );
                    }
                  },
                  child: const Text('Inviter'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DelegationCard extends ConsumerWidget {
  final DoctorSecretaryDelegationEntity delegation;

  const _DelegationCard({required this.delegation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (delegation.status) {
      'ACTIVE' => const Color(0xFF0F9D58),
      'SUSPENDED' => const Color(0xFFF4B400),
      'REVOKED' => const Color(0xFFDB4437),
      _ => AppTheme.primaryColor,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.neutralGray200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.support_agent_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(delegation.inviteeDisplayName, style: AppTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      delegation.secretary?.email ?? delegation.invitedEmail,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.neutralGray500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: delegation.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: delegation.permissions
                .map((permission) => Chip(
                      label: Text(_permissionLabel(permission)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPermissionEditor(context, ref, delegation),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Permissions'),
              ),
              const SizedBox(width: 8),
              if (delegation.isSuspended)
                FilledButton.tonal(
                  onPressed: () async {
                    await ref
                        .read(secretaryActionsProvider)
                        .reactivate(delegationId: delegation.id);
                  },
                  child: const Text('Réactiver'),
                )
              else
                FilledButton.tonal(
                  onPressed: () async {
                    await ref.read(secretaryActionsProvider).suspend(
                          delegationId: delegation.id,
                          reason: 'Suspension manuelle',
                        );
                  },
                  child: const Text('Suspendre'),
                ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await ref
                      .read(secretaryActionsProvider)
                      .revoke(delegationId: delegation.id);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Révoquer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionEditor(
    BuildContext context,
    WidgetRef ref,
    DoctorSecretaryDelegationEntity delegation,
  ) async {
    final draft = delegation.permissions.toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Modifier les permissions',
                          style: AppTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    ...allSecretaryPermissions.map(
                      (permission) => CheckboxListTile(
                        value: draft.contains(permission),
                        title: Text(_permissionLabel(permission)),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (enabled) {
                          setState(() {
                            if (enabled == true) {
                              draft.add(permission);
                            } else {
                              draft.remove(permission);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await ref.read(secretaryActionsProvider).updatePermissions(
                                delegationId: delegation.id,
                                permissions: draft.toList(),
                              );

                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptySecretariesState extends StatelessWidget {
  const _EmptySecretariesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 46,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('Aucune secrétaire liée', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Invitez une secrétaire et attribuez-lui uniquement les permissions administratives nécessaires.',
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

String _permissionLabel(String permission) {
  return switch (permission) {
    'MANAGE_APPOINTMENTS' => 'Gérer les rendez-vous',
    'MANAGE_SCHEDULE' => 'Gérer le planning',
    'VIEW_PATIENT_DIRECTORY' => 'Voir les patients',
    'SEND_ADMIN_MESSAGES' => 'Messages administratifs',
    'VIEW_ADMINISTRATIVE_DATA' => 'Données administratives',
    _ => permission,
  };
}
