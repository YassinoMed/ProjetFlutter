library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/chat_entities.dart';
import '../providers/chat_providers.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      body: SafeArea(
        child: conversationsAsync.when(
          data: (conversations) {
            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(conversationsProvider.notifier).refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Messages', style: AppTheme.headlineSmall),
                            const SizedBox(height: 6),
                            Text(
                              'Échanges sécurisés avec vos interlocuteurs médicaux.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.neutralGray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.successColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ClinicalStatusChip(
                    label: 'E2E CHIFFRÉ',
                    color: AppTheme.successColor,
                    icon: Icons.lock_rounded,
                    compact: true,
                  ),
                  const SizedBox(height: 16),
                  if (conversations.isEmpty)
                    const ClinicalEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Aucune conversation',
                      message:
                          'Vos échanges apparaîtront ici dès qu’un praticien ou un patient vous contactera.',
                    )
                  else
                    ...conversations.map((conversation) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ConversationTile(conversation: conversation),
                        )),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ErrorDisplay(
            message: err.toString(),
            onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
          ),
        ),
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

    return ClinicalSurface(
      onTap: () => context.push(
        AppRoutes.chatDetail.replaceFirst(':conversationId', conversation.id),
      ),
      child: Row(
        children: [
          ClinicalAvatar(
            name: conversation.otherMemberName,
            imageUrl: conversation.otherMemberAvatar,
            radius: 28,
            online: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.otherMemberName,
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  conversation.lastMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.neutralGray500,
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.neutralGray400,
                ),
              ),
              const SizedBox(height: 8),
              if (conversation.unreadCount > 0)
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${conversation.unreadCount}',
                      style: AppTheme.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.neutralGray400,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
