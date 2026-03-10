/// Auth State Entity - Immutable auth state for Riverpod
library;

import 'package:equatable/equatable.dart';

import 'user_entity.dart';

class AuthStateEntity extends Equatable {
  final User? user;
  final String? accessToken;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final bool biometricEnabled;

  const AuthStateEntity({
    this.user,
    this.accessToken,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.biometricEnabled = false,
  });

  const AuthStateEntity.initial()
      : user = null,
        accessToken = null,
        isAuthenticated = false,
        isLoading = false,
        errorMessage = null,
        biometricEnabled = false;

  const AuthStateEntity.loading()
      : user = null,
        accessToken = null,
        isAuthenticated = false,
        isLoading = true,
        errorMessage = null,
        biometricEnabled = false;

  AuthStateEntity copyWith({
    User? user,
    String? accessToken,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    bool? biometricEnabled,
  }) {
    return AuthStateEntity(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  List<Object?> get props => [
        user,
        accessToken,
        isAuthenticated,
        isLoading,
        errorMessage,
        biometricEnabled,
      ];
}
