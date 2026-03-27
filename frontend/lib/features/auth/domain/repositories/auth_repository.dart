/// Auth Repository Interface (Domain layer) — Sanctum
/// No refresh token concept. Single Sanctum token per session.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Login with email or phone number and password
  /// Returns the Sanctum token + User on success
  Future<Either<Failure, ({User user, String token})>> login({
    required String identifier,
    required String password,
    String? deviceId,
    String? deviceName,
    String? platform,
  });

  /// Register a new user (Patient or Doctor)
  Future<Either<Failure, ({User user, String token})>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? phone,
    String? speciality,
    String? licenseNumber,
    String? deviceId,
    String? deviceName,
    String? platform,
  });

  /// Logout - delete current Sanctum token on server
  Future<Either<Failure, void>> logout();

  /// Get current user profile
  Future<Either<Failure, User>> getProfile();

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    String? address,
  });

  /// Update password
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Check if user has a stored Sanctum token
  Future<bool> hasValidToken();

  /// Get stored user from cache
  Future<User?> getCachedUser();

  /// Send forgot password email
  Future<Either<Failure, void>> forgotPassword({required String email});

  /// Reset password
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  // ── Biometric / Device Management ─────────────────────────

  /// Check if biometric is enabled locally for this device
  Future<bool> isBiometricEnabled();

  /// Enable biometric on server + save locally
  Future<Either<Failure, void>> enableBiometric({
    required String deviceId,
    required String deviceName,
    String? platform,
  });

  /// Disable biometric on server + clear locally
  Future<Either<Failure, void>> disableBiometric({required String deviceId});

  /// Get list of trusted devices
  Future<Either<Failure, List<Map<String, dynamic>>>> getDevices();

  /// Revoke a specific device
  Future<Either<Failure, void>> revokeDevice({required String deviceId});

  /// Login with biometric (local auth → read stored token → validate with server)
  /// Returns the user profile if the stored token is still valid.
  /// If token is expired/revoked → returns failure → user must enter password.
  Future<Either<Failure, User>> loginWithBiometric();
}
