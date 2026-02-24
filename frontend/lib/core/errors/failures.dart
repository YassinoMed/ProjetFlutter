/// Failure classes for Clean Architecture error handling
/// Uses Either<Failure, T> pattern from dartz
library;

import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server-side failure (API errors)
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});

  factory ServerFailure.fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return const ServerFailure(
          message: 'Requête invalide',
          statusCode: 400,
        );
      case 401:
        return const ServerFailure(
          message: 'Non autorisé. Veuillez vous reconnecter.',
          statusCode: 401,
        );
      case 403:
        return const ServerFailure(
          message: 'Accès refusé',
          statusCode: 403,
        );
      case 404:
        return const ServerFailure(
          message: 'Ressource non trouvée',
          statusCode: 404,
        );
      case 422:
        return const ServerFailure(
          message: 'Données de validation incorrectes',
          statusCode: 422,
        );
      case 429:
        return const ServerFailure(
          message: 'Trop de requêtes. Veuillez patienter.',
          statusCode: 429,
        );
      case 500:
        return const ServerFailure(
          message: 'Erreur serveur interne',
          statusCode: 500,
        );
      default:
        return ServerFailure(
          message: 'Erreur serveur ($statusCode)',
          statusCode: statusCode,
        );
    }
  }
}

/// Cache / Local DB failure
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Network connectivity failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Pas de connexion internet. Mode hors-ligne activé.',
  });
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

/// Token expired failure – triggers refresh flow
class TokenExpiredFailure extends Failure {
  const TokenExpiredFailure({
    super.message = 'Session expirée. Reconnexion en cours...',
  });
}

/// Encryption/Decryption failure
class EncryptionFailure extends Failure {
  const EncryptionFailure({
    super.message = 'Erreur de chiffrement/déchiffrement',
  });
}

/// Permission failure (camera, microphone, etc.)
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}

/// Validation failure
class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({required super.message, this.fieldErrors});

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// GDPR compliance failure
class GdprFailure extends Failure {
  const GdprFailure({required super.message});
}
