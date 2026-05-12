library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/ai/cloud_medical_ai_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/document_image_quality_service.dart';
import '../../data/services/mlkit_document_ocr_service.dart';
import '../../domain/entities/document_upload_file.dart';
import '../providers/document_providers.dart';

class DocumentUploadPage extends ConsumerStatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  ConsumerState<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends ConsumerState<DocumentUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DocumentUploadFile? _selectedFile;
  String? _documentType;
  DateTime? _documentDate;
  String? _selectedPatientId;
  String? _selectedPatientName;
  MlkitOcrResult? _localOcr;
  DocumentImageQualityResult? _imageQuality;
  String? _cloudAnalysis;
  String? _ocrError;
  String? _qualityError;
  String? _cloudAnalysisError;
  bool _isOcrRunning = false;
  bool _isQualityRunning = false;
  bool _isCloudAnalysisRunning = false;
  bool _isLoading = false;

  static const _types = [
    'PRESCRIPTION',
    'LAB_RESULT',
    'MEDICAL_REPORT',
    'RADIOLOGY_REPORT',
    'REFERRAL_LETTER',
    'MEDICAL_CERTIFICATE',
    'CONSULTATION_HISTORY',
    'OTHER',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importer un document')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du document',
                hintText: 'Ex: Résultats bilan mars 2026',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est requis';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              decoration: const InputDecoration(
                labelText: 'Type suggéré',
              ),
              items: _types
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _documentType = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDocumentDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date du document',
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _documentDate == null
                            ? 'Non renseignée'
                            : DateFormat('dd/MM/yyyy')
                                .format(_documentDate!.toLocal()),
                      ),
                    ),
                    if (_documentDate != null)
                      IconButton(
                        onPressed: () => setState(() => _documentDate = null),
                        icon: const Icon(Icons.clear_rounded),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PatientSelector(
              selectedPatientId: _selectedPatientId,
              selectedPatientName: _selectedPatientName,
              onChanged: (patientId, patientName) {
                setState(() {
                  _selectedPatientId = patientId;
                  _selectedPatientName = patientName;
                });
              },
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file_rounded, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile?.name ??
                          'Choisir un PDF, une image scannée ou un texte',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_isQualityRunning ||
                _imageQuality != null ||
                _qualityError != null) ...[
              _ImageQualityCard(
                isLoading: _isQualityRunning,
                result: _imageQuality,
                error: _qualityError,
                onRetry: _selectedFile == null ? null : _runImageQualityCheck,
              ),
              const SizedBox(height: 20),
            ],
            if (_isOcrRunning || _localOcr != null || _ocrError != null) ...[
              _LocalOcrCard(
                isLoading: _isOcrRunning,
                result: _localOcr,
                error: _ocrError,
                onRetry: _selectedFile == null ? null : _rerunOcrAndCloud,
              ),
              const SizedBox(height: 20),
            ],
            if (_isCloudAnalysisRunning ||
                _cloudAnalysis != null ||
                _cloudAnalysisError != null) ...[
              _CloudAnalysisCard(
                isLoading: _isCloudAnalysisRunning,
                analysis: _cloudAnalysis,
                error: _cloudAnalysisError,
                onRetry:
                    _selectedFile == null ? null : _runCloudDocumentAnalysis,
              ),
              const SizedBox(height: 20),
            ],
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text('Importer et analyser'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt', 'webp'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lire ce fichier. Réessayez.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedFile = DocumentUploadFile(
        name: picked.name,
        bytes: bytes,
        size: picked.size,
        path: kIsWeb ? null : picked.path,
      );
      _localOcr = null;
      _imageQuality = null;
      _cloudAnalysis = null;
      _ocrError = null;
      _qualityError = null;
      _cloudAnalysisError = null;
    });

    await Future.wait([
      _runImageQualityCheck(),
      _runLocalOcr(),
    ]);
    await _runCloudDocumentAnalysis();
  }

  Future<void> _runImageQualityCheck() async {
    final file = _selectedFile;
    if (file == null) {
      return;
    }

    final qualityService = ref.read(documentImageQualityServiceProvider);
    if (!qualityService.supports(file.name)) {
      setState(() {
        _imageQuality = null;
        _qualityError =
            'Contrôle qualité disponible seulement pour les images JPG, PNG ou WEBP.';
      });
      return;
    }

    setState(() {
      _isQualityRunning = true;
      _qualityError = null;
    });

    try {
      final result = await qualityService.analyze(
        filename: file.name,
        bytes: file.bytes,
      );

      if (!mounted) return;

      setState(() {
        _imageQuality = result;
        _isQualityRunning = false;
        _qualityError = result == null
            ? 'Qualité image non analysable pour ce fichier.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _imageQuality = null;
        _isQualityRunning = false;
        _qualityError = 'Contrôle qualité image indisponible.';
      });
    }
  }

  Future<void> _runLocalOcr() async {
    final file = _selectedFile;
    if (file == null) {
      return;
    }

    final ocrService = ref.read(mlkitDocumentOcrServiceProvider);
    if (!ocrService.supports(filename: file.name, path: file.path)) {
      setState(() {
        _localOcr = null;
        _ocrError = _isPlainTextFile(file.name)
            ? 'Fichier texte lu directement; OCR ML Kit non nécessaire.'
            : 'OCR local disponible seulement pour les images JPG, PNG ou WEBP sur mobile.';
      });
      return;
    }

    setState(() {
      _isOcrRunning = true;
      _ocrError = null;
    });

    try {
      final result = await ocrService.extract(
        filename: file.name,
        path: file.path,
      );

      if (!mounted) return;

      setState(() {
        _localOcr = result;
        _isOcrRunning = false;

        if (result == null || !result.hasReadableText) {
          _ocrError = 'ML Kit n’a pas extrait assez de texte exploitable.';
          return;
        }

        _ocrError = null;
        _documentType ??= result.suggestedDocumentType;
        _documentDate ??= result.suggestedDocumentDate;

        if (_titleController.text.trim().isEmpty &&
            result.suggestedTitle != null) {
          _titleController.text = result.suggestedTitle!;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _localOcr = null;
        _isOcrRunning = false;
        _ocrError = 'OCR local indisponible pour ce fichier.';
      });
    }
  }

  Future<void> _rerunOcrAndCloud() async {
    await _runLocalOcr();
    await _runCloudDocumentAnalysis();
  }

  Future<void> _runCloudDocumentAnalysis() async {
    final file = _selectedFile;
    if (file == null || !mounted) {
      return;
    }

    final extractedText = _extractTextForCloud(file);
    if (extractedText == null) {
      setState(() {
        _cloudAnalysis = null;
        _isCloudAnalysisRunning = false;
        _cloudAnalysisError = _cloudMissingTextMessage(file);
      });
      return;
    }

    setState(() {
      _cloudAnalysis = null;
      _cloudAnalysisError = null;
      _isCloudAnalysisRunning = true;
    });

    try {
      final response =
          await ref.read(cloudMedicalAiServiceProvider).analyzeDocument(
                extractedText: extractedText,
                title: _titleController.text,
                documentType: _documentType,
                filename: file.name,
              );

      if (!mounted || _selectedFile != file) {
        return;
      }

      setState(() {
        _cloudAnalysis = response;
        _cloudAnalysisError = null;
        _isCloudAnalysisRunning = false;
      });
    } catch (error) {
      if (!mounted || _selectedFile != file) {
        return;
      }

      setState(() {
        _cloudAnalysis = null;
        _cloudAnalysisError = CloudMedicalAiService.friendlyError(error);
        _isCloudAnalysisRunning = false;
      });
    }
  }

  String? _extractTextForCloud(DocumentUploadFile file) {
    if (_localOcr?.hasReadableText == true) {
      return _localOcr!.rawText;
    }

    if (_isPlainTextFile(file.name)) {
      final text = utf8.decode(file.bytes, allowMalformed: true).trim();
      return text.length >= 12 ? text : null;
    }

    return null;
  }

  bool _isPlainTextFile(String filename) {
    return filename.toLowerCase().endsWith('.txt');
  }

  String _cloudMissingTextMessage(DocumentUploadFile file) {
    if (_isPlainTextFile(file.name)) {
      return 'Le fichier texte ne contient pas assez de contenu exploitable.';
    }

    if (kIsWeb) {
      return 'Aucun texte ML Kit a envoyer a Gemini. ML Kit OCR fonctionne sur Android/iOS pour les images; sur Web, importez le document puis laissez l’analyse serveur traiter le PDF ou l’image.';
    }

    return 'Aucun texte OCR ML Kit exploitable a envoyer a Gemini. Utilisez une image JPG, PNG ou WEBP lisible.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if ((user?.isDoctor == true || user?.isSecretary == true) &&
        (_selectedPatientId == null || _selectedPatientId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un patient'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final document = await ref.read(documentActionsProvider).upload(
            file: _selectedFile!,
            title: _titleController.text.trim(),
            patientUserId: _selectedPatientId,
            documentTypeHint: _documentType,
            documentDateUtc: _documentDate,
            clientOcrText:
                _localOcr?.hasReadableText == true ? _localOcr!.rawText : null,
            clientOcrEngine: _localOcr?.engine,
            clientOcrLanguage: _localOcr?.languageCode,
            clientOcrConfidence: _localOcr?.confidenceScore,
            clientImageQualityScore: _imageQuality?.qualityScore,
            clientImageWidth: _imageQuality?.width,
            clientImageHeight: _imageQuality?.height,
            clientImageQualityWarnings: _imageQuality?.warnings,
          );

      if (mounted) {
        context.go(AppRoutes.documentDetail.replaceFirst(':id', document.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDocumentDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _documentDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );

    if (selected != null) {
      setState(() => _documentDate = selected);
    }
  }
}

class _ImageQualityCard extends StatelessWidget {
  final bool isLoading;
  final DocumentImageQualityResult? result;
  final String? error;
  final VoidCallback? onRetry;

  const _ImageQualityCard({
    required this.isLoading,
    required this.result,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final score = result?.qualityScore;
    final isGood = result?.isGoodEnough == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutralGray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGood ? Icons.verified_rounded : Icons.camera_alt_rounded,
                color: isGood ? AppTheme.successColor : AppTheme.warningColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading
                      ? 'Contrôle qualité image en cours…'
                      : 'Qualité de l’image',
                  style: AppTheme.labelLarge,
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: isLoading ? null : onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Relancer le contrôle qualité',
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const LinearProgressIndicator()
          else if (error != null)
            Text(
              error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
            )
          else if (result != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    'Score ${(score! * 100).toStringAsFixed(0)}%',
                  ),
                ),
                Chip(label: Text('${result!.width} x ${result!.height}')),
                Chip(
                  label: Text(isGood ? 'Lisible' : 'À améliorer'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (result!.warnings.isEmpty)
              Text(
                'Image exploitable pour OCR et analyse documentaire.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.successColor,
                ),
              )
            else
              ...result!.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $warning',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Le score aide à éviter les documents flous ou mal éclairés. Le backend garde seulement les métadonnées qualité, pas une copie du texte OCR en clair.',
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

class _LocalOcrCard extends StatelessWidget {
  final bool isLoading;
  final MlkitOcrResult? result;
  final String? error;
  final VoidCallback? onRetry;

  const _LocalOcrCard({
    required this.isLoading,
    required this.result,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = result?.hasReadableText == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutralGray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasText
                    ? Icons.document_scanner_rounded
                    : Icons.auto_awesome_rounded,
                color: hasText ? AppTheme.successColor : AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading
                      ? 'OCR ML Kit en cours…'
                      : 'Pré-analyse locale ML Kit',
                  style: AppTheme.labelLarge,
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: isLoading ? null : onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Relancer OCR local',
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const LinearProgressIndicator()
          else if (error != null)
            Text(
              error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
            )
          else if (result != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (result!.suggestedDocumentType != null)
                  Chip(
                    label: Text('Type: ${result!.suggestedDocumentType}'),
                  ),
                Chip(
                  label: Text(
                    'Confiance ${(result!.confidenceScore * 100).toStringAsFixed(0)}%',
                  ),
                ),
                if (result!.languageCode != null)
                  Chip(label: Text(result!.languageCode!.toUpperCase())),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result!.normalizedText.length > 320
                  ? '${result!.normalizedText.substring(0, 320)}…'
                  : result!.normalizedText,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Ce texte aide le backend si OCR serveur indisponible. Il ne remplace pas la validation médicale.',
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

class _CloudAnalysisCard extends StatelessWidget {
  final bool isLoading;
  final String? analysis;
  final String? error;
  final VoidCallback? onRetry;

  const _CloudAnalysisCard({
    required this.isLoading,
    required this.analysis,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnalysis = analysis != null && analysis!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutralGray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAnalysis
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_sync_rounded,
                color: hasAnalysis ? AppTheme.successColor : AppTheme.infoColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading
                      ? 'Analyse Gemini en cours…'
                      : 'Analyse Gemini du document',
                  style: AppTheme.labelLarge,
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: isLoading ? null : onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Relancer l’analyse IA',
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('POST')),
              Chip(label: Text('Max tokens 900')),
              Chip(label: Text('Température 0,7')),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const LinearProgressIndicator()
          else if (error != null)
            Text(
              error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
            )
          else if (hasAnalysis)
            Text(
              analysis!,
              style: AppTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          Text(
            'La réponse provient de Gemini à partir du texte extrait localement. Elle doit rester validée par le médecin.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.neutralGray500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientSelector extends ConsumerWidget {
  final String? selectedPatientId;
  final String? selectedPatientName;
  final void Function(String? patientId, String? patientName) onChanged;

  const _PatientSelector({
    required this.selectedPatientId,
    required this.selectedPatientName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user?.isDoctor != true && user?.isSecretary != true) {
      return const SizedBox.shrink();
    }

    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return appointmentsAsync.when(
      data: (appointments) {
        final patients = <String, String>{};
        for (final appointment in appointments) {
          if (appointment.patientId.isNotEmpty) {
            patients[appointment.patientId] = appointment.patientName ??
                'Patient ${appointment.patientId.substring(0, 8)}';
          }
        }

        if (patients.isEmpty) {
          return TextFormField(
            initialValue: selectedPatientId,
            decoration: const InputDecoration(
              labelText: 'ID du patient (requis)',
              hintText: 'Entrez l\'UUID du patient',
              helperText: 'Requis pour les médecins et secrétaires',
            ),
            onChanged: (value) {
              onChanged(value.isEmpty ? null : value, null);
            },
          );
        }

        final patientList = patients.entries.toList();

        return DropdownButtonFormField<String>(
          initialValue: selectedPatientId,
          decoration: const InputDecoration(
            labelText: 'Patient',
            helperText: 'Sélectionnez le patient concerné',
          ),
          items: patientList
              .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ))
              .toList(),
          onChanged: (value) {
            final name = value != null ? patients[value] : null;
            onChanged(value, name);
          },
        );
      },
      loading: () => const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => TextFormField(
        initialValue: selectedPatientId,
        decoration: const InputDecoration(
          labelText: 'ID du patient (requis)',
          hintText: 'Entrez l\'UUID du patient',
          helperText: 'Requis pour les médecins et secrétaires',
          errorText: 'Impossible de charger la liste des patients',
        ),
        onChanged: (value) {
          onChanged(value.isEmpty ? null : value, null);
        },
      ),
    );
  }
}
