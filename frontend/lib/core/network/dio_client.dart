/// Dio HTTP Client Configuration
/// CDC: Client HTTP avec intercepteurs Auth/JWT, tracing, logging, retry
/// v2.1: Added OpenTelemetry trace interceptor
library;

import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../security/secure_storage_service.dart';
import 'mock_interceptor.dart';
import 'trace_interceptor.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Resolve base URL based on platform
String get _resolvedBaseUrl {
  if (kReleaseMode) return ApiConstants.baseUrlProd;
  if (Platform.isIOS) return ApiConstants.baseUrlIos;
  return ApiConstants.baseUrl; // Android emulator
}

// ── Dio Client ──────────────────────────────────────────────

Dio createDioClient(SecureStorageService secureStorage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _resolvedBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Mock data fallback & user-friendly error mapping
  dio.interceptors.add(MockInterceptor());

  // OpenTelemetry distributed tracing (W3C Trace Context)
  dio.interceptors.add(TraceInterceptor());

  // Auth interceptor
  dio.interceptors.add(AuthInterceptor(dio: dio, secureStorage: secureStorage));

  // Logging (debug only)
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => _logger.d(o),
    ));
  }

  return dio;
}

// ── Auth Interceptor ────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  bool _isRefreshing = false;

  AuthInterceptor({
    required Dio dio,
    required SecureStorageService secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _secureStorage.read(key: 'refresh_token');
        if (refreshToken != null) {
          final response = await Dio().post(
            '$_resolvedBaseUrl${ApiConstants.refreshToken}',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['data']['access_token'];
            final newRefreshToken = response.data['data']['refresh_token'];

            await _secureStorage.write(
              key: 'access_token',
              value: newAccessToken,
            );
            await _secureStorage.write(
              key: 'refresh_token',
              value: newRefreshToken,
            );

            // Retry original request
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(err.requestOptions);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        _logger.e('Token refresh failed: $e');
      }
      _isRefreshing = false;
    }
    handler.next(err);
  }
}

// ── Provider ────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return createDioClient(secureStorage);
});
