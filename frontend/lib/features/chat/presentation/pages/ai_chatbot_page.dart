import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/constants/app_constants.dart';
import 'package:mediconnect_pro/core/genui/genui_prompt_panel.dart';
import 'package:mediconnect_pro/core/genui/genui_providers.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';

class AiChatbotPage extends ConsumerStatefulWidget {
  const AiChatbotPage({super.key});

  @override
  ConsumerState<AiChatbotPage> createState() => _AiChatbotPageState();
}

class _AiChatbotPageState extends ConsumerState<AiChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AiMessage> _messages = [
    _AiMessage.assistant(
      'Bonjour docteur. Je peux aider à préparer une réponse patient, structurer une synthèse clinique ou proposer les questions à vérifier avant décision.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? AppConstants.roleDoctor;
    final genUiConfig = GenUiSessionConfig(
      sessionId: 'ai-chat-${user?.id ?? 'doctor'}',
      role: role,
    );
    final genUiController = ref.watch(genUiSessionProvider(genUiConfig));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final extraItems = (genUiController.hasContent ? 1 : 0) +
        (genUiController.isLoading ? 1 : 0);

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.neutralGray50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.softColor(AppTheme.infoColor),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.infoColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Assistant IA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppTheme.darkSurface : AppTheme.primarySurface,
            child: Text(
              'Aide clinique non diagnostique. Validation médicale requise.',
              textAlign: TextAlign.center,
              style: AppTheme.labelSmall.copyWith(
                color: isDark ? AppTheme.neutralGray100 : AppTheme.primaryDark,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              itemCount: _messages.length + extraItems,
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _AiBubble(message: _messages[index]);
                }

                final contentIndex = index - _messages.length;
                if (genUiController.hasContent && contentIndex == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GenUiSurfaceStack(
                      controller: genUiController,
                      role: role,
                    ),
                  );
                }

                if (genUiController.isLoading) {
                  return const _TypingBubble();
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          _SuggestionBar(onSelected: _sendPrompt),
          _buildInput(isDark, genUiController.isLoading),
        ],
      ),
    );
  }

  Widget _buildInput(bool isDark, bool isSending) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Theme.of(context).cardColor,
        boxShadow: AppTheme.shadowSm,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Demander à l’assistant',
                  filled: true,
                  fillColor:
                      isDark ? AppTheme.darkSurface : AppTheme.neutralGray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _controller.text.trim().isEmpty || isSending
                  ? null
                  : () => _sendPrompt(_controller.text),
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Envoyer',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPrompt(String rawPrompt) async {
    final prompt = rawPrompt.trim();
    final user = ref.read(currentUserProvider);
    final role = user?.role ?? AppConstants.roleDoctor;
    final genUiConfig = GenUiSessionConfig(
      sessionId: 'ai-chat-${user?.id ?? 'doctor'}',
      role: role,
    );
    final genUiController = ref.read(genUiSessionProvider(genUiConfig));

    if (prompt.isEmpty || genUiController.isLoading) {
      return;
    }

    setState(() {
      _messages.add(_AiMessage.user(prompt));
      _controller.clear();
    });
    _scrollToBottom();

    final recentMessages = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : List<_AiMessage>.from(_messages);

    await genUiController.generate(
      prompt: 'Réponds au dernier message médecin avec une UI GenUI utile. '
          'Utilise AlertCard, Checklist, MedicalForm, DataTable, MetricCard ou ActionButton selon le besoin. '
          'Dernier message: $prompt',
      context: {
        'screen': 'doctor_ai_chat',
        'role': role,
        'recentMessages': recentMessages.map((message) {
          return {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.content,
          };
        }).toList(growable: false),
      },
      useCache: false,
      force: true,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _SuggestionBar extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _SuggestionBar({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Préparer une réponse patient',
      'Structurer un bilan',
      'Checklist prescription',
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
            onPressed: () => onSelected(suggestion),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final _AiMessage message;

  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryColor
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(18),
            bottomLeft:
                isUser ? const Radius.circular(18) : const Radius.circular(4),
          ),
          border: isUser ? null : Border.all(color: AppTheme.neutralGray200),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Text(
          message.content,
          style: AppTheme.bodyMedium.copyWith(
            color: isUser
                ? Colors.white
                : (isDark ? AppTheme.neutralGray100 : AppTheme.neutralGray800),
          ),
        ),
      ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.08, end: 0),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.neutralGray200),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('Analyse...', style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AiMessage {
  final String content;
  final bool isUser;

  const _AiMessage({
    required this.content,
    required this.isUser,
  });

  factory _AiMessage.user(String content) {
    return _AiMessage(content: content, isUser: true);
  }

  factory _AiMessage.assistant(String content) {
    return _AiMessage(content: content, isUser: false);
  }
}
