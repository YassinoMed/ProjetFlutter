import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mediconnect_pro/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mediconnect_pro/features/chat/data/models/chat_message_model.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

  return ChatRemoteDataSourceImpl(
    dio: dio,
    currentUserId: currentUserId,
  );
});

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  ChatRemoteDataSource get _dataSource => ref.read(chatRemoteDataSourceProvider);

  @override
  Future<List<Conversation>> build() => _dataSource.getConversations();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_dataSource.getConversations);
  }

  void applyMessagePreview(
    String conversationId,
    ChatMessage message, {
    bool incrementUnread = false,
  }) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final updated = <Conversation>[];
    var found = false;

    for (final conversation in current) {
      if (conversation.id != conversationId) {
        updated.add(conversation);
        continue;
      }

      found = true;
      updated.add(
        conversation.copyWith(
          lastMessage: message.content,
          lastMessageTime: message.timestamp,
          unreadCount: incrementUnread
              ? conversation.unreadCount + 1
              : conversation.unreadCount,
        ),
      );
    }

    if (!found) {
      return;
    }

    updated.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    state = AsyncData(updated);
  }

  void markConversationRead(String conversationId) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncData([
      for (final conversation in current)
        if (conversation.id == conversationId)
          conversation.copyWith(unreadCount: 0)
        else
          conversation,
    ]);
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class MessageThreadNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ChatMessage>, String> {
  static const _optimisticIdPrefix = 'local-message-';

  ChatRemoteDataSource get _dataSource => ref.read(chatRemoteDataSourceProvider);

  @override
  Future<List<ChatMessage>> build(String arg) async {
    final messages = await _dataSource.getMessages(arg);
    return _normalize(messages);
  }

  Future<void> syncFromRemote() async {
    final current = state.valueOrNull ?? const <ChatMessage>[];

    try {
      final remoteMessages = await _dataSource.getMessages(arg);
      state = AsyncData(_mergeMessages(current, remoteMessages));
    } catch (error, stackTrace) {
      if (current.isEmpty) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final current = state.valueOrNull ?? const <ChatMessage>[];
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    final optimisticMessage = ChatMessage(
      id: '$_optimisticIdPrefix${DateTime.now().microsecondsSinceEpoch}',
      conversationId: arg,
      senderId: currentUserId,
      content: trimmed,
      timestamp: DateTime.now(),
      isMe: true,
      isEncrypted: true,
      status: MessageStatus.sent,
      isPending: true,
    );

    state = AsyncData(_mergeMessages(current, [optimisticMessage]));
    ref
        .read(conversationsProvider.notifier)
        .applyMessagePreview(arg, optimisticMessage);

    try {
      final persisted = await _dataSource.sendMessage(arg, trimmed, true);
      final withoutOptimistic = (state.valueOrNull ?? const <ChatMessage>[])
          .where((message) => message.id != optimisticMessage.id)
          .toList();

      state = AsyncData(_mergeMessages(withoutOptimistic, [persisted]));
      ref.read(conversationsProvider.notifier).applyMessagePreview(arg, persisted);
    } catch (_) {
      final rollback = (state.valueOrNull ?? const <ChatMessage>[])
          .where((message) => message.id != optimisticMessage.id)
          .toList();
      state = AsyncData(_normalize(rollback));
      unawaited(ref.read(conversationsProvider.notifier).refresh());
      rethrow;
    }
  }

  Future<void> acknowledgeMessage(
    String messageId,
    MessageStatus status,
  ) async {
    await _dataSource.acknowledgeMessage(
      consultationId: arg,
      messageId: messageId,
      status: status,
    );

    _updateMessageStatus(messageId, status);
    ref.read(conversationsProvider.notifier).markConversationRead(arg);
  }

  void applyRealtimeEvent(String eventName, Map<String, dynamic> data) {
    final current = state.valueOrNull;

    if (eventName == 'App\\Events\\ChatMessageSent' ||
        data['type'] == 'CHAT_MESSAGE') {
      final payload = data['message'];
      if (payload is! Map<String, dynamic>) {
        unawaited(syncFromRemote());
        return;
      }

      final message = _dataSourceMessage(payload);
      final merged = _mergeMessages(current ?? const <ChatMessage>[], [message]);
      state = AsyncData(merged);
      ref.read(conversationsProvider.notifier).applyMessagePreview(
            arg,
            message,
            incrementUnread: !message.isMe,
          );
      return;
    }

    if (eventName == 'App\\Events\\ChatMessageAcknowledged' ||
        data['type'] == 'CHAT_ACK') {
      final messageId = data['message_id']?.toString();
      final status = _parseMessageStatus(data['status']?.toString());

      if (messageId == null || status == null) {
        unawaited(syncFromRemote());
        return;
      }

      _updateMessageStatus(messageId, status);
    }
  }

  ChatMessage _dataSourceMessage(Map<String, dynamic> json) {
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';

    return ChatMessageModel.fromJson(
      json,
      currentUserId: currentUserId,
      consultationId: arg,
    );
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncData([
      for (final message in current)
        if (message.id == messageId &&
            _statusPriority(status) >= _statusPriority(message.status))
          message.copyWith(status: status, isPending: false)
        else
          message,
    ]);
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final byId = <String, ChatMessage>{
      for (final message in current) message.id: message,
    };

    for (final message in incoming) {
      byId.removeWhere(
        (_, existing) => _isOptimisticMatch(existing, message),
      );

      final existing = byId[message.id];
      if (existing == null) {
        byId[message.id] = message;
        continue;
      }

      final shouldReplace = existing.isPending ||
          _statusPriority(message.status) >= _statusPriority(existing.status) ||
          message.timestamp.isAfter(existing.timestamp);

      if (shouldReplace) {
        byId[message.id] = message.copyWith(
          isPending: false,
        );
      }
    }

    return _normalize(byId.values);
  }

  bool _isOptimisticMatch(ChatMessage existing, ChatMessage incoming) {
    if (!existing.id.startsWith(_optimisticIdPrefix)) {
      return false;
    }

    return existing.senderId == incoming.senderId &&
        existing.conversationId == incoming.conversationId &&
        existing.content == incoming.content &&
        existing.timestamp.difference(incoming.timestamp).inSeconds.abs() <= 30;
  }

  List<ChatMessage> _normalize(Iterable<ChatMessage> messages) {
    final normalized = messages.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return normalized;
  }

  MessageStatus? _parseMessageStatus(String? status) {
    return switch (status?.toUpperCase()) {
      'READ' => MessageStatus.read,
      'DELIVERED' => MessageStatus.delivered,
      'SENT' => MessageStatus.sent,
      _ => null,
    };
  }

  int _statusPriority(MessageStatus status) {
    return switch (status) {
      MessageStatus.sent => 0,
      MessageStatus.delivered => 1,
      MessageStatus.read => 2,
    };
  }
}

final messagesProvider = AsyncNotifierProvider.autoDispose
    .family<MessageThreadNotifier, List<ChatMessage>, String>(
  MessageThreadNotifier.new,
);
