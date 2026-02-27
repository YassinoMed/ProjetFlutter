import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/core/router/app_routes.dart';
import 'package:mediconnect_pro/features/medical_records/domain/entities/medical_record_entity.dart';
import 'package:mediconnect_pro/features/medical_records/presentation/providers/medical_record_providers.dart';
import 'package:mediconnect_pro/shared/widgets/error_display.dart';

class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = [
    (null, 'Tout', Icons.folder_open_rounded, Color(0xFF3498DB)),
    (
      'consultation',
      'Consultations',
      Icons.assignment_rounded,
      Color(0xFF2E86C1)
    ),
    (
      'prescription',
      'Ordonnances',
      Icons.medication_rounded,
      Color(0xFF27AE60)
    ),
    ('lab_result', 'Analyses', Icons.science_rounded, Color(0xFF8E44AD)),
    ('imaging', 'Imagerie', Icons.visibility_rounded, Color(0xFFE67E22)),
    ('certificate', 'Certificats', Icons.verified_rounded, Color(0xFF16A085)),
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
      appBar: AppBar(
        title: const Text('Dossier Médical'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Implement search within records
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _categories
              .map((c) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.$3, size: 16),
                        const SizedBox(width: 6),
                        Text(c.$2),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((cat) {
          final catKey = cat.$1;
          final catRecords = ref.watch(medicalRecordsProvider(catKey));

          return catRecords.when(
            data: (records) {
              if (records.isEmpty) {
                return _buildEmptyCategory(cat.$2, cat.$3, cat.$4);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(medicalRecordsProvider(catKey).future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final cat = _getCategoryMeta(record.category);
                    return _RecordCard(
                      record: record,
                      icon: cat.$3,
                      color: cat.$4,
                      onTap: () => context.push(AppRoutes.recordDetail
                          .replaceFirst(':id', record.id)),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => ErrorDisplay(
              message: err.toString(),
              onRetry: () => ref.refresh(medicalRecordsProvider(catKey)),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addRecord),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  (String?, String, IconData, Color) _getCategoryMeta(String category) {
    return _categories.firstWhere(
      (c) => c.$1 == category,
      orElse: () => (
        'other',
        'Autre',
        Icons.description_rounded,
        const Color(0xFF95A5A6)
      ),
    );
  }

  Widget _buildEmptyCategory(String name, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun document $name',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Vos documents apparaîtront ici.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.neutralGray500),
          ),
        ],
      ),
    );
  }
}

// ── Record Card ─────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RecordCard({
    required this.record,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy', 'fr_FR').format(record.recordedAtUtc);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isDark
            ? BorderSide(color: Colors.white.withOpacity(0.08))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel(record.category),
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppTheme.neutralGray500),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.neutralGray500),
                        ),
                        if (record.doctorUserId != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.person_rounded,
                              size: 12, color: AppTheme.neutralGray500),
                          const SizedBox(width: 4),
                          Text(
                            'Dr.',
                            style: AppTheme.bodySmall
                                .copyWith(color: AppTheme.neutralGray500),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // E2E badge
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.neutralGray400),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'consultation' => 'Consultation',
      'prescription' => 'Ordonnance',
      'lab_result' => 'Résultat d\'analyse',
      'imaging' => 'Imagerie médicale',
      'certificate' => 'Certificat médical',
      _ => 'Document médical',
    };
  }
}
