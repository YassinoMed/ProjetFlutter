library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../providers/medical_record_providers.dart';

class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _categories = [
    (null, 'Tout', Icons.folder_open_rounded, AppTheme.primaryColor),
    (
      'lab_result',
      'Analyses',
      Icons.science_outlined,
      AppTheme.primaryColor,
    ),
    (
      'consultation',
      'Consultations',
      Icons.description_outlined,
      AppTheme.primaryLight,
    ),
    (
      'prescription',
      'Ordonnances',
      Icons.medication_outlined,
      AppTheme.successColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addRecord),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ClinicalStatusChip(
                    label: 'STOCKAGE LOCAL CHIFFRÉ AES-256',
                    color: AppTheme.successColor,
                    icon: Icons.lock_rounded,
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  Text('Historique', style: AppTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    'Retrouvez l’intégralité de vos soins numériques.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.neutralGray500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClinicalSurface(
                    padding: const EdgeInsets.all(6),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      splashFactory: NoSplash.splashFactory,
                      tabs: _categories
                          .map((category) => Tab(text: category.$2))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  final recordsAsync =
                      ref.watch(medicalRecordsProvider(category.$1));

                  return recordsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return ClinicalEmptyState(
                          icon: category.$3,
                          title: 'Aucun document ${category.$2.toLowerCase()}',
                          message:
                              'Les documents ${category.$2.toLowerCase()} apparaîtront ici après synchronisation.',
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(medicalRecordsProvider(category.$1));
                          await ref
                              .read(medicalRecordsProvider(category.$1).future);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RecordCard(record: record),
                            );
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => ErrorDisplay(
                      message: err.toString(),
                      onRetry: () =>
                          ref.invalidate(medicalRecordsProvider(category.$1)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final MedicalRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy', 'fr_FR').format(record.recordedAtUtc);
    final meta = _meta(record.category);

    return ClinicalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: meta.$3.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(meta.$2, color: meta.$3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.$1, style: AppTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Dernière mise à jour • $dateStr',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.neutralGray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.more_vert_rounded,
                color: AppTheme.neutralGray400,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neutralGray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              _recordPreview(record),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClinicalStatusChip(
                label: meta.$1.toUpperCase(),
                color: meta.$3,
                compact: true,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(
                  AppRoutes.recordDetail.replaceFirst(':id', record.id),
                ),
                child: const Text('Voir détails'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _meta(String category) {
    return switch (category) {
      'consultation' => (
          'Consultation',
          Icons.description_outlined,
          AppTheme.primaryLight
        ),
      'prescription' => (
          'Ordonnance',
          Icons.medication_outlined,
          AppTheme.successColor
        ),
      'lab_result' => (
          'Résultats labo',
          Icons.science_outlined,
          AppTheme.primaryColor
        ),
      'imaging' => ('Imagerie', Icons.image_outlined, AppTheme.warningColor),
      _ => (
          'Document médical',
          Icons.folder_open_outlined,
          AppTheme.neutralGray500
        ),
    };
  }

  String _recordPreview(MedicalRecord record) {
    final notes = record.metadataEncrypted?['notes']?.toString();
    if (notes != null && notes.isNotEmpty) {
      return notes;
    }

    final originalName =
        record.metadataEncrypted?['original_file_name']?.toString();
    if (originalName != null && originalName.isNotEmpty) {
      return originalName;
    }

    return 'Aucun résumé structuré disponible pour ce document.';
  }
}
