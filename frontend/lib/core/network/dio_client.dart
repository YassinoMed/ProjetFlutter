/// Dio HTTP Client Configuration
/// Sanctum: Single opaque token, no refresh logic.
/// On 401 → clear storage → redirect to login.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../security/secure_storage_service.dart';
import 'mock_interceptor.dart';
import 'trace_interceptor.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Resolve base URL based on platform
String get _resolvedBaseUrl {
  if (kReleaseMode) return ApiConstants.baseUrlProd;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return ApiConstants.baseUrlIos;
  }
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

  // Auth interceptor — injects Bearer token, handles 401
  dio.interceptors.add(AuthInterceptor(secureStorage: secureStorage));

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

// ── Auth Interceptor (Sanctum — no refresh) ─────────────────

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach Sanctum Bearer token
    final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Inject the current tenant identifier
    final tenantId = await _secureStorage.read(key: AppConstants.keyTenantId);
    options.headers['X-Tenant-Identifier'] =
        (tenantId != null && tenantId.isNotEmpty)
            ? tenantId
            : ApiConstants.defaultTenantId;

    final actingDoctorUserId = await _secureStorage.read(
      key: AppConstants.keyActingDoctorUserId,
    );
    if (actingDoctorUserId != null && actingDoctorUserId.isNotEmpty) {
      options.headers['X-Acting-Doctor-Id'] = actingDoctorUserId;
    } else {
      options.headers.remove('X-Acting-Doctor-Id');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Sanctum: token expired or revoked → clear storage
      // The UI layer (AuthNotifier) will detect the unauthenticated state
      // and redirect to login.
      _logger.w('Received 401 — token expired or revoked, clearing storage');
      await _secureStorage.delete(key: AppConstants.keyAccessToken);
      await _secureStorage.delete(key: AppConstants.keyUserId);
      await _secureStorage.delete(key: AppConstants.keyUserRole);
      await _secureStorage.delete(key: AppConstants.keyTenantId);
      await _secureStorage.delete(key: AppConstants.keyActingDoctorUserId);
      await _secureStorage.delete(key: 'cached_user');
    }
    handler.next(err);
  }
}

// ── Provider ────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return createDioClient(secureStorage);
});
