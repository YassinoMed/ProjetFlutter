/// Page de création d'ordonnance médicale (médecin uniquement).
///
/// Saisie : patient + liste de médicaments dynamique. À la soumission,
/// génère un PDF via [PrescriptionPdfService] et redirige vers la
/// page détail avec aperçu + boutons partage/impression.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/prescription_entity.dart';
import '../providers/prescription_providers.dart';

class PrescriptionCreatePage extends ConsumerStatefulWidget {
  final String? initialPatientId;
  final String? initialPatientName;

  const PrescriptionCreatePage({
    super.key,
    this.initialPatientId,
    this.initialPatientName,
  });

  @override
  ConsumerState<PrescriptionCreatePage> createState() =>
      _PrescriptionCreatePageState();
}

class _PrescriptionCreatePageState
    extends ConsumerState<PrescriptionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_DraftItem> _items = [_DraftItem()];

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientName != null) {
      _patientNameController.text = widget.initialPatientName!;
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_DraftItem()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée. Reconnectez-vous.')),
      );
      return;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final prescription = Prescription(
      id: id,
      doctorId: user.id,
      doctorName: user.name,
      doctorSpeciality: user.speciality,
      doctorLicenseNumber: user.licenseNumber,
      patientId: widget.initialPatientId ?? 'patient-demo',
      patientName: _patientNameController.text.trim(),
      issuedAt: DateTime.now().toUtc(),
      items: _items.map((d) => d.toEntity()).toList(),
      additionalNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    ref.read(prescriptionStoreProvider.notifier).save(prescription);

    if (!mounted) return;
    context.pushReplacement(
      AppRoutes.prescriptionDetail.replaceFirst(':id', prescription.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une ordonnance'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined,
                      color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dr. ${user?.name ?? 'Médecin'} · ${user?.speciality ?? 'Spécialité non renseignée'}',
                      style: AppTheme.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patientNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du patient',
                hintText: 'Ex: Mohamed Bouneb',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Le nom du patient est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Médicaments', style: AppTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _items.length; i++)
              _MedicationCard(
                index: i,
                item: _items[i],
                canDelete: _items.length > 1,
                onDelete: () => _removeItem(i),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Recommandations (optionnel)',
                hintText: 'Ex: À prendre pendant les repas. Éviter l\'alcool.',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Générer l\'ordonnance PDF'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'L\'ordonnance sera signée numériquement avec votre identité '
              'MediConnect Pro et un QR code de vérification.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftItem {
  final name = TextEditingController();
  final dosage = TextEditingController();
  final frequency = TextEditingController();
  final duration = TextEditingController();
  final notes = TextEditingController();

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    notes.dispose();
  }

  PrescriptionItem toEntity() => PrescriptionItem(
        name: name.text.trim(),
        dosage: dosage.text.trim(),
        frequency: frequency.text.trim(),
        duration: duration.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );
}

class _MedicationCard extends StatelessWidget {
  final int index;
  final _DraftItem item;
  final bool canDelete;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.index,
    required this.item,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Médicament ${index + 1}',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (canDelete)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppTheme.errorColor,
                    tooltip: 'Retirer',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: item.name,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Doliprane 1000mg',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.dosage,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: '1g',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.duration,
                    decoration: const InputDecoration(
                      labelText: 'Durée',
                      hintText: '7 jours',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: item.frequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                hintText: 'Ex: 1 comprimé toutes les 6h',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Fréquence requise' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: item.notes,
              decoration: const InputDecoration(
                labelText: 'Remarques (optionnel)',
                hintText: 'Précautions, contre-indications…',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
