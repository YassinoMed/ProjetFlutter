import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/ai/cloud_medical_ai_service.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';

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
  bool _isThinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return const _TypingBubble();
                }

                return _AiBubble(message: _messages[index]);
              },
            ),
          ),
          _SuggestionBar(onSelected: _sendPrompt),
          _buildInput(isDark),
        ],
      ),
    );
  }

  Widget _buildInput(bool isDark) {
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
              onPressed: _controller.text.trim().isEmpty || _isThinking
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
    if (prompt.isEmpty || _isThinking) {
      return;
    }

    final priorMessages =
        _messages.length > 1 ? _messages.sublist(1) : <_AiMessage>[];
    final recentMessages = priorMessages.length > 10
        ? priorMessages.sublist(priorMessages.length - 10)
        : priorMessages;
    final requestMessages = [
      CloudAiChatMessage.system(CloudMedicalAiService.chatSystemPrompt),
      ...recentMessages.map(
        (message) => message.isUser
            ? CloudAiChatMessage.user(message.content)
            : CloudAiChatMessage.assistant(message.content),
      ),
      CloudAiChatMessage.user(prompt),
    ];

    setState(() {
      _messages.add(_AiMessage.user(prompt));
      _controller.clear();
      _isThinking = true;
    });
    _scrollToBottom();

    try {
      final response = await ref
          .read(cloudMedicalAiServiceProvider)
          .chat(messages: requestMessages);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(_AiMessage.assistant(response));
        _isThinking = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _AiMessage.assistant(
            'Impossible de contacter Gemini pour le moment.\n\n${CloudMedicalAiService.friendlyError(error)}',
          ),
        );
        _isThinking = false;
      });
    }

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
