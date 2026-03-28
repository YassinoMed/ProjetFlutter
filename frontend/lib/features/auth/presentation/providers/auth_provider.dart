/// Auth Provider - Riverpod state management for authentication
/// Sanctum: Single opaque token, no refresh. Biometric = local gate.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/utils/device_info_helper.dart';
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
      final hasToken = await repository.hasValidToken();
      final biometricEnabled = await repository.isBiometricEnabled();

      if (hasToken) {
        final cachedUser = await repository.getCachedUser();
        if (cachedUser != null) {
          if (!cachedUser.isSecretary) {
            await ref
                .read(secureStorageProvider)
                .delete(key: AppConstants.keyActingDoctorUserId);
          }

          final canUseBiometricLogin = biometricEnabled;

          return AuthStateEntity(
            user: cachedUser,
            isAuthenticated: !canUseBiometricLogin,
            biometricEnabled: biometricEnabled,
            canUseBiometricLogin: canUseBiometricLogin,
            requiresBiometricUnlock: canUseBiometricLogin,
          );
        }
      }

      if (biometricEnabled) {
        return const AuthStateEntity(
          biometricEnabled: true,
          canUseBiometricLogin: false,
          requiresBiometricUnlock: false,
        );
      }
    } catch (e) {
      // Gracefully handle — no stored session means unauthenticated
    }

    return const AuthStateEntity.initial();
  }

  /// Login with email + password
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Get device info for trusted device registration
      final deviceHelper = ref.read(deviceInfoHelperProvider);
      final deviceInfo = await deviceHelper.getDeviceInfo();

      final loginUseCase = ref.read(loginUseCaseProvider);
      final result = await loginUseCase(LoginParams(
        identifier: identifier,
        password: password,
        deviceId: deviceInfo.deviceId,
        deviceName: deviceInfo.deviceName,
        platform: deviceInfo.platform,
      ));

      state = await result.fold(
        (failure) => AsyncValue<AuthStateEntity>.error(
            failure.message, StackTrace.current),
        (data) async {
          // Only do post-login work on success
          final repository = ref.read(authRepositoryProvider);
          final biometricEnabled = await repository.isBiometricEnabled();

          await ref
              .read(secureStorageProvider)
              .delete(key: AppConstants.keyActingDoctorUserId);

          return AsyncValue.data(AuthStateEntity(
            user: data.user,
            isAuthenticated: true,
            biometricEnabled: biometricEnabled,
            canUseBiometricLogin: biometricEnabled,
            requiresBiometricUnlock: false,
          ));
        },
      );
    } catch (e) {
      state = AsyncValue.error(
        e.toString(),
        StackTrace.current,
      );
    }
  }

  /// Login with biometric (fingerprint)
  ///
  /// Flow:
  /// 1. Verify fingerprint locally via local_auth
  /// 2. Read stored Sanctum token from SecureStorage
  /// 3. Validate token with server (/me endpoint)
  /// 4. If token expired or revoked, fallback to password
  Future<void> loginWithBiometric() async {
    final previousState = state.valueOrNull ?? const AuthStateEntity.initial();
    state = const AsyncValue.loading();

    try {
      // Step 1: Local biometric authentication
      final biometricService = ref.read(biometricServiceProvider);
      final authenticated = await biometricService.authenticate(
        reason: 'Utilisez votre empreinte pour vous connecter',
      );

      if (!authenticated) {
        state = AsyncValue.data(
          previousState,
        );
        return; // User cancelled
      }

      // Step 2: Validate stored token with server
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.loginWithBiometric();

      final user = result.fold((_) => null, (user) => user);
      if (user?.isSecretary != true) {
        await ref
            .read(secureStorageProvider)
            .delete(key: AppConstants.keyActingDoctorUserId);
      }

      state = result.fold(
        (failure) => AsyncValue.error(failure.message, StackTrace.current),
        (user) => AsyncValue.data(AuthStateEntity(
          user: user,
          isAuthenticated: true,
          biometricEnabled: true,
          canUseBiometricLogin: true,
          requiresBiometricUnlock: false,
        )),
      );
    } on BiometricLockedOutException {
      state = AsyncValue.error(
        'Trop de tentatives. Veuillez réessayer plus tard.',
        StackTrace.current,
      );
    } on BiometricPermanentlyLockedOutException {
      state = AsyncValue.error(
        'Biométrie désactivée. Veuillez utiliser votre mot de passe.',
        StackTrace.current,
      );
    } on BiometricNotAvailableException {
      state = AsyncValue.error(
        "La biométrie n'est pas disponible sur cet appareil.",
        StackTrace.current,
      );
    } on BiometricException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(
        'Erreur lors de l\'authentification biométrique',
        StackTrace.current,
      );
    }
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

    // Get device info
    final deviceHelper = ref.read(deviceInfoHelperProvider);
    final deviceInfo = await deviceHelper.getDeviceInfo();

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
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      platform: deviceInfo.platform,
    ));

    await ref
        .read(secureStorageProvider)
        .delete(key: AppConstants.keyActingDoctorUserId);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (data) => AsyncValue.data(AuthStateEntity(
        user: data.user,
        isAuthenticated: true,
      )),
    );
  }

  /// Enable biometric authentication for current device
  Future<Either<Failure, void>> enableBiometric() async {
    // Step 1: Verify biometric availability
    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isAvailable();
    if (!isAvailable) {
      return const Left(AuthFailure(
        message: "La biométrie n'est pas disponible sur cet appareil",
      ));
    }

    // Step 2: Authenticate with biometric to confirm
    try {
      final authenticated = await biometricService.authenticate(
        reason: 'Confirmez votre empreinte pour activer la biométrie',
      );
      if (!authenticated) {
        return const Left(AuthFailure(
          message: 'Authentification biométrique annulée',
        ));
      }
    } on BiometricException catch (e) {
      return Left(AuthFailure(message: e.message));
    }

    // Step 3: Register on server
    final deviceHelper = ref.read(deviceInfoHelperProvider);
    final deviceInfo = await deviceHelper.getDeviceInfo();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.enableBiometric(
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      platform: deviceInfo.platform,
    );

    // Step 4: Update state
    result.fold(
      (_) {},
      (_) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncValue.data(
            current.copyWith(
              biometricEnabled: true,
              canUseBiometricLogin: true,
              requiresBiometricUnlock: false,
            ),
          );
        }
      },
    );

    return result;
  }

  /// Disable biometric authentication for current device
  Future<Either<Failure, void>> disableBiometric() async {
    final deviceHelper = ref.read(deviceInfoHelperProvider);
    final deviceId = await deviceHelper.getDeviceId();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.disableBiometric(deviceId: deviceId);

    result.fold(
      (_) {},
      (_) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncValue.data(
            current.copyWith(
              biometricEnabled: false,
              canUseBiometricLogin: false,
              requiresBiometricUnlock: false,
            ),
          );
        }
      },
    );

    return result;
  }

  /// Logout
  Future<void> logout() async {
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase();
    await ref
        .read(secureStorageProvider)
        .delete(key: AppConstants.keyActingDoctorUserId);

    final repository = ref.read(authRepositoryProvider);
    final biometricEnabled = await repository.isBiometricEnabled();

    state = AsyncValue.data(AuthStateEntity(
      biometricEnabled: biometricEnabled,
      canUseBiometricLogin: false,
      requiresBiometricUnlock: false,
    ));
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

// Future<void> sendGoogleTokenToBackend(String token) async {

//   final response = await http.post(
//     Uri.parse("$baseUrl/auth/google"),
//     body: {
//       "token": token
//     }
//   );

//   final data = jsonDecode(response.body);

//   final jwt = data["token"];

//   // stocker JWT
// }

//Connexion avec compte google
// Future<void> loginWithGoogle() async {
//   try {

//     final GoogleSignInAccount? googleUser =
//         await GoogleSignIn().signIn();

//     if (googleUser == null) return;

//     final googleAuth = await googleUser.authentication;

//     final idToken = googleAuth.idToken;

//     await sendGoogleTokenToBackend(idToken!);

//   } catch (e) {
//     state = AsyncError(e, StackTrace.current);
//   }
// }

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

  /// Get the list of trusted devices
  Future<Either<Failure, List<Map<String, dynamic>>>> getDevices() async {
    final repository = ref.read(authRepositoryProvider);
    return await repository.getDevices();
  }

  /// Revoke a trusted device (e.g., for lost phone scenario)
  Future<Either<Failure, void>> revokeDevice(String deviceId) async {
    final repository = ref.read(authRepositoryProvider);
    return await repository.revokeDevice(deviceId: deviceId);
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

/// Whether biometric is enabled for the current user/device
final isBiometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.biometricEnabled ?? false;
});

/// Whether the current device can actually unlock a stored session via biometrics
final canUseBiometricLoginProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.canUseBiometricLogin ??
      false;
});

/// Whether a stored session is waiting for a biometric unlock gate
final requiresBiometricUnlockProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.requiresBiometricUnlock ??
      false;
});

/// Check if biometric hardware is available on this device
final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.read(biometricServiceProvider);
  return biometricService.isAvailable();
});
