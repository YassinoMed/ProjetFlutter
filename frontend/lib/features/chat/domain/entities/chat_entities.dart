import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String otherMemberName;
  final String? otherMemberAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.otherMemberName,
    this.otherMemberAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        otherMemberName,
        otherMemberAvatar,
        lastMessage,
        lastMessageTime,
        unreadCount
      ];
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final bool isEncrypted;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.isEncrypted = true,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    bool? isMe,
    bool? isEncrypted,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        timestamp,
        isMe,
        isEncrypted,
        status
      ];
}

enum MessageStatus { sent, delivered, read }
