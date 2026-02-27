import 'package:dartz/dartz.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

abstract class ChatRepository {
  /// Get chat messages for a consultation/appointment
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String consultationId, {
    String? cursor,
    int perPage = 50,
  });

  /// Send an E2E encrypted message
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String consultationId,
    required String ciphertext,
    required String nonce,
    required String algorithm,
    String? keyId,
  });

  /// Acknowledge message delivery/read
  Future<Either<Failure, void>> acknowledgeMessage({
    required String consultationId,
    required String messageId,
    required String status, // 'DELIVERED' or 'READ'
  });

  /// Get conversations (appointments with chat)
  Future<Either<Failure, List<Conversation>>> getConversations();
}
