import 'package:dio/dio.dart';

class ResponseCacheInterceptor extends Interceptor {
  final Map<String, _CachedResponse> _cache = <String, _CachedResponse>{};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final cacheKey = _cacheKeyFor(options);
    if (cacheKey == null) {
      handler.next(options);
      return;
    }

    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: cached.statusCode,
          data: cached.data,
          headers: cached.headers,
        ),
      );
      return;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final cacheKey = _cacheKeyFor(response.requestOptions);
    if (cacheKey != null && response.statusCode == 200) {
      _cache[cacheKey] = _CachedResponse(
        data: response.data,
        statusCode: response.statusCode ?? 200,
        headers: response.headers,
        expiresAt: DateTime.now().add(_ttlFor(response.requestOptions.path)!),
      );
    }

    if (_isMutation(response.requestOptions.method)) {
      _invalidateForPath(response.requestOptions.path);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final cacheKey = _cacheKeyFor(err.requestOptions);
    final cached = cacheKey == null ? null : _cache[cacheKey];
    final isRecoverable = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (isRecoverable && cached != null) {
      handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          statusCode: cached.statusCode,
          data: cached.data,
          headers: cached.headers,
        ),
      );
      return;
    }

    handler.next(err);
  }

  void clearAll() {
    _cache.clear();
  }

  String? _cacheKeyFor(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') {
      return null;
    }

    final ttl = _ttlFor(options.path);
    final authHeader = options.headers['Authorization']?.toString();
    if (ttl == null || authHeader == null || authHeader.isEmpty) {
      return null;
    }

    return '${options.method}|${options.path}|${options.queryParameters}|$authHeader';
  }

  Duration? _ttlFor(String path) {
    if (path.contains('/consultations/') && path.contains('/messages')) {
      return const Duration(seconds: 5);
    }

    if (path.contains('/appointments')) {
      return const Duration(seconds: 20);
    }

    if (path.contains('/teleconsultations')) {
      return const Duration(seconds: 10);
    }

    if (path.contains('/documents')) {
      return const Duration(seconds: 20);
    }

    if (path.contains('/doctors')) {
      return const Duration(minutes: 5);
    }

    return null;
  }

  bool _isMutation(String method) {
    return switch (method.toUpperCase()) {
      'POST' || 'PUT' || 'PATCH' || 'DELETE' => true,
      _ => false,
    };
  }

  void _invalidateForPath(String path) {
    if (path.contains('/auth/')) {
      clearAll();
      return;
    }

    final prefixes = <String>[];

    if (path.contains('/appointments')) {
      prefixes.add('/appointments');
      prefixes.add('/teleconsultations');
    }

    if (path.contains('/consultations/')) {
      prefixes.add('/consultations/');
      prefixes.add('/appointments');
    }

    if (path.contains('/documents')) {
      prefixes.add('/documents');
    }

    if (path.contains('/teleconsultations')) {
      prefixes.add('/teleconsultations');
      prefixes.add('/appointments');
    }

    if (prefixes.isEmpty) {
      return;
    }

    _cache.removeWhere((key, _) => prefixes.any(key.contains));
  }
}

class _CachedResponse {
  final dynamic data;
  final int statusCode;
  final Headers headers;
  final DateTime expiresAt;

  const _CachedResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
