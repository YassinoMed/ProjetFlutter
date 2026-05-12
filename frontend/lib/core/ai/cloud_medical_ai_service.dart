library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service IA appelant **directement** l'API Google Generative Language
/// depuis le client Flutter (aucun relay backend).
///
/// ⚠️ Sécurité: la clé Gemini est embarquée dans le binaire/bundle JS via
/// `--dart-define=GEMINI_API_KEY=...`. Sur Flutter Web, n'importe qui peut
/// l'extraire du bundle téléchargé. Restreindre la clé dans Google Cloud
/// Console (API restricted → generativelanguage.googleapis.com,
/// HTTP referrer / IP ranges) avant tout déploiement.
class CloudAiChatMessage {
  final String role;
  final String content;

  const CloudAiChatMessage({
    required this.role,
    required this.content,
  });

  factory CloudAiChatMessage.system(String content) {
    return CloudAiChatMessage(role: 'system', content: content);
  }

  factory CloudAiChatMessage.user(String content) {
    return CloudAiChatMessage(role: 'user', content: content);
  }

  factory CloudAiChatMessage.assistant(String content) {
    return CloudAiChatMessage(role: 'assistant', content: content);
  }
}

class CloudMedicalAiException implements Exception {
  final String message;

  const CloudMedicalAiException(this.message);

  @override
  String toString() => message;
}

class CloudMedicalAiService {
  static const maxTokens = 900;
  static const temperature = 0.7;

  /// Clé Gemini fournie au build via `--dart-define=GEMINI_API_KEY=...`.
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Modèle Gemini, surchargeable via `--dart-define=GEMINI_MODEL=...`.
  static const String _model =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta';

  static const documentSystemPrompt = '''
Tu es un assistant medical pour MediConnect Pro.
Analyse le texte OCR fourni par ML Kit (ou le document brut joint) sans inventer d'information.
Reponds en francais, de maniere concise et structuree.
Inclure: resume, points cliniques importants, valeurs ou traitements detectes, alertes/incertitudes, questions a verifier, action conseillee.
Ne pose jamais de diagnostic ferme et rappelle la validation medicale si necessaire.
''';

  static const chatSystemPrompt = '''
Tu es un assistant IA pour medecins dans MediConnect Pro.
Reponds en francais, aide a structurer la reflexion clinique, les messages patient, les bilans et les checklists.
Ne remplace pas le jugement medical. En cas de signe de gravite, conseille une evaluation urgente.
Sois clair, bref et actionnable.
''';

  final Dio _dio;

  const CloudMedicalAiService(this._dio);

  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  /// Analyse un document à partir d'un texte déjà extrait (ex: ML Kit OCR).
  Future<String> analyzeDocument({
    required String extractedText,
    String? title,
    String? documentType,
    String? filename,
  }) {
    final text = extractedText.trim();
    if (text.isEmpty) {
      throw const CloudMedicalAiException(
        'Aucun texte OCR exploitable a envoyer au modele Gemini.',
      );
    }

    final prompt = [
      documentSystemPrompt.trim(),
      if (title != null && title.trim().isNotEmpty) 'Titre: ${title.trim()}',
      if (documentType != null && documentType.trim().isNotEmpty)
        'Type suggere: ${documentType.trim()}',
      if (filename != null && filename.trim().isNotEmpty)
        'Fichier: ${filename.trim()}',
      'Texte OCR ML Kit:',
      text.length > 12000 ? text.substring(0, 12000) : text,
    ].join('\n\n');

    return _generate(parts: [
      {'text': prompt},
    ]);
  }

  /// Analyse un document à partir des **bytes** du fichier (PDF/image).
  /// Utilisé côté Web où ML Kit n'est pas disponible — Gemini lit le fichier
  /// directement via `inlineData`.
  Future<String> analyzeDocumentFile({
    required Uint8List bytes,
    required String mimeType,
    String? title,
    String? documentType,
    String? filename,
  }) {
    if (bytes.isEmpty) {
      throw const CloudMedicalAiException('Fichier vide.');
    }

    // Limite raisonnable côté client (Gemini accepte ~20 Mo inline).
    if (bytes.length > 18 * 1024 * 1024) {
      throw const CloudMedicalAiException(
        'Document trop volumineux pour l\'analyse en ligne (>18 Mo). '
        'Ré-essayez avec une version compressée.',
      );
    }

    final instructions = [
      documentSystemPrompt.trim(),
      if (title != null && title.trim().isNotEmpty) 'Titre: ${title.trim()}',
      if (documentType != null && documentType.trim().isNotEmpty)
        'Type suggere: ${documentType.trim()}',
      if (filename != null && filename.trim().isNotEmpty)
        'Fichier: ${filename.trim()}',
      'Analyse le document joint et retourne ta synthese clinique.',
    ].join('\n\n');

    return _generate(parts: [
      {'text': instructions},
      {
        'inline_data': {
          'mime_type': mimeType,
          'data': base64Encode(bytes),
        }
      },
    ]);
  }

