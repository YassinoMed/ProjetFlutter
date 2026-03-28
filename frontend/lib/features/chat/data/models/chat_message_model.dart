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
    final isMe = json['is_me'] == true || senderId == currentUserId;

    var status = MessageStatus.sent;
    final directStatus = json['status']?.toString() ?? '';
    if (directStatus.isNotEmpty) {
      status = switch (directStatus.toUpperCase()) {
        'READ' => MessageStatus.read,
        'DELIVERED' => MessageStatus.delivered,
        _ => MessageStatus.sent,
      };
    } else {
      final statuses = json['statuses'] as List<dynamic>?;
      if (statuses != null && statuses.isNotEmpty) {
        final statusValue = statuses.first['status']?.toString() ?? '';
        status = switch (statusValue.toUpperCase()) {
          'READ' => MessageStatus.read,
          'DELIVERED' => MessageStatus.delivered,
          _ => MessageStatus.sent,
        };
      }
    }

    final timestampRaw = json['sent_at_utc'] ??
        json['created_at'] ??
        DateTime.now().toIso8601String();

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: (json['consultation_id'] ?? consultationId).toString(),
      senderId: senderId,
      recipientId: json['recipient_user_id']?.toString(),
      content:
          json['ciphertext']?.toString() ?? json['content']?.toString() ?? '',
      ciphertext: json['ciphertext']?.toString(),
      nonce: json['nonce']?.toString(),
      algorithm: json['algorithm']?.toString(),
      keyId: json['key_id']?.toString(),
      timestamp: DateTime.parse(timestampRaw.toString()),
      isMe: isMe,
      isEncrypted: json['is_encrypted'] != false,
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
