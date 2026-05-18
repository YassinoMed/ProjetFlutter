import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../domain/entities/export_data_model.dart';
import '../providers/gdpr_export_providers.dart';

class GdprExportPage extends ConsumerWidget {
  const GdprExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(gdprExportControllerProvider);
    final history = ref.watch(gdprExportHistoryProvider);
    final export = exportState.valueOrNull;

    ref.listen(gdprExportControllerProvider, (previous, next) {
      final value = next.valueOrNull;
      if (value == null) return;

      final historyNotifier = ref.read(gdprExportHistoryProvider.notifier);
      final alreadyTracked = historyNotifier.state.any(
        (item) => item.exportedAt == value.exportedAt,
      );
      if (!alreadyTracked) {
        historyNotifier.state = [value, ...historyNotifier.state];
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Export RGPD')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClinicalSurface(
            color: AppTheme.primarySurface,
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portabilité des données', style: AppTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Générez une copie structurée de vos données personnelles disponibles dans MediConnect Pro.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: exportState.isLoading
                ? null
                : () =>
                    ref.read(gdprExportControllerProvider.notifier).runExport(),
            icon: exportState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              exportState.isLoading ? 'Préparation...' : 'Exporter mes données',
            ),
          ),
          if (exportState.hasError) ...[
            const SizedBox(height: 12),
            ClinicalSurface(
              color: AppTheme.softColor(AppTheme.errorColor, 0.12),
              elevated: false,
              child: Text(
                exportState.error.toString(),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ],
          if (export != null) ...[
            const SizedBox(height: 16),
            _ExportSummary(export: export),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(
                      export.data,
                    ),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export JSON copié.')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copier JSON'),
            ),
          ],
          const SizedBox(height: 24),
          const ClinicalSectionHeader(title: 'Historique local'),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const ClinicalEmptyState(
              icon: Icons.history_rounded,
              title: 'Aucun export dans cette session',
              message:
                  'Les exports sont journalisés côté serveur et listés localement ici pendant la session.',
            )
          else
            ...history.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClinicalSurface(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(item.exportedAt.toLocal()),
                      ),
                      subtitle: Text(item.patientEmail ?? 'Export utilisateur'),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _ExportSummary extends StatelessWidget {
  final ExportDataModel export;

  const _ExportSummary({required this.export});

  @override
  Widget build(BuildContext context) {
    final exportedAt =
        DateFormat('dd/MM/yyyy HH:mm').format(export.exportedAt.toLocal());

    return ClinicalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export prêt', style: AppTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Préparé le $exportedAt'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountChip(label: 'RDV', value: export.count('appointments')),
              _CountChip(
                label: 'Messages',
                value: export.count('chat_messages'),
              ),
              _CountChip(label: 'Documents', value: export.count('documents')),
              _CountChip(
                label: 'Consentements',
                value: export.count('consents'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;

  const _CountChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalStatusChip(
      label: '$label: $value',
      color: AppTheme.primaryColor,
      compact: true,
    );
  }
}
