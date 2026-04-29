library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/document_image_quality_service.dart';
import '../../data/services/mlkit_document_ocr_service.dart';
import '../providers/document_providers.dart';

class DocumentUploadPage extends ConsumerStatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  ConsumerState<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends ConsumerState<DocumentUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  File? _selectedFile;
  String? _documentType;
  DateTime? _documentDate;
  MlkitOcrResult? _localOcr;
  DocumentImageQualityResult? _imageQuality;
  String? _ocrError;
  String? _qualityError;
  bool _isOcrRunning = false;
  bool _isQualityRunning = false;
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
                      _selectedFile?.path.split('/').last ??
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
                onRetry: _selectedFile == null ? null : _runLocalOcr,
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
    );

    if (result?.files.single.path != null) {
      final file = File(result!.files.single.path!);
      setState(() {
        _selectedFile = file;
        _localOcr = null;
        _imageQuality = null;
        _ocrError = null;
        _qualityError = null;
      });

      await Future.wait([
        _runImageQualityCheck(),
        _runLocalOcr(),
      ]);
    }
  }

  Future<void> _runImageQualityCheck() async {
    final file = _selectedFile;
    if (file == null) {
      return;
    }

    final qualityService = ref.read(documentImageQualityServiceProvider);
    if (!qualityService.supports(file)) {
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
      final result = await qualityService.analyze(file);

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
    if (!ocrService.supports(file)) {
      setState(() {
        _localOcr = null;
        _ocrError =
            'OCR local disponible seulement pour les images JPG, PNG ou WEBP sur mobile.';
      });
      return;
    }

    setState(() {
      _isOcrRunning = true;
      _ocrError = null;
    });

    try {
      final result = await ocrService.extract(file);

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final document = await ref.read(documentActionsProvider).upload(
            file: _selectedFile!,
            title: _titleController.text.trim(),
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
