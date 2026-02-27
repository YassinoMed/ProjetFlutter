import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.content,
    required super.timestamp,
    required super.isMe,
    super.isEncrypted = true,
    super.status = MessageStatus.sent,
    this.recipientId,
    this.ciphertext,
    this.nonce,
    this.algorithm,
    this.keyId,
  });

  final String? recipientId;
  final String? ciphertext;
  final String? nonce;
  final String? algorithm;
  final String? keyId;

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
    required String consultationId,
  }) {
    final senderId = json['sender_user_id']?.toString() ?? '';
    final isMe = senderId == currentUserId;

    // Parse status from status entries
    var status = MessageStatus.sent;
    final statuses = json['statuses'] as List<dynamic>?;
    if (statuses != null && statuses.isNotEmpty) {
      final statusValue = statuses.first['status']?.toString() ?? '';
      status = switch (statusValue) {
        'READ' => MessageStatus.read,
        'DELIVERED' => MessageStatus.delivered,
        _ => MessageStatus.sent,
      };
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: consultationId,
      senderId: senderId,
      recipientId: json['recipient_user_id']?.toString(),
      content: json['ciphertext']?.toString() ?? '',
      ciphertext: json['ciphertext']?.toString(),
      nonce: json['nonce']?.toString(),
      algorithm: json['algorithm']?.toString(),
      keyId: json['key_id']?.toString(),
      timestamp: DateTime.parse(
          json['sent_at_utc'] ?? DateTime.now().toIso8601String()),
      isMe: isMe,
      isEncrypted: true,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext ?? content,
        'nonce': nonce ?? '',
        'algorithm': algorithm ?? 'AES-256-GCM',
        if (keyId != null) 'key_id': keyId,
      };
}
