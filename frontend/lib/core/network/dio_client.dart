/// Dio HTTP Client Configuration
/// CDC: Client HTTP avec intercepteurs Auth/JWT, tracing, logging, retry
/// v2.1: Added OpenTelemetry trace interceptor
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../security/secure_storage_service.dart';
import 'api_response.dart';
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
        'X-Tenant-Identifier': ApiConstants.defaultTenantId,
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
  Completer<String?>? _refreshCompleter;

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
    final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Inject the current tenant identifier (fallback to default)
    final tenantId = await _secureStorage.read(key: AppConstants.keyTenantId);
    options.headers['X-Tenant-Identifier'] =
        (tenantId != null && tenantId.isNotEmpty)
            ? tenantId
            : ApiConstants.defaultTenantId;

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['__retry'] != true &&
        !err.requestOptions.path.contains(ApiConstants.refreshToken)) {
      if (_isRefreshing) {
        final token = await _refreshCompleter?.future;
        if (token != null && token.isNotEmpty) {
          err.requestOptions.extra['__retry'] = true;
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        }
        return handler.next(err);
      }

      _isRefreshing = true;
      _refreshCompleter = Completer<String?>();
      try {
        final refreshToken =
            await _secureStorage.read(key: AppConstants.keyRefreshToken);
        if (refreshToken != null) {
          final refreshClient = Dio(
            BaseOptions(
              baseUrl: _resolvedBaseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              sendTimeout: ApiConstants.sendTimeout,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Tenant-Identifier': ApiConstants.defaultTenantId,
              },
            ),
          );
          final response = await refreshClient.post(
            ApiConstants.refreshToken,
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200) {
            final tokens = extractTokensMap(response.data);
            final newAccessToken = tokens['access_token'] as String?;
            final newRefreshToken = tokens['refresh_token'] as String?;

            if (newAccessToken == null || newAccessToken.isEmpty) {
              throw DioException(
                requestOptions: err.requestOptions,
                response: response,
                error: 'Missing access token after refresh',
                type: DioExceptionType.badResponse,
              );
            }

            await _secureStorage.write(
              key: AppConstants.keyAccessToken,
              value: newAccessToken,
            );
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await _secureStorage.write(
                key: AppConstants.keyRefreshToken,
                value: newRefreshToken,
              );
            }

            _refreshCompleter?.complete(newAccessToken);
            err.requestOptions.extra['__retry'] = true;
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        _refreshCompleter?.complete(null);
      } catch (e) {
        _logger.e('Token refresh failed: $e');
        await _secureStorage.delete(key: AppConstants.keyAccessToken);
        await _secureStorage.delete(key: AppConstants.keyRefreshToken);
        _refreshCompleter?.complete(null);
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}

// ── Provider ────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return createDioClient(secureStorage);
});
