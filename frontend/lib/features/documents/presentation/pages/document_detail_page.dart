library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/document_entity.dart';
import '../providers/document_providers.dart';

class DocumentDetailPage extends ConsumerWidget {
  final String documentId;

  const DocumentDetailPage({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail document'),
      ),
      body: documentAsync.when(
        data: (document) => _DocumentDetailContent(document: document),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.refresh(documentDetailProvider(documentId)),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () async {
            await ref.read(documentActionsProvider).reanalyze(documentId);
            ref.invalidate(documentDetailProvider(documentId));
          },
          icon: const Icon(Icons.auto_fix_high_rounded),
          label: const Text('Réanalyser'),
        ),
      ),
    );
  }
}

class _DocumentDetailContent extends StatelessWidget {
  final MedicalDocument document;

  const _DocumentDetailContent({required this.document});

  @override
  Widget build(BuildContext context) {
    final date = document.documentDateUtc ?? document.processedAtUtc;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(document.title, style: AppTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: document.processingStatus),
                  if (document.documentType != null)
                    _InfoChip(label: document.documentType!),
                  if (document.urgencyLevel != null)
                    _InfoChip(label: 'Urgence ${document.urgencyLevel}'),
                ],
              ),
              if (date != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Date document: ${DateFormat('dd/MM/yyyy').format(date.toLocal())}',
                  style: AppTheme.bodyMedium,
                ),
              ],
              if (document.lastErrorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Erreur: ${document.lastErrorMessage}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Résumés',
          child: document.summaries.isEmpty
              ? const Text('Aucun résumé disponible pour le moment.')
              : Column(
                  children: document.summaries
                      .map((summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SummaryTile(summary: summary),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Entités extraites',
          child: document.entities.isEmpty
              ? const Text('Aucune entité structurée disponible.')
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: document.entities
                      .map((entity) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.neutralGray100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(entity.label, style: AppTheme.labelSmall),
                                const SizedBox(height: 4),
                                Text(entity.value, style: AppTheme.bodySmall),
                              ],
                            ),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Texte extrait',
          child: Text(
            document.latestExtraction?.rawText?.isNotEmpty == true
                ? document.latestExtraction!.rawText!
                : 'Aucun texte extrait disponible.',
            style: AppTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final DocumentSummaryItem summary;

  const _SummaryTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${summary.audience} · ${summary.format}',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              if (summary.confidenceScore != null)
                Text(
                  '${summary.confidenceScore!.toStringAsFixed(0)}%',
                  style: AppTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary.summaryText, style: AppTheme.bodyMedium),
          if ((summary.missingFields ?? const []).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Champs manquants: ${(summary.missingFields ?? const []).join(', ')}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.warningColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTheme.labelSmall),
    );
  }
}
