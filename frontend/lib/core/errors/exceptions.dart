/// Exception classes for data layer
/// These are caught in repositories and converted to Failures
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'No network connection available',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException({required this.message, this.statusCode});

  @override
  String toString() => 'AuthException: $message';
}

class TokenExpiredException implements Exception {
  final String message;

  const TokenExpiredException({this.message = 'Token expired'});

  @override
  String toString() => 'TokenExpiredException: $message';
}

class EncryptionException implements Exception {
  final String message;

  const EncryptionException({required this.message});

  @override
  String toString() => 'EncryptionException: $message';
}
