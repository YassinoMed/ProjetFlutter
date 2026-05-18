/// Page de création/édition d'un compte rendu de consultation (médecin).
///
/// Si un compte rendu existe déjà pour cette téléconsultation, on le
/// charge et on pré-remplit le formulaire (mode édition).
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

class ConsultationReportCreatePage extends ConsumerStatefulWidget {
  final String teleconsultationId;
  final String patientId;
  final String patientName;
  final DateTime? consultationAt;

  const ConsultationReportCreatePage({
    super.key,
    required this.teleconsultationId,
    required this.patientId,
    required this.patientName,
    this.consultationAt,
  });

  @override
  ConsumerState<ConsultationReportCreatePage> createState() =>
      _ConsultationReportCreatePageState();
}

class _ConsultationReportCreatePageState
    extends ConsumerState<ConsultationReportCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _conclusionCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();
  final _privateNotesCtrl = TextEditingController();
  DateTime? _followUpAt;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateIfEdit());
  }

  void _hydrateIfEdit() {
    final existing = ref
        .read(consultationReportStoreProvider.notifier)
        .byTeleconsultation(widget.teleconsultationId);
    if (existing == null) return;
    setState(() {
      _isEdit = true;
      _reasonCtrl.text = existing.reason;
      _summaryCtrl.text = existing.summary;
      _conclusionCtrl.text = existing.conclusion ?? '';
      _treatmentCtrl.text = existing.treatment ?? '';
      _recommendationsCtrl.text = existing.recommendations ?? '';
      _privateNotesCtrl.text = existing.privateNotes ?? '';
      _followUpAt = existing.followUpAt;
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _summaryCtrl.dispose();
    _conclusionCtrl.dispose();
    _treatmentCtrl.dispose();
    _recommendationsCtrl.dispose();
    _privateNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpAt ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _followUpAt = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée.')),
      );
      return;
    }

    final store = ref.read(consultationReportStoreProvider.notifier);
    final existing = store.byTeleconsultation(widget.teleconsultationId);
    final now = DateTime.now().toUtc();

    final report = ConsultationReport(
      id: existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      teleconsultationId: widget.teleconsultationId,
      doctorId: user.id,
      doctorName: user.name,
      doctorSpeciality: user.speciality,
      patientId: widget.patientId,
      patientName: widget.patientName,
      consultationAt: widget.consultationAt ?? existing?.consultationAt ?? now,
      reason: _reasonCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      conclusion: _emptyToNull(_conclusionCtrl.text),
      treatment: _emptyToNull(_treatmentCtrl.text),
      recommendations: _emptyToNull(_recommendationsCtrl.text),
      followUpAt: _followUpAt,
      privateNotes: _emptyToNull(_privateNotesCtrl.text),
      createdAt: existing?.createdAt ?? now,
      updatedAt: existing == null ? null : now,
    );

    store.save(report);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? 'Compte rendu mis à jour' : 'Compte rendu enregistré',
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );

    context.pushReplacement(
      AppRoutes.consultationReportDetail.replaceFirst(':id', report.id),
    );
  }

  String? _emptyToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier compte rendu' : 'Nouveau compte rendu'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PatientBanner(
              patientName: widget.patientName,
              consultationAt: widget.consultationAt,
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Partie partagée avec le patient',
                icon: Icons.share_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Motif de consultation *',
                hintText: 'Ex: Toux persistante depuis 5 jours',
                prefixIcon: Icon(Icons.help_outline_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Motif requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Résumé de la consultation *',
                hintText:
                    'Examen clinique, observations, échanges avec le patient…',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Résumé requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conclusionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Conclusion médicale',
                hintText:
                    'Hypothèse principale, examens à confirmer. Pas un diagnostic ferme automatique.',
                prefixIcon: Icon(Icons.fact_check_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _treatmentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Traitement recommandé',
                hintText: 'Cf. ordonnance jointe le cas échéant.',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recommendationsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Recommandations',
                hintText: 'Hygiène de vie, suivi, signes d\'alerte…',
                prefixIcon: Icon(Icons.tips_and_updates_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _FollowUpField(
              followUpAt: _followUpAt,
              onTap: _pickFollowUp,
              onClear: () => setState(() => _followUpAt = null),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(
              'Notes privées (médecin uniquement)',
              icon: Icons.lock_outline_rounded,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _privateNotesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes privées',
                hintText: 'Observations à ne pas partager avec le patient.',
                prefixIcon: const Icon(Icons.shield_outlined),
                fillColor: AppTheme.errorColor.withValues(alpha: 0.04),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(_isEdit
                  ? Icons.save_outlined
                  : Icons.assignment_turned_in_outlined),
              label: Text(_isEdit
                  ? 'Enregistrer les modifications'
                  : 'Créer le compte rendu'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le patient verra tout sauf vos notes privées.',
              style: AppTheme.bodySmall
                  .copyWith(color: AppTheme.neutralGray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const _SectionLabel(this.text, {required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return Row(
      children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.titleMedium.copyWith(
            color: c,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PatientBanner extends StatelessWidget {
  final String patientName;
  final DateTime? consultationAt;
  const _PatientBanner({required this.patientName, this.consultationAt});

  @override
  Widget build(BuildContext context) {
    final dateLabel = consultationAt == null
        ? 'aujourd\'hui'
        : DateFormat('dd MMMM yyyy · HH:mm', 'fr_FR')
            .format(consultationAt!.toLocal());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName,
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                Text('Consultation $dateLabel',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.neutralGray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpField extends StatelessWidget {
  final DateTime? followUpAt;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _FollowUpField(
      {required this.followUpAt,
      required this.onTap,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de contrôle suggérée',
          prefixIcon: const Icon(Icons.event_available_outlined),
          suffixIcon: followUpAt != null
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded),
                )
              : null,
        ),
        child: Text(
          followUpAt == null
              ? 'Non renseignée'
              : DateFormat('dd MMMM yyyy', 'fr_FR').format(followUpAt!),
        ),
      ),
    );
  }
}
