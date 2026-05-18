import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/emergency_medical_info.dart';
import '../providers/emergency_qr_providers.dart';

class EmergencyQrPage extends ConsumerStatefulWidget {
  const EmergencyQrPage({super.key});

  @override
  ConsumerState<EmergencyQrPage> createState() => _EmergencyQrPageState();
}

class _EmergencyQrPageState extends ConsumerState<EmergencyQrPage> {
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _treatmentsController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _enabled = false;
  String? _hydratedPatientId;

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _treatmentsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté.')),
      );
    }

    final store = ref.watch(emergencyMedicalInfoStoreProvider.notifier);
    final info = ref.watch(emergencyMedicalInfoProvider(user.id)) ??
        store.getOrCreate(patientId: user.id, patientName: user.name);

    if (_hydratedPatientId != user.id) {
      _hydrate(info);
      _hydratedPatientId = user.id;
    }

    final currentInfo = _buildInfo(user.id, user.name);
    final service = ref.watch(emergencyQrServiceProvider);
    final payload = service.buildPayload(currentInfo);

    return Scaffold(
      appBar: AppBar(title: const Text('QR code d’urgence')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClinicalSurface(
            color: AppTheme.softColor(AppTheme.errorColor, 0.10),
            elevated: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emergency_outlined,
                    color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ce QR code contient uniquement les informations vitales que vous choisissez de partager. Il ne donne jamais accès à tout votre dossier médical.',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neutralGray700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClinicalSurface(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              title:
                  Text('Activer mon QR d’urgence', style: AppTheme.titleMedium),
              subtitle: const Text(
                'Désactivé, le QR reste masqué et ne doit pas être utilisé.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_enabled && currentInfo.hasVitalData)
            ClinicalSurface(
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: 220,
                    child: CustomPaint(
                      painter: _QrPainter(payload),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Informations fournies par le patient',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neutralGray500,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: payload));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payload QR copié pour vérification.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copier le contenu'),
                  ),
                ],
              ),
            )
          else
            const ClinicalEmptyState(
              icon: Icons.qr_code_2_rounded,
              title: 'QR non publié',
              message:
                  'Activez le QR et renseignez au moins une information vitale.',
            ),
          const SizedBox(height: 16),
          _Field(controller: _bloodTypeController, label: 'Groupe sanguin'),
          _Field(
            controller: _allergiesController,
            label: 'Allergies importantes',
            hint: 'Séparées par des virgules',
          ),
          _Field(
            controller: _conditionsController,
            label: 'Maladies chroniques importantes',
            hint: 'Séparées par des virgules',
          ),
          _Field(
            controller: _treatmentsController,
            label: 'Traitements critiques',
            hint: 'Séparés par des virgules',
          ),
          _Field(
            controller: _contactNameController,
            label: 'Contact d’urgence',
          ),
          _Field(
            controller: _contactPhoneController,
            label: 'Téléphone du contact',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(emergencyMedicalInfoStoreProvider.notifier)
                  .save(currentInfo);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR d’urgence mis à jour.')),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _hydrate(EmergencyMedicalInfo info) {
    _enabled = info.enabled;
    _bloodTypeController.text = info.bloodType;
    _allergiesController.text = info.importantAllergies.join(', ');
    _conditionsController.text = info.chronicConditions.join(', ');
    _treatmentsController.text = info.criticalTreatments.join(', ');
    _contactNameController.text = info.emergencyContactName;
    _contactPhoneController.text = info.emergencyContactPhone;
  }

  EmergencyMedicalInfo _buildInfo(String patientId, String patientName) {
    return EmergencyMedicalInfo(
      patientId: patientId,
      patientName: patientName,
      enabled: _enabled,
      bloodType: _bloodTypeController.text.trim(),
      importantAllergies: _csv(_allergiesController.text),
      chronicConditions: _csv(_conditionsController.text),
      criticalTreatments: _csv(_treatmentsController.text),
      emergencyContactName: _contactNameController.text.trim(),
      emergencyContactPhone: _contactPhoneController.text.trim(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  List<String> _csv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;

  _QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.shortestSide / moduleCount;
    final paint = Paint()..color = Colors.black;
    final background = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, background);

    for (var x = 0; x < moduleCount; x++) {
      for (var y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * moduleSize,
              y * moduleSize,
              moduleSize,
              moduleSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
