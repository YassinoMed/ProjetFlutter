library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as path;

class MlkitOcrResult {
  final String rawText;
  final String normalizedText;
  final String engine;
  final String? languageCode;
  final double confidenceScore;
  final String? suggestedDocumentType;
  final String? suggestedTitle;
  final DateTime? suggestedDocumentDate;

  const MlkitOcrResult({
    required this.rawText,
    required this.normalizedText,
    required this.engine,
    this.languageCode,
    required this.confidenceScore,
    this.suggestedDocumentType,
    this.suggestedTitle,
    this.suggestedDocumentDate,
  });

  bool get hasReadableText => normalizedText.trim().length >= 12;
}

class MlkitDocumentOcrService {
  static const String engineName = 'flutter_mlkit_text_recognition';

  bool supports(File file) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    final extension =
        path.extension(file.path).toLowerCase().replaceAll('.', '');
    return const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
  }

  Future<MlkitOcrResult?> extract(File file) async {
    if (!supports(file)) {
      return null;
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFile(file),
      );
      final rawText = recognized.text.trim();
      final normalizedText = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (normalizedText.isEmpty) {
        return const MlkitOcrResult(
          rawText: '',
          normalizedText: '',
          engine: engineName,
          confidenceScore: 0,
        );
      }

      return MlkitOcrResult(
        rawText: rawText,
        normalizedText: normalizedText,
        engine: engineName,
        languageCode: _detectLanguage(normalizedText),
        confidenceScore: _estimateConfidence(normalizedText),
        suggestedDocumentType: _suggestDocumentType(normalizedText),
        suggestedTitle: _suggestTitle(normalizedText),
        suggestedDocumentDate: _extractDocumentDate(normalizedText),
      );
    } finally {
      await recognizer.close();
    }
  }

  String? _detectLanguage(String text) {
    final lower = text.toLowerCase();
    final frenchSignals = [
      'ordonnance',
      'médecin',
      'résultat',
      'laboratoire',
      'compte rendu',
      'certificat',
    ];

    if (frenchSignals.any(lower.contains)) {
      return 'fr';
    }

    return null;
  }

  double _estimateConfidence(String text) {
    final lengthScore = (text.length / 800).clamp(0.25, 0.85);
    final medicalSignalScore = _suggestDocumentType(text) == 'OTHER' ? 0 : 0.1;
    return (lengthScore + medicalSignalScore).clamp(0.25, 0.92).toDouble();
  }

  String _suggestDocumentType(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('ordonnance') || lower.contains('prescription')) {
      return 'PRESCRIPTION';
    }
    if (lower.contains('laboratoire') ||
        lower.contains('hba1c') ||
        lower.contains('glycémie') ||
        lower.contains('glycemie') ||
        lower.contains('crp') ||
        lower.contains('hémoglobine') ||
        lower.contains('hemoglobine')) {
      return 'LAB_RESULT';
    }
    if (lower.contains('radiologie') ||
        lower.contains('scanner') ||
        lower.contains('irm') ||
        lower.contains('radiographie')) {
      return 'RADIOLOGY_REPORT';
    }
    if (lower.contains('certificat')) {
      return 'MEDICAL_CERTIFICATE';
    }
    if (lower.contains('compte rendu') || lower.contains('observation')) {
      return 'MEDICAL_REPORT';
    }
    if (lower.contains('lettre') || lower.contains('adressé')) {
      return 'REFERRAL_LETTER';
    }

    return 'OTHER';
  }

  String _suggestTitle(String text) {
    final type = _suggestDocumentType(text);
    final date = _extractDocumentDate(text);
    final dateSuffix = date == null
        ? ''
        : ' ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return switch (type) {
      'PRESCRIPTION' => 'Ordonnance$dateSuffix',
      'LAB_RESULT' => 'Résultats biologiques$dateSuffix',
      'RADIOLOGY_REPORT' => 'Compte rendu radiologie$dateSuffix',
      'MEDICAL_CERTIFICATE' => 'Certificat médical$dateSuffix',
      'MEDICAL_REPORT' => 'Compte rendu médical$dateSuffix',
      'REFERRAL_LETTER' => 'Lettre médicale$dateSuffix',
      _ => 'Document médical$dateSuffix',
    };
  }

  DateTime? _extractDocumentDate(String text) {
    final match = RegExp(r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})\b')
        .firstMatch(text);

    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '');

    if (day == null || month == null || year == null) {
      return null;
    }

    if (year < 100) {
      year += 2000;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    return DateTime.utc(year, month, day);
  }
}

final mlkitDocumentOcrServiceProvider =
    Provider<MlkitDocumentOcrService>((ref) {
  return MlkitDocumentOcrService();
});
