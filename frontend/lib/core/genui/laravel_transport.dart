/// GenUI Transport Adapter
///
/// Deux modes (transparents pour l'appelant):
///   1) Direct Gemini  — si une clé est configurée dans GeminiKeyStorage
///      (saisie utilisateur via Profil > Préférences > Clé API Gemini).
///      Le client appelle generativelanguage.googleapis.com directement.
///   2) Fallback backend — si pas de clé locale, on POSTe vers
///      `/genui/stream` côté Laravel (configuration historique).
///
/// Le mode direct est plus robuste pour la démo et pour les setups où le
/// backend n'a pas (encore) sa propre clé Gemini.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logger/logger.dart';

import '../ai/gemini_key_storage.dart';
import '../constants/api_constants.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Transport adapter qui envoie les messages au backend Laravel
/// qui fait le relay vers Gemini avec la clé API côté serveur.
class LaravelGenUITransport {
  static const String _geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');
  static const String _geminiBase =
      'https://generativelanguage.googleapis.com/v1beta';

  final Dio _dio;
  // Dio dédié aux appels Gemini direct (pas d'auth interceptor, pas de
  // base URL backend). Réutilise les mêmes timeouts SSE-friendly.
  final Dio _directDio;
  final A2uiTransportAdapter _adapter;
  final String Function() _systemPromptProvider;
  final GeminiKeyStorage? _keyStorage;
  final List<Map<String, String>> _conversationHistory = [];
  final _sseBuffer = StringBuffer();

  Map<String, dynamic>? _nextContext;
  String? _nextCacheKey;
  bool _nextUseCache = false;
  bool _isSending = false;

  LaravelGenUITransport({
    required Dio dio,
    required String Function() systemPromptProvider,
    GeminiKeyStorage? keyStorage,
  })  : _dio = dio,
        _directDio = _createDirectDio(),
        _systemPromptProvider = systemPromptProvider,
        _keyStorage = keyStorage,
        _adapter = A2uiTransportAdapter();

  LaravelGenUITransport._withAdapter({
    required Dio dio,
    required String Function() systemPromptProvider,
    required A2uiTransportAdapter adapter,
    GeminiKeyStorage? keyStorage,
  })  : _dio = dio,
        _directDio = _createDirectDio(),
        _systemPromptProvider = systemPromptProvider,
        _keyStorage = keyStorage,
        _adapter = adapter;

  factory LaravelGenUITransport.withConversationAdapter({
    required Dio dio,
    required String Function() systemPromptProvider,
    GeminiKeyStorage? keyStorage,
  }) {
    late LaravelGenUITransport transport;
    final adapter = A2uiTransportAdapter(
      onSend: (message) => transport._sendChatMessage(message),
    );

    transport = LaravelGenUITransport._withAdapter(
      dio: dio,
      systemPromptProvider: systemPromptProvider,
      adapter: adapter,
      keyStorage: keyStorage,
    );

    return transport;
  }

