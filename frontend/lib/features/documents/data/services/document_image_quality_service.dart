library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class DocumentImageQualityResult {
  final int width;
  final int height;
  final double brightness;
  final double contrast;
  final double sharpness;
  final double qualityScore;
  final List<String> warnings;

  const DocumentImageQualityResult({
    required this.width,
    required this.height,
    required this.brightness,
    required this.contrast,
    required this.sharpness,
    required this.qualityScore,
    this.warnings = const [],
  });

  bool get isGoodEnough => qualityScore >= 0.62 && warnings.length <= 1;
}

class DocumentImageQualityService {
  bool supports(File file) {
    final extension =
        path.extension(file.path).toLowerCase().replaceAll('.', '');
    return const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
  }

  Future<DocumentImageQualityResult?> analyze(File file) async {
    if (!supports(file)) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return const DocumentImageQualityResult(
        width: 0,
        height: 0,
        brightness: 0,
        contrast: 0,
        sharpness: 0,
        qualityScore: 0,
        warnings: ['Image illisible ou format non supporté.'],
      );
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width > 900 ? 900 : decoded.width,
    );
    final luminance = <double>[];
    final stepX = max(1, resized.width ~/ 160);
    final stepY = max(1, resized.height ~/ 160);

    for (var y = 0; y < resized.height; y += stepY) {
      for (var x = 0; x < resized.width; x += stepX) {
        final pixel = resized.getPixel(x, y);
        luminance.add(
          (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255,
        );
      }
    }

    final brightness = _average(luminance);
    final contrast = _standardDeviation(luminance, brightness).clamp(0, 1);
    final sharpness = _edgeSharpness(resized, stepX, stepY).clamp(0, 1);
    final resolutionScore = min(decoded.width, decoded.height) >= 900
        ? 1.0
        : (min(decoded.width, decoded.height) / 900).clamp(0.2, 1.0);
    final exposureScore = (1 - (brightness - 0.52).abs() * 2).clamp(0.0, 1.0);
    final qualityScore = (resolutionScore * 0.25 +
            exposureScore * 0.2 +
            contrast * 0.25 +
            sharpness * 0.3)
        .clamp(0.0, 1.0);

    final warnings = <String>[];
    if (min(decoded.width, decoded.height) < 900) {
      warnings.add(
          'Résolution faible: rapprochez le document ou utilisez une meilleure photo.');
    }
    if (brightness < 0.25) {
      warnings.add('Image trop sombre: ajoutez de la lumière.');
    } else if (brightness > 0.82) {
      warnings.add('Image trop claire: évitez les reflets et surexpositions.');
    }
    if (contrast < 0.16) {
      warnings.add('Contraste faible: placez le document sur un fond neutre.');
    }
    if (sharpness < 0.18) {
      warnings.add(
          'Image possiblement floue: stabilisez le téléphone et refaites la capture.');
    }

    return DocumentImageQualityResult(
      width: decoded.width,
      height: decoded.height,
      brightness: brightness,
      contrast: contrast.toDouble(),
      sharpness: sharpness.toDouble(),
      qualityScore: qualityScore.toDouble(),
      warnings: warnings,
    );
  }

  double _edgeSharpness(img.Image image, int stepX, int stepY) {
    final edges = <double>[];

    for (var y = stepY; y < image.height - stepY; y += stepY) {
      for (var x = stepX; x < image.width - stepX; x += stepX) {
        final center = _pixelLuminance(image.getPixel(x, y));
        final right = _pixelLuminance(image.getPixel(x + stepX, y));
        final bottom = _pixelLuminance(image.getPixel(x, y + stepY));
        edges.add(((center - right).abs() + (center - bottom).abs()) / 2);
      }
    }

    return (_average(edges) * 5).clamp(0, 1).toDouble();
  }

  double _pixelLuminance(img.Pixel pixel) {
    return (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255;
  }

  double _average(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    return values.reduce((a, b) => a + b) / values.length;
  }

  double _standardDeviation(List<double> values, double average) {
    if (values.isEmpty) {
      return 0;
    }

    final variance = values
            .map((value) => pow(value - average, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;

    return sqrt(variance);
  }
}

final documentImageQualityServiceProvider =
    Provider<DocumentImageQualityService>((ref) {
  return DocumentImageQualityService();
});
