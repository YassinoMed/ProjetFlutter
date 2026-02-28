/// API Response Models
/// CDC: Modèles de réponse API standard Laravel
library;

Map<String, dynamic> extractPayloadMap(dynamic payload) {
  return payload is Map<String, dynamic> ? payload : <String, dynamic>{};
}

Map<String, dynamic> extractDataMap(dynamic payload) {
  final map = extractPayloadMap(payload);
  final data = map['data'];
  return data is Map<String, dynamic> ? data : map;
}

Map<String, dynamic> extractTokensMap(dynamic payload) {
  final data = extractDataMap(payload);
  final tokens = data['tokens'];
  return tokens is Map<String, dynamic> ? tokens : data;
}

Map<String, dynamic> extractUserMap(dynamic payload) {
  final data = extractDataMap(payload);
  final user = data['user'];
  return user is Map<String, dynamic> ? user : data;
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final ApiError? error;
  final ApiMeta? meta;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] != null
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiError {
  final String message;
  final int? code;
  final Map<String, List<String>>? errors;

  const ApiError({
    required this.message,
    this.code,
    this.errors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String? ?? 'Erreur inconnue',
      code: json['code'] as int?,
      errors: json['errors'] != null
          ? (json['errors'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                (value as List).map((e) => e.toString()).toList(),
              ),
            )
          : null,
    );
  }
}

class ApiMeta {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;
  final String? nextCursor;

  const ApiMeta({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.nextCursor,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      currentPage: json['current_page'] as int?,
      lastPage: json['last_page'] as int?,
      perPage: json['per_page'] as int?,
      total: json['total'] as int?,
      nextCursor: json['next_cursor'] as String?,
    );
  }
}
