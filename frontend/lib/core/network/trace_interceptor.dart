/// Distributed Tracing Interceptor for Dio
/// Implements W3C Trace Context propagation.
///
/// Automatically injects `traceparent` headers on every HTTP request,
/// enabling end-to-end trace correlation with the backend's
/// TraceRequestMiddleware.
library;

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

class TraceInterceptor extends Interceptor {
  /// Current trace ID (persists across requests in the same "session")
  String? _currentTraceId;

  TraceInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate or reuse trace context
    _currentTraceId ??= _generateHexId(32);
    final spanId = _generateHexId(16);

    // W3C traceparent format: version-traceId-spanId-flags
    final traceparent = '00-$_currentTraceId-$spanId-01';

    options.headers['traceparent'] = traceparent;
    options.headers['X-Trace-Id'] = _currentTraceId;
    options.headers['X-Span-Id'] = spanId;

    // Record start time for duration logging
    options.extra['_trace_start'] = DateTime.now().millisecondsSinceEpoch;
    options.extra['_trace_span_id'] = spanId;

    if (kDebugMode) {
      _logger.d('[TRACE] → ${options.method} ${options.path} '
          '| trace=$_currentTraceId span=$spanId');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logSpan(response.requestOptions, response.statusCode, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logSpan(err.requestOptions, err.response?.statusCode, err.message);
    handler.next(err);
  }

  void _logSpan(RequestOptions options, int? statusCode, String? error) {
    final startMs = options.extra['_trace_start'] as int?;
    final spanId = options.extra['_trace_span_id'] as String?;

    if (startMs == null) return;

    final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;

    if (kDebugMode) {
      final status = statusCode != null ? '$statusCode' : 'ERR';
      final errSuffix = error != null ? ' | $error' : '';
      _logger.d('[TRACE] ← $status ${options.method} ${options.path} '
          '| ${durationMs}ms | span=$spanId$errSuffix');
    }

    // Log slow requests as warnings
    if (durationMs > 2000) {
      _logger.w('[TRACE] ⚠ Slow request: ${options.method} ${options.path} '
          '| ${durationMs}ms');
    }
  }

  /// Reset trace ID (call this on logout or new session).
  void resetTrace() {
    _currentTraceId = null;
  }

  String _generateHexId(int length) {
    final rng = Random.secure();
    return List.generate(
      length ~/ 2,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
