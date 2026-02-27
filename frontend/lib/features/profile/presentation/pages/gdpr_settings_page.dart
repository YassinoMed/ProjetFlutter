import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/core/rgpd/rgpd_service.dart';

class GdprSettingsPage extends ConsumerStatefulWidget {
  const GdprSettingsPage({super.key});

  @override
  ConsumerState<GdprSettingsPage> createState() => _GdprSettingsPageState();
}

class _GdprSettingsPageState extends ConsumerState<GdprSettingsPage> {
  // In a real app we'd fetch the initial state of these from the backend
  // For now we'll mock the initial state to true for all
  final Map<String, bool> _consents = {
    for (var c in ConsentType.all) c: true,
  };
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidentialité & RGPD'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Vos Consentements'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: ConsentType.all.map((type) {
                      return SwitchListTile(
                        title: Text(ConsentType.label(type)),
                        subtitle: Text(
                          ConsentType.description(type),
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.neutralGray500),
                        ),
                        value: _consents[type] ?? true,
                        activeThumbColor: AppTheme.primaryColor,
                        onChanged: (val) => _updateConsent(type, val),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Vos Droits'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download_rounded,
                            color: Colors.blue),
                        title: const Text('Exporter mes données'),
                        subtitle: const Text(
                            'Télécharger une copie de toutes vos données'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _exportData(context),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded,
                            color: Colors.red),
                        title: const Text('Droit à l\'oubli',
                            style: TextStyle(color: Colors.red)),
                        subtitle: const Text(
                            'Supprimer définitivement votre compte et vos données'),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Colors.red),
                        onTap: () => _showDeleteConfirmDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Conformément au Règlement Général sur la Protection des Données (RGPD), '
                  'vous disposez de droits concernant vos informations personnelles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: AppTheme.titleMedium.copyWith(color: AppTheme.primaryColor),
      ),
    );
  }

  Future<void> _updateConsent(String type, bool consented) async {
    final prev = _consents[type]!;
    setState(() => _consents[type] = consented);

    final service = ref.read(rgpdServiceProvider);
    final result =
        await service.updateConsent(consentType: type, consented: consented);

    result.fold(
      (failure) {
        setState(() => _consents[type] = prev); // Revert on failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${failure.message}')),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Préférence mise à jour'),
              duration: Duration(seconds: 1),
            ),
          );
        }
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${failure.message}')),
          );
        }
      },
      (data) {
        if (context.mounted) {
          _showDataExportedDialog(context, data);
        }
      },
    );
  }

  void _showDataExportedDialog(
      BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export terminé'),
        content: const Text(
          'Vos données ont été exportées avec succès. '
          'Dans une application réelle, cela téléchargera un fichier JSON structuré, ou un fichier ZIP chiffré.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer votre compte ?',
            style: TextStyle(color: Colors.red)),
        content: const Text(
          'Cette action est irréversible. Toutes vos données personnelles, '
          'dossiers médicaux et conversations seront définitivement supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _requestDeletion(context);
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${failure.message}')),
          );
        }
      },
      (_) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Au revoir'),
              content: const Text('Vos données ont été supprimées.'),
              actions: [
                TextButton(
                  onPressed: () {
                    // TODO: Logout and navigate to login
                  },
                  child: const Text('Fermer'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
