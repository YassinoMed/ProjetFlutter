import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../documents/domain/entities/document_entity.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../providers/document_analysis_providers.dart';

class DocumentAnalysisPage extends ConsumerWidget {
  final String documentId;

  const DocumentAnalysisPage({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Analyse IA du document')),
      body: documentAsync.when(
        data: (document) {
          final analysis = ref
              .watch(aiDocumentAnalysisServiceProvider)
              .fromDocument(document);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ClinicalSurface(
                color: AppTheme.primarySurface,
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.title, style: AppTheme.titleLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ClinicalStatusChip(
                          label: analysis.detectedType.toUpperCase(),
                          color: AppTheme.primaryColor,
                          compact: true,
                        ),
                        if (analysis.confidenceScore != null)
                          ClinicalStatusChip(
                            label:
                                '${(analysis.confidenceScore! * 100).toStringAsFixed(0)}% confiance',
                            color: AppTheme.successColor,
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ClinicalSurface(
                color: AppTheme.softColor(AppTheme.warningColor, 0.12),
                elevated: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.warningColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        analysis.disclaimer,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutralGray700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SummarySection(
                title: 'Résumé patient',
                summaries: analysis.patientSummaries,
              ),
              const SizedBox(height: 16),
              _SummarySection(
                title: 'Résumé médecin',
                summaries: analysis.doctorSummaries,
              ),
              const SizedBox(height: 16),
              _VerificationSection(points: analysis.pointsToVerify),
              const SizedBox(height: 16),
              _EntitySection(entities: analysis.importantEntities),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: document.isProcessing
                    ? null
                    : () async {
                        await ref
                            .read(documentActionsProvider)
                            .reanalyze(documentId);
                        ref.invalidate(documentDetailProvider(documentId));
                      },
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: Text(
                  document.isProcessing
                      ? 'Analyse en cours'
                      : 'Analyser avec IA',
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final List<DocumentSummaryItem> summaries;

  const _SummarySection({
    required this.title,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.titleMedium),
          const SizedBox(height: 10),
          if (summaries.isEmpty)
            Text(
              'Aucun résumé disponible.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray500,
              ),
            )
          else
            ...summaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(summary.summaryText, style: AppTheme.bodyMedium),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  final List<String> points;

  const _VerificationSection({required this.points});

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Points à vérifier', style: AppTheme.titleMedium),
          const SizedBox(height: 10),
          if (points.isEmpty)
            const Text('Aucun point d’attention automatique.')
          else
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(point)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntitySection extends StatelessWidget {
  final List<DocumentExtractedEntity> entities;

  const _EntitySection({required this.entities});

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Éléments détectés', style: AppTheme.titleMedium),
          const SizedBox(height: 10),
          if (entities.isEmpty)
            const Text('Aucun élément structuré important.')
          else
            ...entities.map(
              (entity) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(entity.label),
                subtitle: Text(entity.value),
                trailing: entity.confidenceScore == null
                    ? null
                    : Text(
                        '${(entity.confidenceScore! * 100).toStringAsFixed(0)}%',
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
