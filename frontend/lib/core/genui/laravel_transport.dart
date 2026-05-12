/// GenUI Transport Adapter — Proxy via Laravel Backend
/// La clé Gemini n'est JAMAIS exposée côté client.
/// Le backend Laravel gère l'authentification, le rate-limiting et le relay.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logger/logger.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Transport adapter qui envoie les messages au backend Laravel
/// qui fait le relay vers Gemini avec la clé API côté serveur.
class LaravelGenUITransport {
  final Dio _dio;
  final A2uiTransportAdapter _adapter;
  final List<Map<String, String>> _conversationHistory = [];
  bool _isSending = false;

  LaravelGenUITransport({required Dio dio})
      : _dio = dio,
        _adapter = A2uiTransportAdapter();

  /// L'adaptateur A2UI sous-jacent, à passer au Conversation.
  A2uiTransportAdapter get adapter => _adapter;

  /// Indique si un envoi est en cours
  bool get isSending => _isSending;

  /// Envoie un message utilisateur au backend Laravel qui fait le relay
  /// vers Gemini en streaming (SSE).
  Future<void> sendToLaravel({
    required String userMessage,
    required String systemPrompt,
    Map<String, dynamic>? patientContext,
  }) async {
    if (_isSending) return;
    _isSending = true;

    _conversationHistory.add({'role': 'user', 'content': userMessage});

    try {
      final response = await _dio.post<ResponseBody>(
        '/genui/stream',
        data: {
          'message': userMessage,
          'system_prompt': systemPrompt,
          'history': _conversationHistory.length > 20
              ? _conversationHistory.sublist(_conversationHistory.length - 20)
              : _conversationHistory,
          if (patientContext != null) 'context': patientContext,
        },
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        _isSending = false;
        return;
      }

      final buffer = StringBuffer();

      await for (final Uint8List chunk in stream) {
        final decoded = utf8.decode(chunk, allowMalformed: true);

        // Parse SSE format: "data: {...}\n\n"
        for (final line in decoded.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') continue;
            if (data.isEmpty) continue;

            buffer.write(data);
            _adapter.addChunk(data);
          }
        }
      }

      // Stocker la réponse complète dans l'historique
      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        _conversationHistory.add({
          'role': 'assistant',
          'content': fullResponse,
        });
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        _logger.e('GenUI Laravel transport error', error: e);
      }

      // Envoyer un message d'erreur lisible à l'UI
      final errorMessage = _friendlyError(e);
      _adapter.addChunk(
        '{"component":"AlertCard","data":{"message":"$errorMessage","severity":"error"}}',
      );
    } catch (e) {
      if (kDebugMode) {
        _logger.e('GenUI unexpected error', error: e);
      }
      _adapter.addChunk(
        '{"component":"AlertCard","data":{"message":"Une erreur inattendue est survenue.","severity":"error"}}',
      );
    } finally {
      _isSending = false;
    }
  }

  /// Réinitialise l'historique de conversation
  void clearHistory() => _conversationHistory.clear();

  /// Nombre de messages dans l'historique
  int get historyLength => _conversationHistory.length;

  /// Libère les ressources
  void dispose() {
    _adapter.dispose();
  }

  String _friendlyError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Le service IA ne répond pas. Réessayez dans quelques instants.';
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (statusCode == 429) {
      return 'Trop de requêtes. Veuillez patienter avant de réessayer.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Le serveur est temporairement indisponible.';
    }

    return 'Impossible de contacter le service IA.';
  }
}