  Future<String> chat({
    required List<CloudAiChatMessage> messages,
  }) {
    final cleaned = messages
        .where((message) => message.content.trim().isNotEmpty)
        .map(
          (message) => CloudAiChatMessage(
            role: message.role,
            content: message.content.trim(),
          ),
        )
        .toList(growable: false);

    if (cleaned.isEmpty) {
      throw const CloudMedicalAiException('Message vide.');
    }

    final transcript = cleaned
        .map((message) => '${_roleLabel(message.role)}: ${message.content}')
        .join('\n\n');

    final prompt = [
      chatSystemPrompt.trim(),
      'Conversation recente:',
      transcript,
      'Reponds au dernier message utilisateur.',
    ].join('\n\n');

    return _generate(parts: [
      {'text': prompt},
    ]);
  }

  // ── HTTP ───────────────────────────────────────────────────

  Future<String> _generate({required List<Map<String, dynamic>> parts}) async {
    if (!hasApiKey) {
      throw const CloudMedicalAiException(
        'Clé Gemini absente. Lancez l\'app avec '
        '--dart-define=GEMINI_API_KEY=<votre-clé>.',
      );
    }

    const url = '$_apiBase/models/$_model:generateContent?key=$_apiKey';

    try {
      final response = await _dio.post<dynamic>(
        url,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': parts,
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
          headers: const {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw CloudMedicalAiException(
          _extractProviderError(response.data) ??
              'Erreur Gemini HTTP $statusCode.',
        );
      }

      final text = _extractCandidateText(response.data);
      if (text == null || text.trim().isEmpty) {
        throw const CloudMedicalAiException(
          'Gemini a retourne une reponse vide ou illisible.',
        );
      }

      return _cleanModelText(text);
    } on DioException catch (error) {
      throw CloudMedicalAiException(friendlyError(error));
    }
  }

  static String friendlyError(Object error) {
    if (error is CloudMedicalAiException) {
      return normalizeLegacyCloudText(error.message);
    }

    if (error is DioException) {
      final providerMessage = _extractProviderError(error.response?.data);
      if (providerMessage != null) {
        return normalizeLegacyCloudText(providerMessage);
      }

      final message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return normalizeLegacyCloudText(message.trim());
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Gemini ne repond pas pour le moment.';
      }
    }

    return normalizeLegacyCloudText(
      'Le service Gemini est indisponible pour le moment.',
    );
  }

  static String normalizeLegacyCloudText(String value) {
    return value
        .replaceAll(
          'Impossible de contacter le modele cloud pour le moment.',
          'Impossible de contacter Gemini pour le moment.',
        )
        .replaceAll(
          'Impossible de contacter le modèle cloud pour le moment.',
          'Impossible de contacter Gemini pour le moment.',
        )
        .replaceAll(
          'Le modele cloud est indisponible pour le moment.',
          'Le service Gemini est indisponible pour le moment.',
        )
        .replaceAll(
          'Le modèle cloud est indisponible pour le moment.',
          'Le service Gemini est indisponible pour le moment.',
        )
        .replaceAll('modele cloud', 'service Gemini')
        .replaceAll('modèle cloud', 'service Gemini');
  }

  static String _roleLabel(String role) {
    return switch (role) {
      'system' => 'Consignes systeme',
      'assistant' => 'Assistant',
      _ => 'Utilisateur',
    };
  }

  /// Extrait le texte de la première candidate Gemini.
  /// Format attendu: data.candidates[0].content.parts[*].text
  static String? _extractCandidateText(dynamic data) {
    if (data is! Map) return null;

    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final first = candidates.first;
    if (first is! Map) return null;

    final content = first['content'];
    if (content is! Map) return null;

    final parts = content['parts'];
    if (parts is! List) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(part['text']);
      }
    }
    final text = buffer.toString();
    return text.isEmpty ? null : text;
  }

  static String? _extractProviderError(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      return data.trim().isEmpty ? null : data.trim();
    }

    if (data is Map) {
      // Format Google: {"error": {"message": "...", "status": "..."}}
      final error = data['error'];
      if (error is Map) {
        final msg = error['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
      final directMessage = data['message'];
      if (directMessage is String && directMessage.trim().isNotEmpty) {
        return directMessage.trim();
      }
    }

    return null;
  }

  static String _cleanModelText(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        .replaceAll(
            RegExp(r'```(?:json|markdown|md)?', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is String) {
          cleaned = decoded.trim();
        }
      } catch (_) {
        // Keep the original cleaned text when it is not a JSON string.
      }
    }

    return cleaned;
  }
}

final cloudMedicalAiServiceProvider = Provider<CloudMedicalAiService>((ref) {
  return CloudMedicalAiService(_createGeminiDio());
});

Dio _createGeminiDio() {
  // Dio brut: aucun interceptor d'auth ni base URL — on appelle Google direct.
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 60),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 600,
    ),
  );
}
