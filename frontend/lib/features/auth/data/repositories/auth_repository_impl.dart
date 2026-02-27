/// Auth Repository Implementation
/// CDC: JWT tokens storage, offline cache, error handling
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
  Future<
      Either<Failure,
          ({User user, String accessToken, String refreshToken})>> login(
      {required String email, required String password}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Store tokens securely
      await _storeAuthData(response);

      return Right((
        user: response.user.toEntity(),
        accessToken: response.accessToken,
        refreshToken: response.refreshToken ?? '',
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
      );

      await _storeAuthData(response);

      return Right((
        user: response.user.toEntity(),
        accessToken: response.accessToken,
        refreshToken: response.refreshToken ?? '',
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

    await secureStorage.deleteAll();
    return const Right(null);
  }

  @override
  Future<Either<Failure, ({String accessToken, String refreshToken})>>
      refreshToken() async {
    try {
      final storedRefreshToken = await secureStorage.read(
        key: AppConstants.keyRefreshToken,
      );

      if (storedRefreshToken == null) {
        return const Left(TokenExpiredFailure());
      }

      final result = await remoteDataSource.refreshToken(storedRefreshToken);

      await secureStorage.write(
        key: AppConstants.keyAccessToken,
        value: result.accessToken,
      );
      await secureStorage.write(
        key: AppConstants.keyRefreshToken,
        value: result.refreshToken,
      );

      return Right(result);
    } on TokenExpiredException {
      await secureStorage.deleteAll();
      return const Left(TokenExpiredFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    if (!await networkInfo.isConnected) {
      // Try cached user
      final cachedUser = await getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return const Left(NetworkFailure());
    }

    try {
      final userModel = await remoteDataSource.getProfile();
      // Cache user data
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
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (address != null) 'address': address,
      };

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
  Future<bool> hasValidTokens() async {
    final token = await secureStorage.read(key: AppConstants.keyAccessToken);
    return token != null;
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

  // ── Private Helpers ───────────────────────────────────────

  Future<void> _storeAuthData(LoginResponseModel response) async {
    await secureStorage.write(
      key: AppConstants.keyAccessToken,
      value: response.accessToken,
    );
    await secureStorage.write(
      key: AppConstants.keyRefreshToken,
      value: response.refreshToken ?? '',
    );
    await secureStorage.write(
      key: AppConstants.keyUserId,
      value: response.user.id,
    );
    await secureStorage.write(
      key: AppConstants.keyUserRole,
      value: response.user.role,
    );
    await secureStorage.write(
      key: 'cached_user',
      value: jsonEncode(response.user.toJson()),
    );
  }
}
