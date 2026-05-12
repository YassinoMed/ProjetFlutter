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
import 'package:local_auth/error_codes.dart' as auth_error;
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
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) return false;

      if (defaultTargetPlatform == TargetPlatform.windows) {
        return true;
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
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
    try {
      await _ensureCanAuthenticate();

      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: defaultTargetPlatform != TargetPlatform.windows,
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

      switch (e.code) {
        case auth_error.notAvailable:
        case 'BiometricNotAvailable':
        case auth_error.otherOperatingSystem:
          throw BiometricNotAvailableException();
        case auth_error.notEnrolled:
          throw BiometricNotEnrolledException();
        case auth_error.passcodeNotSet:
          throw BiometricPasscodeNotSetException();
        case auth_error.lockedOut:
          throw BiometricLockedOutException();
        case auth_error.permanentlyLockedOut:
          throw BiometricPermanentlyLockedOutException();
        case auth_error.biometricOnlyNotSupported:
          throw BiometricNotAvailableException();
        default:
          throw BiometricException(
            message: e.message ?? 'Erreur d\'authentification biométrique',
            code: e.code,
          );
      }
    } on BiometricException {
      rethrow;
    } catch (e) {
      _logger.e('Biometric authentication unsupported: $e');
      throw BiometricNotAvailableException();
    }
  }

  Future<void> _ensureCanAuthenticate() async {
    if (!_isSupportedPlatform) {
      throw BiometricNotAvailableException();
    }

    final isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) {
      throw BiometricNotAvailableException();
    }

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }

    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      throw BiometricNotAvailableException();
    }

    final biometrics = await _localAuth.getAvailableBiometrics();
    if (biometrics.isEmpty) {
      throw BiometricNotEnrolledException();
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
          code: auth_error.notAvailable,
        );
}

class BiometricNotEnrolledException extends BiometricException {
  BiometricNotEnrolledException()
      : super(
          message:
              "Aucune empreinte ou biométrie n'est configurée sur cet appareil.",
          code: auth_error.notEnrolled,
        );
}

class BiometricPasscodeNotSetException extends BiometricException {
  BiometricPasscodeNotSetException()
      : super(
          message:
              "Définissez un code de verrouillage sur l'appareil avant d'activer la biométrie.",
          code: auth_error.passcodeNotSet,
        );
}

class BiometricLockedOutException extends BiometricException {
  BiometricLockedOutException()
      : super(
          message: 'Trop de tentatives. Veuillez réessayer plus tard.',
          code: auth_error.lockedOut,
        );
}

class BiometricPermanentlyLockedOutException extends BiometricException {
  BiometricPermanentlyLockedOutException()
      : super(
          message:
              'Biométrie désactivée. Veuillez utiliser votre mot de passe.',
          code: auth_error.permanentlyLockedOut,
        );
}

// ── Provider ────────────────────────────────────────────────

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
