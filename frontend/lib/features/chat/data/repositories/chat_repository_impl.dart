import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/features/chat/data/models/chat_message_model.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';
import 'package:mediconnect_pro/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio dio;
  final String currentUserId;

  ChatRepositoryImpl({required this.dio, required this.currentUserId});

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String consultationId, {
    String? cursor,
    int perPage = 50,
  }) async {
    try {
      final url = ApiConstants.consultationMessages
          .replaceFirst('{id}', consultationId);

      final response = await dio.get(url, queryParameters: {
        'per_page': perPage,
        if (cursor != null) 'cursor': cursor,
      });

      final List<dynamic> data = response.data['data'] ?? [];

      final messages = data
          .map((json) => ChatMessageModel.fromJson(
                json as Map<String, dynamic>,
                currentUserId: currentUserId,
                consultationId: consultationId,
              ))
          .toList();

      return Right(messages);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String consultationId,
    required String ciphertext,
    required String nonce,
    required String algorithm,
    String? keyId,
  }) async {
    try {
      final url = ApiConstants.consultationMessages
          .replaceFirst('{id}', consultationId);

      final response = await dio.post(url, data: {
        'ciphertext': ciphertext,
        'nonce': nonce,
        'algorithm': algorithm,
        if (keyId != null) 'key_id': keyId,
      });

      final json = response.data['message'] as Map<String, dynamic>;

      return Right(ChatMessageModel.fromJson(
        json,
        currentUserId: currentUserId,
        consultationId: consultationId,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ?? 'Send failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acknowledgeMessage({
    required String consultationId,
    required String messageId,
    required String status,
  }) async {
    try {
      final url = ApiConstants.consultationMessageAck
          .replaceFirst('{id}', consultationId)
          .replaceFirst('{msgId}', messageId);

      await dio.post(url, data: {'status': status});
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ?? 'Ack failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() async {
    try {
      // Conversations are based on appointments, so we fetch appointments
      final response = await dio.get(ApiConstants.appointments);
      final List<dynamic> data = response.data['data'] ?? [];

      final conversations = data.map((json) {
        final patientUserId = json['patient_user_id']?.toString() ?? '';
        final isPatient = patientUserId == currentUserId;

        return Conversation(
          id: json['id']?.toString() ?? '',
          otherMemberName: isPatient
              ? 'Dr. ${json['doctor_name'] ?? 'Médecin'}'
              : json['patient_name'] ?? 'Patient',
          otherMemberAvatar: null,
          lastMessage: json['status']?.toString() ?? '',
          lastMessageTime: DateTime.parse(
              json['starts_at_utc'] ?? DateTime.now().toIso8601String()),
          unreadCount: 0,
        );
      }).toList();

      return Right(conversations);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message:
              e.response?.data?['message']?.toString() ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
