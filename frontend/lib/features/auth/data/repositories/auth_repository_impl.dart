/// Auth Repository Implementation — Sanctum
/// Single opaque token. No refresh. On 401 → re-authenticate.
library;

import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ({User user, String token})>> login({
    required String identifier,
    required String password,
    String? deviceId,
    String? deviceName,
    String? platform,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final response = await remoteDataSource.login(
        identifier: identifier,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
        platform: platform,
      );

      // Store Sanctum token
      await _storeAuthData(response);

      return Right((
        user: response.user.toEntity(),
        token: response.accessToken,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final response = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        role: role,
        phone: phone,
        speciality: speciality,
        licenseNumber: licenseNumber,
        deviceId: deviceId,
        deviceName: deviceName,
        platform: platform,
      );

      await _storeAuthData(response);

      return Right((
        user: response.user.toEntity(),
        token: response.accessToken,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }
    } catch (_) {
      // Even if server logout fails, clear local data
    }

    // Clear all auth data
    await secureStorage.delete(key: AppConstants.keyAccessToken);
    await secureStorage.delete(key: AppConstants.keyUserId);
    await secureStorage.delete(key: AppConstants.keyUserRole);
    await secureStorage.delete(key: AppConstants.keyTenantId);
    await secureStorage.delete(key: AppConstants.keyBiometricEnabled);
    await secureStorage.delete(key: 'cached_user');
    // NOTE: We keep keyBiometricDeviceId — it's the device's identity, not a secret.

    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    if (!await networkInfo.isConnected) {
      final cachedUser = await getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return const Left(NetworkFailure());
    }

    try {
      final userModel = await remoteDataSource.getProfile();
      await secureStorage.write(
        key: 'cached_user',
        value: jsonEncode(userModel.toJson()),
      );
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    String? address,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final data = <String, dynamic>{
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (address != null) 'address': address,
      };

      if (name != null) {
        final parts = name.trim().split(' ');
        data['first_name'] = parts.isNotEmpty ? parts.first : '';
        data['last_name'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      final userModel = await remoteDataSource.updateProfile(data);
      await secureStorage.write(
        key: 'cached_user',
        value: jsonEncode(userModel.toJson()),
      );
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await secureStorage.read(key: AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<User?> getCachedUser() async {
    try {
      final cachedData = await secureStorage.read(key: 'cached_user');
      if (cachedData != null) {
        final json = jsonDecode(cachedData) as Map<String, dynamic>;
        return UserModel.fromJson(json).toEntity();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.resetPassword(
        token: token,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ── Biometric / Device Management ─────────────────────────

  @override
  Future<bool> isBiometricEnabled() async {
    final value = await secureStorage.read(
      key: AppConstants.keyBiometricEnabled,
    );
    return value == 'true';
  }

  @override
  Future<Either<Failure, void>> enableBiometric({
    required String deviceId,
    required String deviceName,
    String? platform,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.enableBiometric(
        deviceId: deviceId,
        deviceName: deviceName,
        platform: platform,
      );

      await secureStorage.write(
        key: AppConstants.keyBiometricEnabled,
        value: 'true',
      );

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> disableBiometric({
    required String deviceId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.disableBiometric(deviceId: deviceId);

      await secureStorage.delete(key: AppConstants.keyBiometricEnabled);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getDevices() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final devices = await remoteDataSource.getDevices();
      return Right(devices);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> revokeDevice({
    required String deviceId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.revokeDevice(deviceId: deviceId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithBiometric() async {
    // Step 1: Check if biometric is enabled locally
    final biometricEnabled = await isBiometricEnabled();
    if (!biometricEnabled) {
      return const Left(AuthFailure(
        message: 'La biométrie n\'est pas activée sur cet appareil',
      ));
    }

    // Step 2: Check if we have a stored Sanctum token
    final hasToken = await hasValidToken();
    if (!hasToken) {
      return const Left(AuthFailure(
        message:
            'Session expirée. Veuillez vous connecter avec votre mot de passe.',
      ));
    }

    // Step 3: Validate the stored token by fetching profile from server
    if (!await networkInfo.isConnected) {
      // Offline: return cached user if available
      final cached = await getCachedUser();
      if (cached != null) {
        return Right(cached);
      }
      return const Left(NetworkFailure());
    }

    try {
      final userModel = await remoteDataSource.getProfile();
      await secureStorage.write(
        key: 'cached_user',
        value: jsonEncode(userModel.toJson()),
      );
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        // Token expired or revoked → clear it
        await secureStorage.delete(key: AppConstants.keyAccessToken);
        return const Left(AuthFailure(
          message:
              'Session expirée. Veuillez vous connecter avec votre mot de passe.',
        ));
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  // ── Private Helpers ───────────────────────────────────────

  Future<void> _storeAuthData(LoginResponseModel response) async {
    await secureStorage.write(
      key: AppConstants.keyAccessToken,
      value: response.accessToken,
    );
    await secureStorage.write(
      key: AppConstants.keyUserId,
      value: response.user.id,
    );
    await secureStorage.write(
      key: AppConstants.keyUserRole,
      value: response.user.role,
    );
    if (response.user.tenantId != null && response.user.tenantId!.isNotEmpty) {
      await secureStorage.write(
        key: AppConstants.keyTenantId,
        value: response.user.tenantId!,
      );
    }
    await secureStorage.write(
      key: 'cached_user',
      value: jsonEncode(response.user.toJson()),
    );
  }
}
