library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mediconnect_pro/core/rgpd/rgpd_service.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/shared/widgets/clinical_ui.dart';

class GdprSettingsPage extends ConsumerStatefulWidget {
  const GdprSettingsPage({super.key});

  @override
  ConsumerState<GdprSettingsPage> createState() => _GdprSettingsPageState();
}

class _GdprSettingsPageState extends ConsumerState<GdprSettingsPage> {
  final Map<String, bool> _consents = {
    for (var consent in ConsentType.all) consent: true,
  };

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Confidentialité',
                          style: AppTheme.headlineSmall,
                        ),
                      ),
                      Switch.adaptive(
                        value: _consents[ConsentType.analytics] ?? true,
                        onChanged: (value) =>
                            _updateConsent(ConsentType.analytics, value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Votre santé est privée. MediConnect Pro s’engage à protéger vos données avec un niveau de sécurité clinique.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.neutralGray500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...ConsentType.all.map((type) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClinicalSurface(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ConsentType.label(type),
                                      style: AppTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ConsentType.description(type),
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.neutralGray500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Switch.adaptive(
                                value: _consents[type] ?? true,
                                onChanged: (value) =>
                                    _updateConsent(type, value),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  ClinicalSurface(
                    color: AppTheme.primarySurface,
                    elevated: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chiffrement E2E', style: AppTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Obligatoire pour l’utilisation. Vos messages et documents sensibles ne sont jamais exposés en clair.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.neutralGray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const ClinicalSectionHeader(title: 'Vos droits'),
                  const SizedBox(height: 12),
                  ClinicalSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () => _exportData(context),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text('Exporter mes données',
                              style: AppTheme.titleSmall),
                          subtitle: Text(
                            'Télécharger une copie structurée de vos données.',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.neutralGray500,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          onTap: () => _showDeleteConfirmDialog(context),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.softColor(AppTheme.errorColor),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          title: Text(
                            'Droit à l’oubli',
                            style: AppTheme.titleSmall.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                          subtitle: Text(
                            'Supprimer définitivement votre compte et vos données.',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.neutralGray500,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _updateConsent(String type, bool consented) async {
    final previous = _consents[type]!;
    setState(() => _consents[type] = consented);

    final service = ref.read(rgpdServiceProvider);
    final result =
        await service.updateConsent(consentType: type, consented: consented);

    result.fold(
      (failure) {
        setState(() => _consents[type] = previous);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${failure.message}')),
        );
      },
      (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférence mise à jour'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _isLoading = true);
    final service = ref.read(rgpdServiceProvider);
    final result = await service.exportData();
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${failure.message}')),
        );
      },
      (_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export terminé'),
            content: const Text(
              'Vos données ont été préparées avec succès.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer votre compte ?',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.errorColor),
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données personnelles, dossiers et conversations seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _requestDeletion(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDeletion(BuildContext context) async {
    setState(() => _isLoading = true);
    final service = ref.read(rgpdServiceProvider);
    final result = await service.requestDeletion();
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${failure.message}')),
        );
      },
      (_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Demande prise en compte'),
            content: const Text(
              'Votre demande de suppression a été enregistrée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }
}
