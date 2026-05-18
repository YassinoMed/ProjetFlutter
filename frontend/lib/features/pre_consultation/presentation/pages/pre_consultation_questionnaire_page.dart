import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/pre_consultation_questionnaire.dart';
import '../providers/pre_consultation_questionnaire_providers.dart';

class PreConsultationQuestionnairePage extends ConsumerStatefulWidget {
  final String appointmentId;

  const PreConsultationQuestionnairePage({
    super.key,
    required this.appointmentId,
  });

  @override
  ConsumerState<PreConsultationQuestionnairePage> createState() =>
      _PreConsultationQuestionnairePageState();
}

class _PreConsultationQuestionnairePageState
    extends ConsumerState<PreConsultationQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _durationController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _documentsController = TextEditingController();
  final _messageController = TextEditingController();

  bool _hasFever = false;
  double _painLevel = 0;
  bool _initialized = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _symptomsController.dispose();
    _durationController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _documentsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentAsync =
        ref.watch(appointmentDetailProvider(widget.appointmentId));
    final existing = ref.watch(
      preConsultationQuestionnaireByAppointmentProvider(widget.appointmentId),
    );
    final currentUser = ref.watch(currentUserProvider);
    final isCareTeam =
        currentUser?.isDoctor == true || currentUser?.isSecretary == true;

    if (!_initialized && existing != null) {
      _hydrate(existing);
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isCareTeam ? 'Questionnaire patient' : 'Avant le RDV'),
      ),
      body: appointmentAsync.when(
        data: (appointment) {
          final canEdit = currentUser?.isPatient == true && !isCareTeam;
          final dateLabel = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR')
              .format(appointment.dateTime);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ClinicalSurface(
                  color: AppTheme.primarySurface,
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Préparation de consultation',
                          style: AppTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        dateLabel,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.neutralGray600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ClinicalStatusChip(
                        label: 'AIDE AU MÉDECIN',
                        color: AppTheme.primaryColor,
                        icon: Icons.assignment_outlined,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _MedicalDisclaimer(),
                const SizedBox(height: 16),
                _Field(
                  controller: _reasonController,
                  label: 'Motif de consultation',
                  hint: 'Ex: douleur thoracique, suivi traitement...',
                  enabled: canEdit,
                  requiredField: true,
                  maxLines: 2,
                ),
                _Field(
                  controller: _symptomsController,
                  label: 'Symptômes',
                  hint: 'Listez les symptômes importants.',
                  enabled: canEdit,
                  requiredField: true,
                  maxLines: 3,
                ),
                _Field(
                  controller: _durationController,
                  label: 'Durée des symptômes',
                  hint: 'Ex: depuis 3 jours, depuis ce matin...',
                  enabled: canEdit,
                ),
                ClinicalSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Niveau de douleur',
                              style: AppTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${_painLevel.round()}/10',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _painLevel,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: '${_painLevel.round()}',
                        onChanged: canEdit
                            ? (value) => setState(() => _painLevel = value)
                            : null,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _hasFever,
                        onChanged: canEdit
                            ? (value) => setState(() => _hasFever = value)
                            : null,
                        title: const Text('Fièvre'),
                        subtitle: const Text(
                            'Cochez si le patient déclare de la fièvre.'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _medicationsController,
                  label: 'Médicaments déjà pris',
                  hint: 'Nom, dose approximative, fréquence si connue.',
                  enabled: canEdit,
                  maxLines: 2,
                ),
                _Field(
                  controller: _allergiesController,
                  label: 'Allergies',
                  hint: 'Médicaments, aliments, produits...',
                  enabled: canEdit,
                  maxLines: 2,
                ),
                _Field(
                  controller: _documentsController,
                  label: 'Documents liés',
                  hint: 'IDs ou titres séparés par des virgules.',
                  enabled: canEdit,
                ),
                _Field(
                  controller: _messageController,
                  label: 'Message libre',
                  hint: 'Contexte utile pour le médecin.',
                  enabled: canEdit,
                  maxLines: 4,
                ),
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        _save(appointment.patientId, appointment.doctorId),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer le questionnaire'),
                  ),
                ] else if (existing == null) ...[
                  const SizedBox(height: 8),
                  const ClinicalEmptyState(
                    icon: Icons.assignment_late_outlined,
                    title: 'Questionnaire non rempli',
                    message:
                        'Le patient n’a pas encore partagé de préparation pour ce rendez-vous.',
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  void _hydrate(PreConsultationQuestionnaire item) {
    _reasonController.text = item.reason;
    _symptomsController.text = item.symptoms;
    _durationController.text = item.symptomDuration;
    _medicationsController.text = item.medicationsTaken;
    _allergiesController.text = item.allergies;
    _documentsController.text = item.linkedDocumentIds.join(', ');
    _messageController.text = item.freeMessage;
    _hasFever = item.hasFever;
    _painLevel = item.painLevel.toDouble();
  }

  void _save(String fallbackPatientId, String doctorId) {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final patientId = currentUser?.id ?? fallbackPatientId;
    final linkedDocumentIds = _documentsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final questionnaire = PreConsultationQuestionnaire(
      appointmentId: widget.appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      reason: _reasonController.text.trim(),
      symptoms: _symptomsController.text.trim(),
      symptomDuration: _durationController.text.trim(),
      painLevel: _painLevel.round(),
      hasFever: _hasFever,
      medicationsTaken: _medicationsController.text.trim(),
      allergies: _allergiesController.text.trim(),
      linkedDocumentIds: linkedDocumentIds,
      freeMessage: _messageController.text.trim(),
      updatedAt: DateTime.now().toUtc(),
    );

    ref
        .read(preConsultationQuestionnaireStoreProvider.notifier)
        .save(questionnaire);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Questionnaire enregistré.')),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final bool requiredField;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    this.requiredField = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        minLines: 1,
        maxLines: maxLines,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Champ requis';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}

class _MedicalDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      color: AppTheme.softColor(AppTheme.warningColor, 0.12),
      elevated: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ce questionnaire prépare la consultation. Il ne remplace pas un avis médical et ne déclenche aucun diagnostic automatique.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
