/// Biometric Service — wraps local_auth for fingerprint authentication
///
/// SECURITY: This service provides LOCAL-ONLY biometric verification.
/// The fingerprint never leaves the device. It is used as a "gate"
/// before reading the stored JWT token from SecureStorage.
///
/// Flow:
/// 1. Check device biometric capability
/// 2. Prompt user for fingerprint/face
/// 3. On success → allow token read from SecureStorage
/// 4. On failure → fallback to password login
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

class BiometricService {
  final LocalAuthentication _localAuth;
  final Logger _logger = Logger();

  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Check if the device has biometric hardware AND enrolled biometrics
  Future<bool> isAvailable() async {
    if (!_isSupportedPlatform) return false;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      _logger.w('Biometric availability check failed: $e');
      return false;
    } catch (e) {
      _logger.w('Biometric availability check not supported: $e');
      return false;
    }
  }

  /// Get the list of available biometric types (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!_isSupportedPlatform) return [];

    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      _logger.w('Failed to get available biometrics: $e');
      return [];
    } catch (e) {
      _logger.w('Biometric listing not supported: $e');
      return [];
    }
  }

  /// Check if fingerprint specifically is available
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong);
  }

  /// Authenticate the user with biometrics (fingerprint / face).
  ///
  /// Returns `true` if the user passes local biometric check.
  /// Returns `false` on failure (wrong finger, cancelled, etc.).
  ///
  /// [reason] is shown to the user in the system dialog.
  Future<bool> authenticate({
    String reason = 'Utilisez votre empreinte pour vous connecter',
  }) async {
    if (!_isSupportedPlatform) {
      throw BiometricNotAvailableException();
    }

    try {
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (result) {
        _logger.i('Biometric authentication successful');
      } else {
        _logger
            .w('Biometric authentication failed (user cancelled or rejected)');
      }

      return result;
    } on PlatformException catch (e) {
      _logger.e('Biometric authentication error: ${e.code} - ${e.message}');

      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
          throw BiometricNotAvailableException();
        case 'LockedOut':
          throw BiometricLockedOutException();
        case 'PermanentlyLockedOut':
          throw BiometricPermanentlyLockedOutException();
        default:
          throw BiometricException(
            message: e.message ?? 'Erreur d\'authentification biométrique',
            code: e.code,
          );
      }
    } catch (e) {
      _logger.e('Biometric authentication unsupported: $e');
      throw BiometricNotAvailableException();
    }
  }

  /// Cancel any ongoing biometric prompt
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      _logger.w('Failed to cancel biometric authentication: $e');
    }
  }
}

// ── Exceptions ──────────────────────────────────────────────

class BiometricException implements Exception {
  final String message;
  final String? code;

  const BiometricException({required this.message, this.code});

  @override
  String toString() => 'BiometricException($code): $message';
}

class BiometricNotAvailableException extends BiometricException {
  BiometricNotAvailableException()
      : super(
          message: "La biométrie n'est pas disponible sur cet appareil",
          code: 'NotAvailable',
        );
}

class BiometricLockedOutException extends BiometricException {
  BiometricLockedOutException()
      : super(
          message: 'Trop de tentatives. Veuillez réessayer plus tard.',
          code: 'LockedOut',
        );
}

class BiometricPermanentlyLockedOutException extends BiometricException {
  BiometricPermanentlyLockedOutException()
      : super(
          message:
              'Biométrie désactivée. Veuillez utiliser votre mot de passe.',
          code: 'PermanentlyLockedOut',
        );
}

// ── Provider ────────────────────────────────────────────────

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
