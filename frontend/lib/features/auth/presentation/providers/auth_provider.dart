/// Auth Provider - Riverpod state management for authentication
/// CDC: AuthNotifier with JWT handling, role redirect
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// ── Repository Provider ─────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio: dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ── Use Case Providers ──────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(authRepositoryProvider));
});

// ── Auth State Notifier ─────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthStateEntity> {
  @override
  Future<AuthStateEntity> build() async {
    try {
      final repository = ref.watch(authRepositoryProvider);
      final hasTokens = await repository.hasValidTokens();

      if (hasTokens) {
        final cachedUser = await repository.getCachedUser();
        if (cachedUser != null) {
          return AuthStateEntity(
            user: cachedUser,
            isAuthenticated: true,
          );
        }
      }
    } catch (e) {
      // Gracefully handle — no stored session means unauthenticated
    }

    return const AuthStateEntity.initial();
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase(LoginParams(
      email: email,
      password: password,
    ));

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (data) => AsyncValue.data(AuthStateEntity(
        user: data.user,
        accessToken: data.accessToken,
        isAuthenticated: true,
      )),
    );
  }

  /// Register
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? phone,
    String? speciality,
    String? licenseNumber,
  }) async {
    state = const AsyncValue.loading();

    final registerUseCase = ref.read(registerUseCaseProvider);
    final result = await registerUseCase(RegisterParams(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role,
      phone: phone,
      speciality: speciality,
      licenseNumber: licenseNumber,
    ));

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (data) => AsyncValue.data(AuthStateEntity(
        user: data.user,
        accessToken: data.accessToken,
        isAuthenticated: true,
      )),
    );
  }

  /// Logout
  Future<void> logout() async {
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase();

    state = const AsyncValue.data(AuthStateEntity.initial());
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    final getProfile = ref.read(getProfileUseCaseProvider);
    final result = await getProfile();

    result.fold(
      (failure) {},
      (user) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncValue.data(current.copyWith(user: user));
        }
      },
    );
  }

  /// Update Profile
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    String? address,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.updateProfile(
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
      address: address,
    );

    result.fold(
      (failure) {},
      (user) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncValue.data(current.copyWith(user: user));
        }
      },
    );

    return result;
  }

  /// Update Password
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    return await repository.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}

// ── Providers ───────────────────────────────────────────────

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthStateEntity>(
  () => AuthNotifier(),
);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.isAuthenticated ?? false;
});

final currentUserRoleProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});
