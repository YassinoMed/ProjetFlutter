library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';

import '../ai/gemini_key_storage.dart';
import '../network/dio_client.dart';
import 'genui_service.dart';

class GenUiSessionConfig {
  final String sessionId;
  final String role;

  const GenUiSessionConfig({
    required this.sessionId,
    required this.role,
  });

  @override
  bool operator ==(Object other) {
    return other is GenUiSessionConfig &&
        other.sessionId == sessionId &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(sessionId, role);
}

final genUiSessionProvider = ChangeNotifierProvider.autoDispose
    .family<GenUiSessionController, GenUiSessionConfig>((ref, config) {
  final dio = ref.watch(dioProvider);
  final keyStorage = ref.watch(geminiKeyStorageProvider);
  final controller = GenUiSessionController(
    dio: dio,
    role: config.role,
    keyStorage: keyStorage,
  );

  ref.onDispose(controller.dispose);
  return controller;
});

class GenUiSessionController extends ChangeNotifier {
  final Dio _dio;
  final String _role;
  final GeminiKeyStorage? _keyStorage;
  late GenUIService _service;

  final List<String> _surfaceIds = [];
  final List<String> _textFragments = [];

  bool _isDisposed = false;
  bool _isLoading = false;
  bool _hasRequested = false;
  String? _error;

  GenUiSessionController({
    required Dio dio,
    required String role,
    GeminiKeyStorage? keyStorage,
  })  : _dio = dio,
        _role = role,
        _keyStorage = keyStorage {
    _createService();
  }

  List<String> get surfaceIds => List.unmodifiable(_surfaceIds);
  String get generatedText => _textFragments.join('\n').trim();
  String? get error => _error;
  bool get isLoading => _isLoading || _service.isSending;
  bool get hasRequested => _hasRequested;
  bool get hasContent => _surfaceIds.isNotEmpty || generatedText.isNotEmpty;
  SurfaceController get surfaceController => _service.surfaceController;

  Future<void> generate({
    required String prompt,
    Map<String, dynamic>? context,
    bool useCache = false,
    String? cacheKey,
    bool force = false,
  }) async {
    if (prompt.trim().isEmpty) return;
    if (!force && _hasRequested) return;
    if (isLoading) return;

    _hasRequested = true;
    _isLoading = true;
    _error = null;
    _notify();

    try {
      await _service.sendMessage(
        prompt,
        patientContext: context,
        useCache: useCache,
        cacheKey: cacheKey,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> regenerate({
    required String prompt,
    Map<String, dynamic>? context,
    bool useCache = false,
    String? cacheKey,
  }) async {
    reset();
    await generate(
      prompt: prompt,
      context: context,
      useCache: useCache,
      cacheKey: cacheKey,
      force: true,
    );
  }

  void reset() {
    _service.dispose();
    _surfaceIds.clear();
    _textFragments.clear();
    _error = null;
    _isLoading = false;
    _hasRequested = false;
    _createService();
    _notify();
  }

  void _createService() {
    _service = GenUIService(
      dio: _dio,
      role: _role,
      keyStorage: _keyStorage,
      onSurfaceAdded: (surfaceId) {
        if (!_surfaceIds.contains(surfaceId)) {
          _surfaceIds.add(surfaceId);
          _notify();
        }
      },
      onSurfaceRemoved: (surfaceId) {
        _surfaceIds.remove(surfaceId);
        _notify();
      },
      onTextReceived: (text) {
        // En streaming direct Gemini, le texte conversationnel et les blocs
        // ```json``` (consommés par le SurfaceController pour rendre les
        // widgets dynamiques) sont entrelacés dans la même réponse. On les
        // strippe ici pour n'afficher dans le chat que la prose lisible.
        final cleaned = _stripGenUiFences(text);
        if (cleaned.isNotEmpty) {
          _textFragments.add(cleaned);
          _notify();
        }
      },
      onWaitingChanged: (waiting) {
        _isLoading = waiting;
        _notify();
      },
      onError: (error) {
        _error = error;
        _isLoading = false;
        _notify();
      },
    );
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Retire les blocs de code Markdown (```json … ```), les fences ouvertes
  /// non encore refermées pendant le streaming, et normalise les retours à
  /// la ligne pour n'afficher dans le chat que la prose lisible.
  ///
  /// Gemini renvoie des morceaux qui peuvent contenir partiellement un bloc
  /// JSON : on les filtre de façon idempotente pour éviter le flash de
  /// markup brut côté UI.
  static final RegExp _fencedBlock =
      RegExp(r'```[a-zA-Z0-9_-]*\s*[\s\S]*?```', multiLine: true);
  static final RegExp _danglingOpenFence =
      RegExp(r'```[a-zA-Z0-9_-]*\s*[\s\S]*$', multiLine: true);

  static String _stripGenUiFences(String text) {
    if (text.isEmpty) return '';
    var cleaned = text.replaceAll(_fencedBlock, '');
    // Élimine les fences ouvertes en fin de chunk (streaming partiel).
    cleaned = cleaned.replaceAll(_danglingOpenFence, '');
    // Compacte les sauts de ligne multiples laissés par le strip.
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return cleaned;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _service.dispose();
    super.dispose();
  }
}
