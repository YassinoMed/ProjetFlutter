import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';

/// RGPD compliance service for CDC requirements
class RgpdService {
  final Dio _dio;

  RgpdService(this._dio);

  /// Export all user data (RGPD Article 20 - Portability)
  Future<Either<Failure, Map<String, dynamic>>> exportData() async {
    try {
      final response = await _dio.get(ApiConstants.rgpdExport);
      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Export failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Update consent (RGPD Article 7)
  Future<Either<Failure, void>> updateConsent({
    required String consentType,
    required bool consented,
  }) async {
    try {
      await _dio.post(ApiConstants.rgpdConsent, data: {
        'consent_type': consentType,
        'consented': consented,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ??
              'Consent update failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Right to erasure (RGPD Article 17)
  Future<Either<Failure, void>> requestDeletion() async {
    try {
      await _dio.delete(ApiConstants.rgpdForget);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Deletion failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

/// Consent types matching the backend
class ConsentType {
  static const String dataProcessing = 'data_processing';
  static const String medicalData = 'medical_data';
  static const String notifications = 'notifications';
  static const String analytics = 'analytics';

  static const List<String> all = [
    dataProcessing,
    medicalData,
    notifications,
    analytics,
  ];

  static String label(String type) => switch (type) {
        dataProcessing => 'Traitement des données',
        medicalData => 'Données médicales',
        notifications => 'Notifications',
        analytics => 'Analyses',
        _ => type,
      };

  static String description(String type) => switch (type) {
        dataProcessing =>
          'Autoriser le traitement de vos données personnelles pour le fonctionnement de l\'application.',
        medicalData =>
          'Autoriser le stockage sécurisé de vos données médicales conformément au RGPD.',
        notifications =>
          'Recevoir des notifications push pour les rappels de rendez-vous et les messages.',
        analytics =>
          'Autoriser les analyses anonymisées pour améliorer le service.',
        _ => '',
      };
}

/// Provider for RGPD service
final rgpdServiceProvider = Provider<RgpdService>((ref) {
  final dio = ref.watch(dioProvider);
  return RgpdService(dio);
});

/// Provider for data export
final rgpdExportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final rgpd = ref.watch(rgpdServiceProvider);
  final result = await rgpd.exportData();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});
