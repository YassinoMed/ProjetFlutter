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

  const AuthStateEntity({
    this.user,
    this.accessToken,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  const AuthStateEntity.initial()
      : user = null,
        accessToken = null,
        isAuthenticated = false,
        isLoading = false,
        errorMessage = null;

  const AuthStateEntity.loading()
      : user = null,
        accessToken = null,
        isAuthenticated = false,
        isLoading = true,
        errorMessage = null;

  AuthStateEntity copyWith({
    User? user,
    String? accessToken,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthStateEntity(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    user,
    accessToken,
    isAuthenticated,
    isLoading,
    errorMessage,
  ];
}
