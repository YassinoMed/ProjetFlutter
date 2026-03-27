/// Auth Remote Data Source (Sanctum)
/// Handles API communication for authentication + biometric device management.
/// No refresh token logic — Sanctum uses a single opaque token per session.
library;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
    String? deviceId,
    String? deviceName,
    String? platform,
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
    String? deviceId,
    String? deviceName,
    String? platform,
  });

  Future<void> logout();

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

  // ── Biometric / Device Management ─────────────────────────

  Future<void> enableBiometric({
    required String deviceId,
    required String deviceName,
    String? platform,
  });

  Future<void> disableBiometric({required String deviceId});

  Future<List<Map<String, dynamic>>> getDevices();

  Future<void> revokeDevice({required String deviceId});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
    String? deviceId,
    String? deviceName,
    String? platform,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {
          'login': identifier,
          'password': password,
          if (deviceId != null) 'device_id': deviceId,
          if (deviceName != null) 'device_name': deviceName,
          if (platform != null) 'platform': platform,
        },
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
        // Backend throws ValidationException for invalid credentials (422)
        final validationMsg = _extractValidationError(e.response?.data);
        throw AuthException(
          message: validationMsg.contains('Invalid')
              ? 'Email ou mot de passe incorrect'
              : validationMsg,
          statusCode: 422,
        );
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const ServerException(
          message:
              'Impossible de contacter le serveur. Vérifiez votre connexion.',
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
    String? deviceId,
    String? deviceName,
    String? platform,
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
        if (deviceId != null) 'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
        if (platform != null) 'platform': platform,
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
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.me);

      if (response.statusCode == 200) {
        final userJson = extractUserMap(response.data);
        return UserModel.fromJson(userJson);
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
        final userJson = extractUserMap(response.data);
        return UserModel.fromJson(userJson);
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

  // ── Biometric / Device Management ─────────────────────────

  @override
  Future<void> enableBiometric({
    required String deviceId,
    required String deviceName,
    String? platform,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.enableBiometric,
        data: {
          'device_id': deviceId,
          'device_name': deviceName,
          if (platform != null) 'platform': platform,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to enable biometric',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> disableBiometric({required String deviceId}) async {
    try {
      final response = await dio.post(
        ApiConstants.disableBiometric,
        data: {'device_id': deviceId},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to disable biometric',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final response = await dio.get(ApiConstants.devices);

      if (response.statusCode == 200) {
        final data = extractPayloadMap(response.data);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData
              .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList();
        }
        return [];
      }

      throw ServerException(
        message: 'Failed to get devices',
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
  Future<void> revokeDevice({required String deviceId}) async {
    try {
      final response = await dio.delete(
        '${ApiConstants.revokeDevice}/$deviceId',
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to revoke device',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────

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
