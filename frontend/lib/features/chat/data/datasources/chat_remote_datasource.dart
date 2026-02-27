import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

abstract class ChatRemoteDataSource {
  Future<List<Conversation>> getConversations();
  Future<List<ChatMessage>> getMessages(String consultationId);
  Future<ChatMessage> sendMessage(
      String consultationId, String content, bool isEncrypted);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Conversation>> getConversations() async {
    // Conversations are based on appointments
    final response = await dio.get(ApiConstants.appointments);
    final List<dynamic> data = response.data['data'] ?? response.data;

    return data
        .map((json) => Conversation(
              id: json['id'].toString(),
              otherMemberName:
                  json['doctor_name'] ?? json['patient_name'] ?? 'Unknown',
              otherMemberAvatar: null,
              lastMessage: json['status']?.toString() ?? '',
              lastMessageTime: DateTime.parse(json['starts_at_utc'] ??
                  json['updated_at'] ??
                  DateTime.now().toIso8601String()),
              unreadCount: json['unread_count'] ?? 0,
            ))
        .toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String consultationId) async {
    final response = await dio.get(
      ApiConstants.consultationMessages.replaceFirst('{id}', consultationId),
    );
    final List<dynamic> data = response.data['data'] ?? response.data;

    return data
        .map((json) => ChatMessage(
              id: json['id']?.toString() ?? '',
              conversationId: consultationId,
              senderId: json['sender_user_id']?.toString() ?? '',
              content: json['ciphertext'] as String? ?? '',
              timestamp: DateTime.parse(
                  json['sent_at_utc'] ?? DateTime.now().toIso8601String()),
              isMe: json['is_me'] ?? false,
              isEncrypted: true,
              status: MessageStatus.values.firstWhere(
                (e) =>
                    e.name ==
                    (json['status'] ?? 'sent').toString().toLowerCase(),
                orElse: () => MessageStatus.sent,
              ),
            ))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(
      String consultationId, String content, bool isEncrypted) async {
    final response = await dio.post(
      ApiConstants.consultationMessages.replaceFirst('{id}', consultationId),
      data: {
        'ciphertext': content,
        'nonce': '',
        'algorithm': 'AES-256-GCM',
      },
    );
    final json = response.data['message'] ?? response.data;

    return ChatMessage(
      id: json['id'].toString(),
      conversationId: consultationId,
      senderId: json['sender_user_id'].toString(),
      content: json['ciphertext'],
      timestamp: DateTime.parse(json['sent_at_utc']),
      isMe: true,
      isEncrypted: isEncrypted,
    );
  }
}
