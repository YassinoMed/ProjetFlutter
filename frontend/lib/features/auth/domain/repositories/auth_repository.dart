/// Auth Repository Interface (Domain layer)
/// Clean Architecture: abstractions in domain, implementations in data
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Login with email and password
  /// Returns JWT tokens + User on success
  Future<
      Either<Failure,
          ({User user, String accessToken, String refreshToken})>> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
    String? platform,
  });

  /// Register a new user (Patient or Doctor)
  Future<
      Either<Failure,
          ({User user, String accessToken, String refreshToken})>> register({
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

  /// Logout - invalidate tokens on server
  Future<Either<Failure, void>> logout();

  /// Refresh access token using refresh token
  Future<Either<Failure, ({String accessToken, String refreshToken})>>
      refreshToken();

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

  /// Check if user has valid tokens stored
  Future<bool> hasValidTokens();

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
  /// Returns the user profile if the stored token is still valid
  Future<Either<Failure, User>> loginWithBiometric();
}
