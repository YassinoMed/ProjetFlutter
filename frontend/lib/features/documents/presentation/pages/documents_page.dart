library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/document_entity.dart';
import '../providers/document_providers.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  static const _types = <String?>[
    null,
    'PRESCRIPTION',
    'LAB_RESULT',
    'MEDICAL_REPORT',
    'RADIOLOGY_REPORT',
    'MEDICAL_CERTIFICATE',
    'OTHER',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);
    final query = ref.watch(documentSearchQueryProvider);
    final selectedType = ref.watch(documentTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents IA'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.documentUpload),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Importer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextFormField(
              initialValue: query,
              decoration: InputDecoration(
                hintText: 'Rechercher: ordonnance diabète',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.neutralGray200),
                ),
              ),
              onChanged: (value) =>
                  ref.read(documentSearchQueryProvider.notifier).state = value,
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = selectedType == type;

                return ChoiceChip(
                  label: Text(_typeLabel(type)),
                  selected: isSelected,
                  onSelected: (_) => ref
                      .read(documentTypeFilterProvider.notifier)
                      .state = type,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: documentsAsync.when(
              data: (documents) {
                if (documents.isEmpty) {
                  return _EmptyDocumentsState(query: query);
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(documentsProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      return _DocumentCard(document: document);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorDisplay(
                message: error.toString(),
                onRetry: () => ref.refresh(documentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final MedicalDocument document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(document.processingStatus);
    final date = document.documentDateUtc ?? document.processedAtUtc;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.documentDetail.replaceFirst(':id', document.id)),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.description_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(document.title, style: AppTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          document.documentType ?? 'Non classé',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.neutralGray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: document.processingStatus),
                ],
              ),
              const SizedBox(height: 12),
              if (date != null)
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(date.toLocal())}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutralGray600,
                  ),
                ),
              if (document.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: document.tags
                      .take(4)
                      .map((tag) => Chip(
                            label: Text(tag['tag']?.toString() ?? ''),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              if ((document.latestExtraction?.rawText ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  document.latestExtraction!.rawText!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutralGray600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyDocumentsState extends StatelessWidget {
  final String query;

  const _EmptyDocumentsState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                Icons.auto_awesome_rounded,
                size: 46,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('Aucun document trouvé', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Importez un document médical pour lancer l’analyse et le résumé intelligent.'
                  : 'Aucun document ne correspond à votre recherche.',
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

Color _statusColor(String status) {
  return switch (status) {
    'COMPLETED' => const Color(0xFF0F9D58),
    'PROCESSING' => const Color(0xFF2563EB),
    'FAILED' => const Color(0xFFDB4437),
    _ => const Color(0xFFF4B400),
  };
}

String _typeLabel(String? type) {
  return switch (type) {
    null => 'Tous',
    'PRESCRIPTION' => 'Ordonnances',
    'LAB_RESULT' => 'Analyses',
    'MEDICAL_REPORT' => 'Comptes rendus',
    'RADIOLOGY_REPORT' => 'Imagerie',
    'MEDICAL_CERTIFICATE' => 'Certificats',
    _ => 'Autres',
  };
}
