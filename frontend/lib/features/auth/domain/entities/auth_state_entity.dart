/// Auth State Entity - Immutable auth state for Riverpod
/// Sanctum: No accessToken stored in state. Token lives only in SecureStorage.
library;

import 'package:equatable/equatable.dart';

import 'user_entity.dart';

class AuthStateEntity extends Equatable {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final bool biometricEnabled;

  const AuthStateEntity({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.biometricEnabled = false,
  });

  const AuthStateEntity.initial()
      : user = null,
        isAuthenticated = false,
        isLoading = false,
        errorMessage = null,
        biometricEnabled = false;

  const AuthStateEntity.loading()
      : user = null,
        isAuthenticated = false,
        isLoading = true,
        errorMessage = null,
        biometricEnabled = false;

  AuthStateEntity copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    bool? biometricEnabled,
  }) {
    return AuthStateEntity(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  List<Object?> get props => [
        user,
        isAuthenticated,
        isLoading,
        errorMessage,
        biometricEnabled,
      ];
}
