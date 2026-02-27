import 'package:dartz/dartz.dart';
import 'package:mediconnect_pro/core/errors/failures.dart';
import 'package:mediconnect_pro/core/utils/usecase.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';
import 'package:mediconnect_pro/features/chat/domain/repositories/chat_repository.dart';

class GetMessages implements UseCase<List<ChatMessage>, GetMessagesParams> {
  final ChatRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
      GetMessagesParams params) async {
    return repository.getMessages(
      params.consultationId,
      cursor: params.cursor,
      perPage: params.perPage,
    );
  }
}

class GetMessagesParams {
  final String consultationId;
  final String? cursor;
  final int perPage;

  const GetMessagesParams({
    required this.consultationId,
    this.cursor,
    this.perPage = 50,
  });
}

class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    return repository.sendMessage(
      consultationId: params.consultationId,
      ciphertext: params.ciphertext,
      nonce: params.nonce,
      algorithm: params.algorithm,
      keyId: params.keyId,
    );
  }
}

class SendMessageParams {
  final String consultationId;
  final String ciphertext;
  final String nonce;
  final String algorithm;
  final String? keyId;

  const SendMessageParams({
    required this.consultationId,
    required this.ciphertext,
    required this.nonce,
    this.algorithm = 'AES-256-GCM',
    this.keyId,
  });
}

class AcknowledgeMessage implements UseCase<void, AckMessageParams> {
  final ChatRepository repository;

  AcknowledgeMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(AckMessageParams params) async {
    return repository.acknowledgeMessage(
      consultationId: params.consultationId,
      messageId: params.messageId,
      status: params.status,
    );
  }
}

class AckMessageParams {
  final String consultationId;
  final String messageId;
  final String status;

  const AckMessageParams({
    required this.consultationId,
    required this.messageId,
    required this.status,
  });
}
