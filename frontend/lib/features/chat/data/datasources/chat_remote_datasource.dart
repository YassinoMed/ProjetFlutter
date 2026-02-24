import 'package:dio/dio.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

abstract class ChatRemoteDataSource {
  Future<List<Conversation>> getConversations();
  Future<List<ChatMessage>> getMessages(String conversationId);
  Future<ChatMessage> sendMessage(
      String conversationId, String content, bool isEncrypted);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Conversation>> getConversations() async {
    final response = await dio.get(ApiConstants.conversations);
    final List<dynamic> data = response.data['data'] ?? response.data;

    return data
        .map((json) => Conversation(
              id: json['id'].toString(),
              otherMemberName: json['other_member']['name'],
              otherMemberAvatar: json['other_member']['avatar_url'],
              lastMessage: json['last_message']?['content'] ?? '',
              lastMessageTime: DateTime.parse(json['updated_at']),
              unreadCount: json['unread_count'] ?? 0,
            ))
        .toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final response = await dio.get(
      ApiConstants.messages.replaceFirst('{id}', conversationId),
    );
    final List<dynamic> data = response.data['data'] ?? response.data;

    return data
        .map((json) => ChatMessage(
              id: json['id']?.toString() ?? '',
              conversationId: conversationId,
              senderId: json['sender_id']?.toString() ?? '',
              content: json['content'] as String? ?? '',
              timestamp: DateTime.parse(
                  json['created_at'] ?? DateTime.now().toIso8601String()),
              isMe: json['is_me'] ?? false,
              isEncrypted: json['is_encrypted'] ?? true,
              status: MessageStatus.values.firstWhere(
                (e) => e.name == (json['status'] ?? 'sent'),
                orElse: () => MessageStatus.sent,
              ),
            ))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(
      String conversationId, String content, bool isEncrypted) async {
    final response = await dio.post(
      ApiConstants.sendMessage.replaceFirst('{id}', conversationId),
      data: {
        'content': content,
        'is_encrypted': isEncrypted,
      },
    );
    final json = response.data['data'] ?? response.data;

    return ChatMessage(
      id: json['id'].toString(),
      conversationId: conversationId,
      senderId: json['sender_id'].toString(),
      content: json['content'],
      timestamp: DateTime.parse(json['created_at']),
      isMe: true,
      isEncrypted: isEncrypted,
    );
  }
}
