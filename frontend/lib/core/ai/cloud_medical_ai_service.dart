library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

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

  static const documentSystemPrompt = '''
Tu es un assistant medical pour MediConnect Pro.
Analyse le texte OCR fourni par ML Kit sans inventer d'information.
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

    return _postPrompt(prompt);
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

    return _postPrompt(prompt);
  }

  Future<String> _postPrompt(String prompt) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.geminiChat,
        data: {
          'prompt': prompt,
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
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

      final text = _extractResponseText(response.data);
      if (text == null || text.trim().isEmpty) {
        throw const CloudMedicalAiException(
          'Gemini a retourne une reponse vide ou illisible.',
        );
      }

      return text.trim();
    } on DioException catch (error) {
      throw CloudMedicalAiException(friendlyError(error));
    }
  }

  static String friendlyError(Object error) {
    if (error is CloudMedicalAiException) {
      return error.message;
    }

    if (error is DioException) {
      final providerMessage = _extractProviderError(error.response?.data);
      if (providerMessage != null) {
        return providerMessage;
      }

      final message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Gemini ne repond pas pour le moment.';
      }
    }

    return 'Le service Gemini est indisponible pour le moment.';
  }

  static String _roleLabel(String role) {
    return switch (role) {
      'system' => 'Consignes systeme',
      'assistant' => 'Assistant',
      _ => 'Utilisateur',
    };
  }

  static String? _extractResponseText(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is String) {
      return _cleanModelText(data);
    }

    if (data is List) {
      for (final item in data) {
        final text = _extractResponseText(item);
        if (text != null && text.trim().isNotEmpty) {
          return text;
        }
      }

      return const JsonEncoder.withIndent('  ').convert(data);
    }

    if (data is Map) {
      const paths = [
        ['data', 'content'],
        ['data', 'data', 'content'],
        ['data', 'text'],
        ['content'],
        ['answer'],
        ['response'],
        ['output'],
        ['result'],
        ['generated_text'],
        ['text'],
        ['message'],
      ];

      for (final path in paths) {
        final text = _extractResponseText(_valueAt(data, path));
        if (text != null && text.trim().isNotEmpty) {
          return text;
        }
      }

      return const JsonEncoder.withIndent('  ').convert(data);
    }

    return data.toString();
  }

  static Object? _valueAt(dynamic value, List<String> path) {
    var current = value;

    for (final segment in path) {
      if (current is Map) {
        current = current[segment];
      } else {
        return null;
      }
    }

    return current;
  }

  static String? _extractProviderError(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is String) {
      return data.trim().isEmpty ? null : data.trim();
    }

    if (data is Map) {
      final directMessage = _stringAt(data, const ['message']) ??
          _stringAt(data, const ['error', 'message']) ??
          _stringAt(data, const ['error']);

      if (directMessage != null && directMessage.trim().isNotEmpty) {
        return directMessage.trim();
      }
    }

    return null;
  }

  static String? _stringAt(Map data, List<String> path) {
    final value = _valueAt(data, path);
    return value is String ? value : null;
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
  return CloudMedicalAiService(ref.watch(dioProvider));
});