  static Dio _createDirectDio() {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'text/event-stream',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 600,
    ));
  }

  /// L'adaptateur A2UI sous-jacent, à passer au Conversation.
  A2uiTransportAdapter get adapter => _adapter;

  /// Indique si un envoi est en cours
  bool get isSending => _isSending;

  void configureNextRequest({
    Map<String, dynamic>? context,
    String? cacheKey,
    bool useCache = false,
  }) {
    _nextContext = context;
    _nextCacheKey = cacheKey;
    _nextUseCache = useCache;
  }

  Future<void> _sendChatMessage(ChatMessage message) {
    final userMessage = _messageContent(message);
    final context = _nextContext;
    final cacheKey = _nextCacheKey;
    final useCache = _nextUseCache;

    _nextContext = null;
    _nextCacheKey = null;
    _nextUseCache = false;

    return sendToLaravel(
      userMessage: userMessage,
      systemPrompt: _systemPromptProvider(),
      patientContext: context,
      cacheKey: cacheKey,
      useCache: useCache,
    );
  }

  /// Envoie un message utilisateur au backend Laravel qui fait le relay
  /// vers Gemini en streaming (SSE).
  Future<void> sendToLaravel({
    required String userMessage,
    required String systemPrompt,
    Map<String, dynamic>? patientContext,
    String? cacheKey,
    bool useCache = false,
  }) async {
    if (_isSending) return;
    _isSending = true;

    final normalizedMessage = userMessage.trim().isEmpty
        ? 'Interaction utilisateur GenUI'
        : userMessage.trim();
    final effectiveCacheKey = useCache
        ? cacheKey ?? _cacheKey(normalizedMessage, systemPrompt, patientContext)
        : null;

    _conversationHistory.add({'role': 'user', 'content': normalizedMessage});

    try {
      final cachedResponse = effectiveCacheKey == null
          ? null
          : _GenUiResponseCache.instance.get(effectiveCacheKey);
      if (cachedResponse != null) {
        _adapter.addChunk(cachedResponse);
        _conversationHistory.add({
          'role': 'assistant',
          'content': cachedResponse,
        });
        return;
      }

      // Branche direct Gemini si une clé est configurée localement.
      // Sinon fallback historique vers le backend Laravel.
      final localKey = await _keyStorage?.getApiKey() ?? '';
      final Response<ResponseBody> response;
      if (localKey.isNotEmpty) {
        response = await _directDio.post<ResponseBody>(
          '$_geminiBase/models/$_geminiModel:streamGenerateContent'
          '?alt=sse&key=$localKey',
          data: _buildGeminiRequestBody(
            userMessage: normalizedMessage,
            systemPrompt: systemPrompt,
            patientContext: patientContext,
          ),
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(seconds: 120),
            sendTimeout: const Duration(seconds: 30),
            headers: const {
              'Accept': 'text/event-stream',
              'Content-Type': 'application/json',
            },
          ),
        );
      } else {
        response = await _dio.post<ResponseBody>(
          ApiConstants.genuiStream,
          data: {
            'message': normalizedMessage,
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
      }

      final stream = response.data?.stream;
      if (stream == null) {
        _isSending = false;
        return;
      }

      final buffer = StringBuffer();
      _sseBuffer.clear();

      await for (final Uint8List chunk in stream) {
        final decoded = utf8.decode(chunk, allowMalformed: true);
        final pieces = _extractSsePayloads(decoded);

        for (final data in pieces) {
          if (data == '[DONE]' || data.isEmpty) continue;

          final text = _extractTextPayload(data);
          if (text.isEmpty) continue;

          buffer.write(text);
          _adapter.addChunk(text);
        }
      }

      final trailing = _flushSseBuffer();
      for (final data in trailing) {
        final text = _extractTextPayload(data);
        if (text.isEmpty) continue;
        buffer.write(text);
        _adapter.addChunk(text);
      }

      // Stocker la réponse complète dans l'historique
      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        _conversationHistory.add({
          'role': 'assistant',
          'content': fullResponse,
        });
        if (effectiveCacheKey != null) {
          _GenUiResponseCache.instance.put(effectiveCacheKey, fullResponse);
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        _logger.e('GenUI Laravel transport error', error: e);
      }

      // Envoyer un message d'erreur lisible à l'UI
      final errorMessage = _friendlyError(e);
      _adapter.addChunk(_alertA2uiMessage(errorMessage));
    } catch (e) {
      if (kDebugMode) {
        _logger.e('GenUI unexpected error', error: e);
      }
      _adapter.addChunk(
        _alertA2uiMessage('Une erreur inattendue est survenue.'),
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

  String _messageContent(ChatMessage message) {
    final text = message.text.trim();
    if (text.isNotEmpty) return text;

    return jsonEncode(message.toJson());
  }

  List<String> _extractSsePayloads(String text) {
    _sseBuffer.write(text);
    final payloads = <String>[];
    var pending = _sseBuffer.toString().replaceAll('\r\n', '\n');

    while (true) {
      final separatorIndex = pending.indexOf('\n\n');
      if (separatorIndex == -1) break;

      final event = pending.substring(0, separatorIndex);
      pending = pending.substring(separatorIndex + 2);

      final payload = _decodeSseEvent(event);
      if (payload != null) payloads.add(payload);
    }

    _sseBuffer
      ..clear()
      ..write(pending);
    return payloads;
  }

  List<String> _flushSseBuffer() {
    final pending = _sseBuffer.toString().trim();
    _sseBuffer.clear();
    if (pending.isEmpty) return const [];
    final payload = _decodeSseEvent(pending);
    return payload == null ? const [] : [payload];
  }

  String? _decodeSseEvent(String event) {
    final dataLines = <String>[];
    for (final rawLine in event.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trimRight();
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    if (dataLines.isEmpty) return null;
    return dataLines.join('\n');
  }

  String _extractTextPayload(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        // Erreur Gemini standard: { "error": { "message": "..." } }
        final error = decoded['error'];
        if (error is Map) {
          final msg = error['message'];
          if (msg is String && msg.trim().isNotEmpty) {
            return _alertA2uiMessage(msg.trim());
          }
        }
        if (error is String && error.trim().isNotEmpty) {
          return _alertA2uiMessage(error.trim());
        }

        // Format Gemini streamGenerateContent:
        // {"candidates":[{"content":{"parts":[{"text":"..."}]}}]}
        final candidates = decoded['candidates'];
        if (candidates is List && candidates.isNotEmpty) {
          final first = candidates.first;
          if (first is Map) {
            final content = first['content'];
            if (content is Map) {
              final parts = content['parts'];
              if (parts is List) {
                final buffer = StringBuffer();
                for (final part in parts) {
                  if (part is Map && part['text'] is String) {
                    buffer.write(part['text']);
                  }
                }
                if (buffer.isNotEmpty) {
                  return _rewriteCatalogIds(buffer.toString());
                }
              }
            }
          }
        }

        // Format backend historique (proxy LLM chunks).
        for (final key in const ['text', 'delta', 'content']) {
          final value = decoded[key];
          if (value is String) return _rewriteCatalogIds(value);
        }
      }
    } catch (_) {
      // Plain SSE data is valid: the backend may proxy raw LLM chunks.
    }

    return _rewriteCatalogIds(data);
  }

  /// Remplace les références à des catalogues A2UI standards externes (que
  /// le LLM injecte spontanément malgré le system prompt) par notre
  /// catalogue local enregistré dans le [SurfaceController]. Sans cette
  /// réécriture, le SurfaceController lève
  /// `Catalog with id "https://a2ui.org/..." not found` lors du rendu.
  ///
  /// On gère les deux conventions JSON (clé entre quotes simples ou
  /// doubles) ainsi que la variante `catalog_id`.
  static final RegExp _externalCatalogId = RegExp(
    r'("catalogId"|"catalog_id"|\\"catalogId\\"|\\"catalog_id\\")\s*:\s*\\?"https?://[^"\\]*a2ui[^"\\]*"',
  );
  static const String _localCatalogId = '"com.mediconnect.catalog"';

  String _rewriteCatalogIds(String input) {
    if (!input.contains('a2ui')) return input;
    return input.replaceAllMapped(_externalCatalogId, (m) {
      final keyToken = m.group(1) ?? '"catalogId"';
      return '$keyToken: $_localCatalogId';
    });
  }

  /// Construit le payload Gemini direct (streamGenerateContent).
  /// L'historique de conversation est mappé vers le format `contents`,
  /// le prompt système vers `systemInstruction`, et le contexte patient
  /// est injecté comme premier message utilisateur.
  Map<String, dynamic> _buildGeminiRequestBody({
    required String userMessage,
    required String systemPrompt,
    Map<String, dynamic>? patientContext,
  }) {
    final contents = <Map<String, dynamic>>[];

    // Historique borné aux 20 derniers échanges (économie tokens + latence).
    final recentHistory = _conversationHistory.length > 20
        ? _conversationHistory.sublist(_conversationHistory.length - 20)
        : _conversationHistory;

    for (final msg in recentHistory) {
      final role = msg['role'] == 'assistant' ? 'model' : 'user';
      final content = msg['content']?.trim() ?? '';
      if (content.isEmpty) continue;
      contents.add({
        'role': role,
        'parts': [
          {'text': content}
        ],
      });
    }

    // Le dernier message est déjà dans _conversationHistory (ajouté plus haut
    // par sendToLaravel). On le re-trace pas, contents[-1] est userMessage.

    // Si on a un contexte patient, on l'ajoute en preamble user message.
    if (patientContext != null && patientContext.isNotEmpty) {
      contents.insert(0, {
        'role': 'user',
        'parts': [
          {
            'text': 'Contexte patient JSON (référence): '
                '${jsonEncode(patientContext)}',
          }
        ],
      });
      contents.insert(1, {
        'role': 'model',
        'parts': [
          {'text': 'Compris, j\'utiliserai ce contexte.'}
        ],
      });
    }

    return {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };
  }

  String _cacheKey(
    String message,
    String systemPrompt,
    Map<String, dynamic>? context,
  ) {
    final contextText = context == null ? '' : jsonEncode(_sortedJson(context));
    return '$message\n---system---\n$systemPrompt\n---context---\n$contextText';
  }

  Object? _sortedJson(Object? value) {
    if (value is Map) {
      return SplayTreeMap<String, Object?>.from(
        value.map((key, item) => MapEntry(key.toString(), _sortedJson(item))),
      );
    }

    if (value is List) {
      return value.map(_sortedJson).toList(growable: false);
    }

    return value;
  }

  String _alertA2uiMessage(String message) {
    final surfaceId = 'genui_error_${DateTime.now().millisecondsSinceEpoch}';
    return [
      '```json',
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': surfaceId,
          'catalogId': 'com.mediconnect.catalog',
          'sendDataModel': false,
        },
      }),
      '```',
      '```json',
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': [
            {
              'id': 'root',
              'component': 'AlertCard',
              'title': 'Assistant indisponible',
              'message': message,
              'severity': 'error',
            },
          ],
        },
      }),
      '```',
    ].join('\n');
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

class _GenUiResponseCache {
  _GenUiResponseCache._();

  static final instance = _GenUiResponseCache._();
  static const _maxEntries = 24;
  static const _ttl = Duration(minutes: 10);

  final _entries = <String, _CachedGenUiResponse>{};

  String? get(String key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;

    if (DateTime.now().difference(entry.createdAt) > _ttl) {
      return null;
    }

    _entries[key] = entry;
    return entry.content;
  }

  void put(String key, String content) {
    if (content.trim().isEmpty) return;

    _entries[key] = _CachedGenUiResponse(content, DateTime.now());
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}

class _CachedGenUiResponse {
  const _CachedGenUiResponse(this.content, this.createdAt);

  final String content;
  final DateTime createdAt;
}
