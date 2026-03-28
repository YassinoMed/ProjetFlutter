library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
        data: (document) => _DocumentDetailContent(
          documentId: documentId,
          document: document,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.refresh(documentDetailProvider(documentId)),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) =>
                      _DocumentQuestionSheet(documentId: documentId),
                ),
                icon: const Icon(Icons.question_answer_rounded),
                label: const Text('Poser une question'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await ref.read(documentActionsProvider).reanalyze(documentId);
                  ref.invalidate(documentDetailProvider(documentId));
                },
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Réanalyser'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentDetailContent extends ConsumerStatefulWidget {
  final String documentId;
  final MedicalDocument document;

  const _DocumentDetailContent({
    required this.documentId,
    required this.document,
  });

  @override
  ConsumerState<_DocumentDetailContent> createState() =>
      _DocumentDetailContentState();
}

class _DocumentDetailContentState
    extends ConsumerState<_DocumentDetailContent> {
  String? _selectedAudience;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedAudience ??= _defaultAudienceForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final date = document.documentDateUtc ?? document.processedAtUtc;
    final warnings = ((document.sourceMetadata?['analysis']
            as Map<String, dynamic>?)?['warnings'] as List?)
        ?.map((item) => item.toString())
        .toList();
    final availableAudiences = document.summaries
        .map((summary) => summary.audience)
        .toSet()
        .toList()
      ..sort();

    final selectedAudience = availableAudiences.contains(_selectedAudience)
        ? _selectedAudience
        : (availableAudiences.isNotEmpty ? availableAudiences.first : null);

    final summaries = selectedAudience == null
        ? document.summaries
        : document.summaries
            .where((summary) => summary.audience == selectedAudience)
            .toList();

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
                  if (document.languageCode != null)
                    _InfoChip(label: document.languageCode!.toUpperCase()),
                ],
              ),
              if (date != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Date document: ${DateFormat('dd/MM/yyyy').format(date.toLocal())}',
                  style: AppTheme.bodyMedium,
                ),
              ],
              if (document.classificationConfidence != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Confiance classification: ${(document.classificationConfidence! * 100).toStringAsFixed(0)}%',
                  style: AppTheme.bodySmall,
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
        if (warnings != null && warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Alertes de traitement',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings
                  .map((warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• $warning',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Résumés IA',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (availableAudiences.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableAudiences
                      .map((audience) => ChoiceChip(
                            label: Text(_audienceLabel(audience)),
                            selected: selectedAudience == audience,
                            onSelected: (_) {
                              setState(() => _selectedAudience = audience);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (summaries.isEmpty)
                const Text('Aucun résumé disponible pour cette audience.')
              else
                Column(
                  children: summaries
                      .map((summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SummaryTile(summary: summary),
                          ))
                      .toList(),
                ),
            ],
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

  String _defaultAudienceForCurrentUser() {
    final user = ref.read(currentUserProvider);

    if (user?.isPatient == true) return 'PATIENT';
    if (user?.isSecretary == true) return 'ADMINISTRATIVE';
    return 'PROFESSIONAL';
  }
}

class _DocumentQuestionSheet extends ConsumerStatefulWidget {
  final String documentId;

  const _DocumentQuestionSheet({required this.documentId});

  @override
  ConsumerState<_DocumentQuestionSheet> createState() =>
      _DocumentQuestionSheetState();
}

class _DocumentQuestionSheetState
    extends ConsumerState<_DocumentQuestionSheet> {
  final _questionController = TextEditingController();
  String? _selectedAudience;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _selectedAudience = user?.isPatient == true
        ? 'PATIENT'
        : user?.isSecretary == true
            ? 'ADMINISTRATIVE'
            : 'PROFESSIONAL';
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answerAsync =
        ref.watch(documentQuestionControllerProvider(widget.documentId));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Question sur le document', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'La réponse est limitée au contenu réellement extrait du document.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray500,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedAudience,
              decoration: const InputDecoration(
                labelText: 'Audience du résumé',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'PATIENT',
                  child: Text('Patient'),
                ),
                DropdownMenuItem(
                  value: 'PROFESSIONAL',
                  child: Text('Professionnel'),
                ),
                DropdownMenuItem(
                  value: 'ADMINISTRATIVE',
                  child: Text('Administratif'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedAudience = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _questionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex: quels traitements sont mentionnés ?',
                labelText: 'Votre question',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: answerAsync.isLoading ? null : _submit,
                    icon: answerAsync.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Analyser'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Effacer',
                  onPressed: () => ref
                      .read(
                          documentQuestionControllerProvider(widget.documentId)
                              .notifier)
                      .clear(),
                  icon: const Icon(Icons.clear_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            answerAsync.when(
              data: (answer) => answer == null
                  ? const SizedBox.shrink()
                  : _QuestionAnswerCard(answer: answer),
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  error.toString(),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    await ref
        .read(documentQuestionControllerProvider(widget.documentId).notifier)
        .ask(
          question: question,
          audience: _selectedAudience,
        );
  }
}

class _QuestionAnswerCard extends StatelessWidget {
  final DocumentQuestionAnswer answer;

  const _QuestionAnswerCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _audienceLabel(answer.audience),
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              if (answer.confidenceScore != null)
                Text(
                  '${(answer.confidenceScore! * 100).toStringAsFixed(0)}%',
                  style: AppTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(answer.answer, style: AppTheme.bodyMedium),
          if (answer.evidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Éléments utilisés', style: AppTheme.titleSmall),
            const SizedBox(height: 8),
            ...answer.evidence.map(
              (evidence) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${evidence.excerpt}',
                  style: AppTheme.bodySmall,
                ),
              ),
            ),
          ],
          if (answer.uncertaintyNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Incertitudes: ${answer.uncertaintyNotes.join(' ')}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.warningColor,
              ),
            ),
          ],
          if (answer.disclaimer != null) ...[
            const SizedBox(height: 12),
            Text(
              answer.disclaimer!,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray500,
              ),
            ),
          ],
        ],
      ),
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
                '${_audienceLabel(summary.audience)} · ${_formatLabel(summary.format)}',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              if (summary.confidenceScore != null)
                Text(
                  '${(summary.confidenceScore! * 100).toStringAsFixed(0)}%',
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

String _audienceLabel(String audience) {
  return switch (audience) {
    'PATIENT' => 'Patient',
    'ADMINISTRATIVE' => 'Administratif',
    _ => 'Professionnel',
  };
}

String _formatLabel(String format) {
  return switch (format) {
    'SHORT' => 'Court',
    'STRUCTURED' => 'Structuré',
    'PATIENT_FRIENDLY' => 'Vulgarisé',
    'PROFESSIONAL_DETAILED' => 'Détaillé',
    'ADMINISTRATIVE' => 'Administratif',
    'CRITICAL' => 'Critique',
    'BULLETS' => 'Points clés',
    _ => format,
  };
}
