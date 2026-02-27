/// Conversations Page - Placeholder for Step 4
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/chat_providers.dart';
import '../../domain/entities/chat_entities.dart';

import '../../../../shared/widgets/error_display.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(conversationsProvider.future),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final convo = conversations[index];
                return _ConversationTile(conversation: convo);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.refresh(conversationsProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppTheme.neutralGray300),
          SizedBox(height: 16),
          Text('Aucune conversation'),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(conversation.lastMessageTime);

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: conversation.otherMemberAvatar != null
            ? NetworkImage(conversation.otherMemberAvatar!)
            : null,
        child: conversation.otherMemberAvatar == null
            ? const Icon(Icons.person_rounded)
            : null,
      ),
      title: Text(conversation.otherMemberName, style: AppTheme.titleMedium),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeStr, style: AppTheme.labelSmall),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.push(
        AppRoutes.chatDetail.replaceFirst(':conversationId', conversation.id),
      ),
    );
  }
}
