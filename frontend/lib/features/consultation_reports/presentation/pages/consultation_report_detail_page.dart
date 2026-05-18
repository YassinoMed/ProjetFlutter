/// Détail d'un compte rendu — vue adaptée au rôle.
///
/// Médecin :
///   - voit tout (y compris notes privées dans une carte rouge)
///   - peut éditer
/// Patient :
///   - voit uniquement la projection partageable (toPatientView)
///   - aucune trace UI des notes privées
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/consultation_report_entity.dart';
import '../providers/consultation_report_providers.dart';

class ConsultationReportDetailPage extends ConsumerWidget {
  final String reportId;
  const ConsultationReportDetailPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(consultationReportStoreProvider.notifier);
    final raw = store.byId(reportId);
    final currentUser = ref.watch(currentUserProvider);

    if (raw == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compte rendu')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Compte rendu introuvable. Il a peut-être été supprimé '
              'ou n\'a pas été persisté (mode démo en mémoire).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // SÉCURITÉ: si l'utilisateur courant n'est PAS le médecin qui a rédigé
    // le compte rendu, on lui présente la projection patient. Le patient
    // ne doit jamais voir les notes privées même si l'ID est deviné.
    final isOwnerDoctor =
        currentUser != null && currentUser.id == raw.doctorId;
    final report = isOwnerDoctor ? raw : raw.toPatientView();

    final dateFr = DateFormat('dd MMMM yyyy · HH:mm', 'fr_FR')
        .format(report.consultationAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compte rendu'),
        actions: [
          if (isOwnerDoctor)
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(
                AppRoutes.consultationReportCreate,
                extra: {
                  'teleconsultationId': report.teleconsultationId,
                  'patientId': report.patientId,
                  'patientName': report.patientName,
                  'consultationAt': report.consultationAt,
                },
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(report: report, dateFr: dateFr, isDoctor: isOwnerDoctor),
          const SizedBox(height: 16),
          _Section(label: 'Motif', icon: Icons.help_outline_rounded, content: report.reason),
          _Section(
              label: 'Résumé de la consultation',
              icon: Icons.notes_rounded,
              content: report.summary),
          if (report.conclusion != null)
            _Section(
              label: 'Conclusion médicale',
              icon: Icons.fact_check_outlined,
              content: report.conclusion!,
            ),
          if (report.treatment != null)
            _Section(
              label: 'Traitement recommandé',
              icon: Icons.medication_outlined,
              content: report.treatment!,
            ),
          if (report.recommendations != null)
            _Section(
              label: 'Recommandations',
              icon: Icons.tips_and_updates_outlined,
              content: report.recommendations!,
            ),
          if (report.followUpAt != null)
            _Section(
              label: 'Date de contrôle suggérée',
              icon: Icons.event_available_outlined,
              content: DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                  .format(report.followUpAt!.toLocal()),
              accentColor: AppTheme.successColor,
            ),
          if (isOwnerDoctor && report.privateNotes != null) ...[
            const SizedBox(height: 8),
            _PrivateNotesCard(notes: report.privateNotes!),
          ],
          const SizedBox(height: 16),
          if (!isOwnerDoctor)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.infoColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce compte rendu est une synthèse rédigée par votre '
                      'médecin. En cas de question, contactez-le via la '
                      'messagerie sécurisée.',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ConsultationReport report;
  final String dateFr;
  final bool isDoctor;
  const _HeaderCard(
      {required this.report, required this.dateFr, required this.isDoctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.publicReference,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  isDoctor ? Icons.medical_services_outlined : Icons.person,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isDoctor
                  ? 'Patient · ${report.patientName}'
                  : 'Dr. ${report.doctorName}'
                      '${report.doctorSpeciality == null ? '' : ' · ${report.doctorSpeciality}'}',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(dateFr,
                style: AppTheme.bodySmall
                    .copyWith(color: AppTheme.neutralGray500)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final IconData icon;
  final String content;
  final Color? accentColor;
  const _Section({
    required this.label,
    required this.icon,
    required this.content,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = accentColor ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutralGray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: c, size: 18),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(
                    color: c,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(content, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PrivateNotesCard extends StatelessWidget {
  final String notes;
  const _PrivateNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppTheme.errorColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'NOTES PRIVÉES MÉDECIN',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(notes, style: AppTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            'Non visible par le patient.',
            style: AppTheme.bodySmall
                .copyWith(color: AppTheme.errorColor, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
