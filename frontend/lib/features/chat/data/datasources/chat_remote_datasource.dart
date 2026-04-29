import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/network/api_response.dart';
import 'package:mediconnect_pro/core/security/e2ee_chat_crypto_service.dart';
import 'package:mediconnect_pro/features/chat/data/models/chat_message_model.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

abstract class ChatRemoteDataSource {
  Future<List<Conversation>> getConversations();
  Future<List<ChatMessage>> getMessages(String consultationId);
  Future<ChatMessage> sendMessage(
    String consultationId,
    String content,
    bool isEncrypted,
  );
  Future<void> acknowledgeMessage({
    required String consultationId,
    required String messageId,
    required MessageStatus status,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;
  final String currentUserId;
  final E2eeChatCryptoService e2eeCrypto;

  ChatRemoteDataSourceImpl({
    required this.dio,
    required this.currentUserId,
    required this.e2eeCrypto,
  });

  @override
  Future<List<Conversation>> getConversations() async {
    final response = await dio.get(
      ApiConstants.appointments,
      queryParameters: {'per_page': 20},
    );

    final payload = extractPayloadMap(response.data);
    final List<dynamic> data = payload['data'] as List? ?? const [];

    return data.map((item) {
      final json = item as Map<String, dynamic>;
      final patientId = json['patient_user_id']?.toString() ?? '';
      final isPatientView = patientId == currentUserId;
      final remoteName = isPatientView
          ? (json['doctor_name']?.toString() ?? 'Médecin')
          : (json['patient_name']?.toString() ?? 'Patient');

      return Conversation(
        id: json['id']?.toString() ?? '',
        otherMemberName: remoteName,
        otherMemberAvatar: null,
        lastMessage: json['status']?.toString() ?? '',
        lastMessageTime: DateTime.parse(
          (json['updated_at_utc'] ??
                  json['starts_at_utc'] ??
                  DateTime.now().toIso8601String())
              .toString(),
        ),
        unreadCount: (json['unread_count'] as int?) ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String consultationId) async {
    final response = await dio.get(
      ApiConstants.consultationMessages.replaceFirst('{id}', consultationId),
      queryParameters: {'per_page': ApiConstants.messagesPageSize},
    );

    final payload = extractPayloadMap(response.data);
    final List<dynamic> data = payload['data'] as List? ?? const [];

    final messages = await Future.wait(
      data.whereType<Map<String, dynamic>>().map((json) async {
        final model = ChatMessageModel.fromJson(
          json,
          currentUserId: currentUserId,
          consultationId: consultationId,
        );

        final plaintext = await e2eeCrypto.decryptForConsultation(
          dio: dio,
          consultationId: consultationId,
          currentUserId: currentUserId,
          senderUserId: model.senderId,
          recipientUserId: model.recipientId,
          ciphertext: model.ciphertext ?? model.content,
          nonce: model.nonce,
        );

        return model.copyWith(content: plaintext);
      }),
    )
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return messages;
  }

  @override
  Future<ChatMessage> sendMessage(
    String consultationId,
    String content,
    bool isEncrypted,
  ) async {
    final encrypted = await e2eeCrypto.encryptForConsultation(
      dio: dio,
      consultationId: consultationId,
      currentUserId: currentUserId,
      plaintext: content,
    );

    final response = await dio.post(
      ApiConstants.consultationMessages.replaceFirst('{id}', consultationId),
      data: {
        'ciphertext': encrypted.ciphertext,
        'nonce': encrypted.nonce,
        'algorithm': encrypted.algorithm,
        'key_id': encrypted.keyId,
      },
    );

    final payload = extractPayloadMap(response.data);
    final data = extractDataMap(payload);
    final messageJson = data['message'] as Map<String, dynamic>? ?? const {};

    final persisted = ChatMessageModel.fromJson(
      messageJson,
      currentUserId: currentUserId,
      consultationId: consultationId,
    );

    return persisted.copyWith(content: content);
  }

  @override
  Future<void> acknowledgeMessage({
    required String consultationId,
    required String messageId,
    required MessageStatus status,
  }) async {
    final statusValue = switch (status) {
      MessageStatus.sent => 'DELIVERED',
      MessageStatus.delivered => 'DELIVERED',
      MessageStatus.read => 'READ',
    };

    await dio.post(
      ApiConstants.consultationMessageAck
          .replaceFirst('{id}', consultationId)
          .replaceFirst('{msgId}', messageId),
      data: {'status': statusValue},
    );
  }
}
