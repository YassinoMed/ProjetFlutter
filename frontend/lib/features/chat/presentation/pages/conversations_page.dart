library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/genui/genui_prompt_panel.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/chat_entities.dart';
import '../providers/chat_providers.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentPath = GoRouterState.of(context).uri.path;
    final isDoctorChat = currentPath.startsWith(AppRoutes.doctorChat);
    final detailRoute =
        isDoctorChat ? AppRoutes.doctorChatDetail : AppRoutes.chatDetail;
    final user = ref.watch(currentUserProvider);

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
                  GenUiPromptPanel(
                    sessionId: 'conversations-${user?.id ?? 'anonymous'}',
                    role: user?.role ?? AppConstants.rolePatient,
                    title: 'Assistant messages',
                    prompt:
                        'Génère une synthèse de messagerie sécurisée avec MetricCard, Checklist et ActionButton. '
                        'Ne révèle pas de contenu sensible et ne donne pas de diagnostic.',
                    contextData: {
                      'screen': 'conversations',
                      'conversationCount': conversations.length,
                      'unreadCount': conversations.fold<int>(
                        0,
                        (total, item) => total + item.unreadCount,
                      ),
                      'recentConversations': conversations.take(5).map((item) {
                        return {
                          'conversationId': item.id,
                          'otherMemberName': item.otherMemberName,
                          'lastMessageTime':
                              item.lastMessageTime.toIso8601String(),
                          'unreadCount': item.unreadCount,
                        };
                      }).toList(growable: false),
                    },
                    icon: Icons.mark_chat_unread_outlined,
                    compact: true,
                  ),
                  const SizedBox(height: 16),
                  if (isDoctorChat) ...[
                    const _AiAssistantTile(),
                    const SizedBox(height: 16),
                  ],
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
                          child: _ConversationTile(
                            conversation: conversation,
                            detailRoute: detailRoute,
                          ),
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
  final String detailRoute;

  const _ConversationTile({
    required this.conversation,
    required this.detailRoute,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatConversationTime(conversation.lastMessageTime);

    return ClinicalSurface(
      onTap: () => context.push(
        detailRoute.replaceFirst(':conversationId', conversation.id),
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

  String _formatConversationTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDay = DateTime(local.year, local.month, local.day);

    if (targetDay == today) {
      return DateFormat('HH:mm').format(local);
    }

    if (targetDay == yesterday) {
      return 'Hier';
    }

    return DateFormat('dd/MM').format(local);
  }
}

class _AiAssistantTile extends StatelessWidget {
  const _AiAssistantTile();

  @override
  Widget build(BuildContext context) {
    return ClinicalSurface(
      onTap: () => context.push(AppRoutes.doctorAiChat),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.softColor(AppTheme.infoColor),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.infoColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant IA médical', style: AppTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Synthèse, réponse patient et checklist clinique.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.neutralGray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.neutralGray400,
          ),
        ],
      ),
    );
  }
}
