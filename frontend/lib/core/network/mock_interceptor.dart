import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Interceptor to provide mock data when the backend is unreachable (404/500)
/// This allows frontend development to continue even if the API is incomplete.
class MockInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If we get a 404 or 500, check if we have mock data for this path
    if (err.response?.statusCode == 404 || err.response?.statusCode == 500) {
      final path = err.requestOptions.path;
      final method = err.requestOptions.method.toUpperCase();

      if (path.contains(ApiConstants.appointments)) {
        final isPost = method == 'POST';
        // Check if path is just '/appointments' or has an ID like '/appointments/123'
        final isDetail = !path.endsWith(ApiConstants.appointments) &&
            !path.contains('/appointments?');

        if (isPost || isDetail) {
          // Mock single appointment for booking or detail
          return handler.resolve(Response(
            requestOptions: err.requestOptions,
            statusCode: isPost ? 201 : 200,
            data: {
              'data': {
                'id': isDetail ? path.split('/').last : 'mock-new-booking',
                'doctor': {
                  'id': 'doc-1',
                  'first_name': 'Sarah',
                  'last_name': 'Connor',
                  'speciality': 'Cardiologue',
                  'avatar_url': 'https://i.pravatar.cc/150?u=sarah',
                },
                'appointment_date': DateTime.now()
                    .add(const Duration(days: 1))
                    .toIso8601String(),
                'status': 'confirmed',
                'type': 'video',
              }
            },
          ));
        }

        // Mock list for GET
        return handler.resolve(Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'mock-1',
                'doctor': {
                  'id': 'doc-1',
                  'first_name': 'Sarah',
                  'last_name': 'Connor',
                  'speciality': 'Cardiologue',
                  'avatar_url': 'https://i.pravatar.cc/150?u=sarah',
                },
                'appointment_date': DateTime.now()
                    .add(const Duration(days: 1))
                    .toIso8601String(),
                'status': 'confirmed',
                'type': 'video',
              },
              {
                'id': 'mock-2',
                'doctor': {
                  'id': 'doc-2',
                  'first_name': 'James',
                  'last_name': 'Smith',
                  'speciality': 'Généraliste',
                  'avatar_url': 'https://i.pravatar.cc/150?u=james',
                },
                'appointment_date': DateTime.now()
                    .add(const Duration(days: 3))
                    .toIso8601String(),
                'status': 'pending',
                'type': 'clinic',
              }
            ]
          },
        ));
      }

      // Handle Messages (check this BEFORE conversations to avoid collision)
      if (method == 'GET' && path.contains('/messages')) {
        return handler.resolve(Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'msg-1',
                'consultation_id':
                    path.split('/').elementAt(path.split('/').length - 2),
                'sender_user_id': 'doc-1',
                'recipient_user_id': 'patient-id',
                'ciphertext':
                    'Bonjour ! Comment puis-je vous aider aujourd\'hui ?',
                'sent_at_utc': DateTime.now()
                    .subtract(const Duration(minutes: 30))
                    .toIso8601String(),
                'is_me': false,
                'is_encrypted': true,
                'status': 'READ',
              },
              {
                'id': 'msg-2',
                'consultation_id':
                    path.split('/').elementAt(path.split('/').length - 2),
                'sender_user_id': 'patient-id',
                'recipient_user_id': 'doc-1',
                'ciphertext':
                    'Bonjour Docteur, j\'ai une question sur mon traitement.',
                'sent_at_utc': DateTime.now()
                    .subtract(const Duration(minutes: 25))
                    .toIso8601String(),
                'is_me': true,
                'is_encrypted': true,
                'status': 'READ',
              },
            ]
          },
        ));
      }

      // Handle Conversations (same as appointments in our architecture)
      if (path.contains('/consultations')) {
        return handler.resolve(Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'convo-1',
                'other_member': {
                  'id': 'doc-1',
                  'name': 'Dr. Sarah Connor',
                  'avatar_url': 'https://i.pravatar.cc/150?u=sarah',
                },
                'last_message': {
                  'content': 'Bonjour, n\'oubliez pas votre rendez-vous.',
                  'created_at': DateTime.now()
                      .subtract(const Duration(hours: 2))
                      .toIso8601String(),
                },
                'updated_at': DateTime.now()
                    .subtract(const Duration(hours: 2))
                    .toIso8601String(),
                'unread_count': 1,
              }
            ]
          },
        ));
      }

      if (path.contains(ApiConstants.doctors)) {
        return handler.resolve(Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'doc-1',
                'first_name': 'Sarah',
                'last_name': 'Connor',
                'speciality': 'Cardiologue',
                'avatar_url': 'https://i.pravatar.cc/150?u=sarah',
                'rating': 4.8,
              },
              {
                'id': 'doc-2',
                'first_name': 'James',
                'last_name': 'Smith',
                'speciality': 'Généraliste',
                'avatar_url': 'https://i.pravatar.cc/150?u=james',
                'rating': 4.5,
              }
            ]
          },
        ));
      }
    }

    // Fallback to error mapping for better UI messages
    // BUT: skip remapping for auth endpoints — preserve real error messages
    final path = err.requestOptions.path;
    if (path.contains('/auth/')) {
      handler.next(err);
      return;
    }
    final customError = _mapException(err);
    handler.next(customError);
  }

  DioException _mapException(DioException err) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message =
            'Le serveur met trop de temps à répondre. Vérifiez votre connexion.';
      case DioExceptionType.connectionError:
        message =
            'Impossible de contacter le serveur. Est-il en cours d\'exécution?';
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        if (status == 404) {
          message = 'Le service demandé est introuvable (404).';
        } else if (status == 500) {
          message = 'Erreur interne du serveur (500).';
        } else {
          message = 'Erreur du serveur (Code: $status).';
        }
      default:
        message = 'Une erreur inattendue est survenue.';
    }

    return DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: message, // Store the human-friendly message in 'error'
      message: message,
    );
  }
}
