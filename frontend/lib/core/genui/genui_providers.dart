library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';

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
  final controller = GenUiSessionController(
    dio: dio,
    role: config.role,
  );

  ref.onDispose(controller.dispose);
  return controller;
});

class GenUiSessionController extends ChangeNotifier {
  final Dio _dio;
  final String _role;
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
  })  : _dio = dio,
        _role = role {
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
        if (text.trim().isNotEmpty) {
          _textFragments.add(text.trim());
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

  @override
  void dispose() {
    _isDisposed = true;
    _service.dispose();
    super.dispose();
  }
}
