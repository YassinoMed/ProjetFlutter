/// Auth Remote Data Source
/// Handles API communication for authentication
library;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  });

  Future<LoginResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? phone,
    String? speciality,
    String? licenseNumber,
  });

  Future<void> logout();

  Future<({String accessToken, String refreshToken})> refreshToken(
    String refreshToken,
  );

  Future<UserModel> getProfile();

  Future<UserModel> updateProfile(Map<String, dynamic> data);

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            (response.data is Map && response.data.containsKey('data'))
                ? response.data['data'] as Map<String, dynamic>
                : response.data as Map<String, dynamic>;

        return LoginResponseModel.fromJson(data);
      }

      throw ServerException(
        message: response.data['message'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthException(
          message: 'Email ou mot de passe incorrect',
          statusCode: 401,
        );
      }
      if (e.response?.statusCode == 422) {
        throw ServerException(
          message: _extractValidationError(e.response?.data),
          statusCode: 422,
        );
      }
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<LoginResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? phone,
    String? speciality,
    String? licenseNumber,
  }) async {
    try {
      final parts = name.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts.first : 'Utilisateur';
      final lastName =
          parts.length > 1 ? parts.sublist(1).join(' ') : 'Sans Nom';

      final data = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
        if (phone != null) 'phone': phone,
        if (speciality != null) 'speciality': speciality,
        if (licenseNumber != null) 'license_number': licenseNumber,
      };

      final response = await dio.post(ApiConstants.register, data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data =
            (response.data is Map && response.data.containsKey('data'))
                ? response.data['data'] as Map<String, dynamic>
                : response.data as Map<String, dynamic>;

        return LoginResponseModel.fromJson(data);
      }

      throw ServerException(
        message: response.data['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw ServerException(
          message: _extractValidationError(e.response?.data),
          statusCode: 422,
        );
      }
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Logout failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<({String accessToken, String refreshToken})> refreshToken(
    String currentRefreshToken,
  ) async {
    try {
      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': currentRefreshToken},
      );

      if (response.statusCode == 200) {
        return (
          accessToken: response.data['access_token'] as String,
          refreshToken: response.data['refresh_token'] as String,
        );
      }

      throw const TokenExpiredException();
    } on DioException {
      throw const TokenExpiredException();
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.profile);

      if (response.statusCode == 200) {
        return UserModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw ServerException(
        message: 'Failed to get profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await dio.put(ApiConstants.profile, data: data);

      if (response.statusCode == 200) {
        return UserModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw ServerException(
        message: 'Failed to update profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await dio.put(
        ApiConstants.profilePassword,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw ServerException(
          message: _extractValidationError(e.response?.data),
          statusCode: 422,
        );
      }
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await dio.post(
        ApiConstants.resetPassword,
        data: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractValidationError(dynamic data) {
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
      return data['message']?.toString() ?? 'Erreur de validation';
    }
    return 'Erreur de validation';
  }
}
