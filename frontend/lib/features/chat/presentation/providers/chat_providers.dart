import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/core/security/e2ee_chat_crypto_service.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:mediconnect_pro/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

  return ChatRemoteDataSourceImpl(
    dio: dio,
    currentUserId: currentUserId,
    e2eeCrypto: ref.watch(e2eeChatCryptoServiceProvider),
  );
});

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  ChatRemoteDataSource get _dataSource =>
      ref.read(chatRemoteDataSourceProvider);

  @override
  Future<List<Conversation>> build() async {
    final conversations = await _dataSource.getConversations();
    return _sortConversations(conversations);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final conversations = await _dataSource.getConversations();
      return _sortConversations(conversations);
    });
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
      final shouldRefreshPreview =
          _compareInstants(message.timestamp, conversation.lastMessageTime) >=
              0;
      updated.add(
        conversation.copyWith(
          lastMessage:
              shouldRefreshPreview ? message.content : conversation.lastMessage,
          lastMessageTime: shouldRefreshPreview
              ? message.timestamp
              : conversation.lastMessageTime,
          unreadCount: incrementUnread
              ? conversation.unreadCount + 1
              : conversation.unreadCount,
        ),
      );
    }

    if (!found) {
      return;
    }

    state = AsyncData(_sortConversations(updated));
  }

  void markConversationRead(String conversationId) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    Conversation? targetConversation;
    for (final conversation in current) {
      if (conversation.id == conversationId) {
        targetConversation = conversation;
        break;
      }
    }

    if (targetConversation == null || targetConversation.unreadCount == 0) {
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

  List<Conversation> _sortConversations(List<Conversation> conversations) {
    final sorted = [...conversations]..sort((a, b) {
        final byDate = _compareInstants(b.lastMessageTime, a.lastMessageTime);
        if (byDate != 0) {
          return byDate;
        }

        return a.id.compareTo(b.id);
      });

    return sorted;
  }

  int _compareInstants(DateTime left, DateTime right) {
    return left.toUtc().compareTo(right.toUtc());
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class MessageThreadNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ChatMessage>, String> {
  static const _optimisticIdPrefix = 'local-message-';

  ChatRemoteDataSource get _dataSource =>
      ref.read(chatRemoteDataSourceProvider);

  @override
  Future<List<ChatMessage>> build(String arg) async {
    final messages = await _dataSource.getMessages(arg);
    return _normalize(messages);
  }

  Future<void> syncFromRemote() async {
    final current = state.valueOrNull ?? const <ChatMessage>[];
    final knownIds = current.map((message) => message.id).toSet();

    try {
      final remoteMessages = await _dataSource.getMessages(arg);
      final merged = _mergeMessages(current, remoteMessages);
      final hasNewIncoming = remoteMessages.any(
        (message) => !message.isMe && !knownIds.contains(message.id),
      );

      state = AsyncData(merged);

      if (merged.isNotEmpty) {
        ref.read(conversationsProvider.notifier).applyMessagePreview(
              arg,
              merged.last,
              incrementUnread: hasNewIncoming,
            );
      }
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
      ref
          .read(conversationsProvider.notifier)
          .applyMessagePreview(arg, persisted);
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
    if (eventName == 'App\\Events\\ChatMessageSent' ||
        data['type'] == 'CHAT_MESSAGE') {
      unawaited(syncFromRemote());
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
      ..sort((a, b) {
        final byDate = _compareInstants(a.timestamp, b.timestamp);
        if (byDate != 0) {
          return byDate;
        }

        if (a.isPending != b.isPending) {
          return a.isPending ? 1 : -1;
        }

        final bySender = a.senderId.compareTo(b.senderId);
        if (bySender != 0) {
          return bySender;
        }

        return a.id.compareTo(b.id);
      });

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

  int _compareInstants(DateTime left, DateTime right) {
    return left.toUtc().compareTo(right.toUtc());
  }
}

final messagesProvider = AsyncNotifierProvider.autoDispose
    .family<MessageThreadNotifier, List<ChatMessage>, String>(
  MessageThreadNotifier.new,
);
