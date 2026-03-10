/// Auth Use Cases
/// CDC: JWT (access 15 min + refresh 7 jours avec rotation)
/// Extended with device info for trusted device tracking
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// ── Login Use Case ──────────────────────────────────────────

class LoginParams {
  final String email;
  final String password;
  final String? deviceId;
  final String? deviceName;
  final String? platform;

  const LoginParams({
    required this.email,
    required this.password,
    this.deviceId,
    this.deviceName,
    this.platform,
  });
}

class LoginUseCase extends UseCase<
    ({User user, String accessToken, String refreshToken}), LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<
      Either<Failure,
          ({User user, String accessToken, String refreshToken})>> call(
      LoginParams params) {
    return repository.login(
      email: params.email,
      password: params.password,
      deviceId: params.deviceId,
      deviceName: params.deviceName,
      platform: params.platform,
    );
  }
}

// ── Register Use Case ───────────────────────────────────────

class RegisterParams {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String role;
  final String? phone;
  final String? speciality;
  final String? licenseNumber;
  final String? deviceId;
  final String? deviceName;
  final String? platform;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.role,
    this.phone,
    this.speciality,
    this.licenseNumber,
    this.deviceId,
    this.deviceName,
    this.platform,
  });
}

class RegisterUseCase extends UseCase<
    ({User user, String accessToken, String refreshToken}), RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<
      Either<Failure,
          ({User user, String accessToken, String refreshToken})>> call(
      RegisterParams params) {
    return repository.register(
      name: params.name,
      email: params.email,
      password: params.password,
      passwordConfirmation: params.passwordConfirmation,
      role: params.role,
      phone: params.phone,
      speciality: params.speciality,
      licenseNumber: params.licenseNumber,
      deviceId: params.deviceId,
      deviceName: params.deviceName,
      platform: params.platform,
    );
  }
}

// ── Logout Use Case ─────────────────────────────────────────

class LogoutUseCase extends UseCaseNoParams<void> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}

// ── Get Profile Use Case ────────────────────────────────────

class GetProfileUseCase extends UseCaseNoParams<User> {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call() {
    return repository.getProfile();
  }
}

// ── Forgot Password Use Case ────────────────────────────────

class ForgotPasswordParams {
  final String email;

  const ForgotPasswordParams({required this.email});
}

class ForgotPasswordUseCase extends UseCase<void, ForgotPasswordParams> {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ForgotPasswordParams params) {
    return repository.forgotPassword(email: params.email);
  }
}
