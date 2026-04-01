import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/network/websocket_service.dart';
import 'package:mediconnect_pro/core/security/encrypted_attachment_service.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/core/voice/voice_service.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';
import 'package:mediconnect_pro/features/chat/presentation/providers/chat_providers.dart';
import 'package:mediconnect_pro/shared/widgets/clinical_ui.dart';
import '../../../../shared/widgets/error_display.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatDetailPage({super.key, required this.conversationId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _readAckedMessageIds = <String>{};
  late final WebSocketService _websocketService;
  String? _lastVisibleMessageId;
  String? _consultationListenerId;
  StreamSubscription<VoiceInputResult>? _voiceResultSubscription;

  bool _isVoiceMode = false;
  bool _isListening = false;
  bool _showAttachOptions = false;

  @override
  void initState() {
    super.initState();
    _websocketService = ref.read(websocketServiceProvider);
    Future.microtask(_subscribeToRealtime);
  }

  @override
  void dispose() {
    if (_consultationListenerId != null) {
      unawaited(
        _websocketService.unsubscribeConsultation(
          widget.conversationId,
          listenerId: _consultationListenerId,
        ),
      );
    }
    _controller.dispose();
    _scrollController.dispose();
    _voiceResultSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversations =
        ref.watch(conversationsProvider).valueOrNull ?? const <Conversation>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Conversation? conversation;
    for (final item in conversations) {
      if (item.id == widget.conversationId) {
        conversation = item;
        break;
      }
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.neutralGray50,
      appBar: AppBar(
        title: Row(
          children: [
            ClinicalAvatar(
              name: conversation?.otherMemberName ?? 'Conversation',
              imageUrl: conversation?.otherMemberAvatar,
              radius: 18,
              online: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    conversation?.otherMemberName ?? 'Conversation sécurisée',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleSmall,
                  ),
                  Text(
                    'En ligne',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: 'Lire les messages',
            onPressed: () => _readLastMessage(),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {
              // TODO: Start video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_file_rounded),
            tooltip: 'Fichier chiffré E2EE',
            onPressed: () => _pickAndUploadFile(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.neutralGray100,
            ),
            child: const Center(
              child: ClinicalStatusChip(
                label: 'E2E CHIFFRÉ',
                color: AppTheme.successColor,
                icon: Icons.lock_rounded,
                compact: true,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                final ordered = [...messages];
                final timeline = _buildTimelineEntries(ordered);

                _maybeScrollToLatest(ordered);
                _scheduleReadAcknowledgements(ordered);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  itemCount: timeline.length,
                  itemBuilder: (context, index) {
                    final entry = timeline[index];

                    if (entry.isDateSeparator) {
                      return _DateSeparator(label: entry.label!);
                    }

                    final message = entry.message!;
                    return _MessageBubble(
                      message: message,
                      onSpeak: () => _speakMessage(message.content),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => ErrorDisplay(
                message: err.toString(),
                onRetry: () => ref
                    .read(messagesProvider(widget.conversationId).notifier)
                    .syncFromRemote(),
              ),
            ),
          ),
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.primarySurface,
              ),
              child: Row(
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Écoute en cours... Parlez maintenant',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.stop_rounded,
                      color: AppTheme.errorColor,
                    ),
                    onPressed: _stopVoiceInput,
                  ),
                ],
              ),
            ).animate().slideY(begin: 1.0, end: 0.0, duration: 300.ms),
          if (_showAttachOptions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.darkSurface : Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppTheme.darkBorder : AppTheme.neutralGray200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.description_rounded,
                    label: 'Ordonnance',
                    color: AppTheme.primaryColor,
                    onTap: () => _pickAndUploadFile(type: 'medical_record'),
                  ),
                  _AttachOption(
                    icon: Icons.science_rounded,
                    label: 'Résultat',
                    color: AppTheme.videoCallColor,
                    onTap: () => _pickAndUploadFile(type: 'medical_record'),
                  ),
                  _AttachOption(
                    icon: Icons.image_rounded,
                    label: 'Image',
                    color: AppTheme.successColor,
                    onTap: () => _pickAndUploadFile(),
                  ),
                  _AttachOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Fichier',
                    color: AppTheme.warningColor,
                    onTap: () => _pickAndUploadFile(),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1.0, end: 0.0, duration: 200.ms),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Theme.of(context).cardColor,
        boxShadow: AppTheme.shadowSm,
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _showAttachOptions = !_showAttachOptions);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppTheme.darkSurface : AppTheme.neutralGray100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _showAttachOptions ? Icons.close_rounded : Icons.add_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isVoiceMode
                    ? GestureDetector(
                        key: const ValueKey('voice'),
                        onLongPressStart: (_) => _startVoiceInput(),
                        onLongPressEnd: (_) => _stopVoiceInput(),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? AppTheme.softColor(AppTheme.errorColor)
                                : (isDark
                                    ? AppTheme.darkSurface
                                    : AppTheme.neutralGray100),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              _isListening
                                  ? '🎤 Relâchez pour envoyer'
                                  : 'Maintenez pour parler',
                              style: AppTheme.bodyMedium.copyWith(
                                color: _isListening
                                    ? AppTheme.errorColor
                                    : AppTheme.neutralGray500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )
                    : TextField(
                        key: const ValueKey('text'),
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Écrivez votre message',
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.neutralGray100,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        onChanged: (_) => setState(() {}),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                setState(() => _isVoiceMode = !_isVoiceMode);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppTheme.darkSurface : AppTheme.neutralGray100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isVoiceMode ? Icons.keyboard_rounded : Icons.mic_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            if (!_isVoiceMode)
              AnimatedOpacity(
                opacity: _controller.text.trim().isNotEmpty ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: GestureDetector(
                    onTap: _controller.text.trim().isNotEmpty
                        ? _sendMessage
                        : null,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _subscribeToRealtime() async {
    if (!mounted || _consultationListenerId != null) {
      return;
    }

    final listenerId = await _websocketService.subscribeToConsultationEvents(
      widget.conversationId,
      (eventName, data) {
        if (!mounted) {
          return;
        }

        ref
            .read(messagesProvider(widget.conversationId).notifier)
            .applyRealtimeEvent(eventName, data);
      },
    );

    if (!mounted) {
      await _websocketService.unsubscribeConsultation(
        widget.conversationId,
        listenerId: listenerId,
      );
      return;
    }

    _consultationListenerId = listenerId;
  }

  void _scheduleReadAcknowledgements(List<ChatMessage> messages) {
    final unreadIncoming = messages.where(
      (message) => !message.isMe && message.status != MessageStatus.read,
    );

    for (final message in unreadIncoming) {
      if (_readAckedMessageIds.contains(message.id)) {
        continue;
      }

      _readAckedMessageIds.add(message.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _readAckedMessageIds.remove(message.id);
          return;
        }

        unawaited(_markMessageAsRead(message));
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref
          .read(conversationsProvider.notifier)
          .markConversationRead(widget.conversationId);
    });
  }

  void _maybeScrollToLatest(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return;
    }

    final latestMessage = messages.last;
    final shouldScroll = _lastVisibleMessageId == null ||
        _isNearBottom() ||
        latestMessage.isMe;

    _lastVisibleMessageId = latestMessage.id;

    if (!shouldScroll) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final target = _scrollController.position.maxScrollExtent;
      if ((_scrollController.offset - target).abs() < 4) {
        return;
      }

      if (latestMessage.isMe || _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }

    return (_scrollController.position.maxScrollExtent - _scrollController.offset)
            .abs() <
        160;
  }

  Future<void> _markMessageAsRead(ChatMessage message) async {
    if (!mounted) {
      _readAckedMessageIds.remove(message.id);
      return;
    }

    try {
      await ref.read(messagesProvider(widget.conversationId).notifier)
          .acknowledgeMessage(
            message.id,
            MessageStatus.read,
          );
    } catch (_) {
      _readAckedMessageIds.remove(message.id);
    }
  }

  List<_ChatTimelineEntry> _buildTimelineEntries(List<ChatMessage> messages) {
    final entries = <_ChatTimelineEntry>[];
    DateTime? currentDay;

    for (final message in messages) {
      final localTimestamp = message.timestamp.toLocal();
      final messageDay = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
      );

      if (currentDay == null || currentDay != messageDay) {
        currentDay = messageDay;
        entries.add(
          _ChatTimelineEntry.date(
            _formatDayLabel(messageDay),
          ),
        );
      }

      entries.add(_ChatTimelineEntry.message(message));
    }

    return entries;
  }

  String _formatDayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (day == today) {
      return 'Aujourd’hui';
    }

    if (day == yesterday) {
      return 'Hier';
    }

    return DateFormat('dd MMM yyyy').format(day);
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    try {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendMessage(content);
      if (!mounted) {
        return;
      }
      _controller.clear();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'envoi: $e')),
        );
      }
    }
  }

  void _startVoiceInput() {
    setState(() => _isListening = true);
    final voiceService = ref.read(voiceServiceProvider);
    voiceService.startListening();

    // Listen for results
    _voiceResultSubscription?.cancel();
    _voiceResultSubscription = voiceService.onResult.listen((result) {
      if (result.isFinal && mounted) {
        setState(() {
          _controller.text = result.text;
          _isListening = false;
          _isVoiceMode = false; // Switch to text mode to review
        });
      }
    });
  }

  void _stopVoiceInput() {
    setState(() => _isListening = false);
    ref.read(voiceServiceProvider).stopListening();
  }

  void _speakMessage(String text) {
    ref.read(voiceServiceProvider).speak(text);
  }

  void _readLastMessage() {
    final messages = ref.read(messagesProvider(widget.conversationId));
    messages.whenData((msgs) {
      if (msgs.isNotEmpty) {
        final last = msgs.last;
        _speakMessage(last.content);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Lecture du dernier message…'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  Future<void> _pickAndUploadFile({String? type}) async {
    setState(() => _showAttachOptions = false);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    final file = File(filePath);

    // Show uploading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('🔒 Chiffrement et envoi en cours…'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }

    try {
      if (!mounted) {
        return;
      }

      // TODO: Use actual shared key from ECDH key exchange
      // For now, use a placeholder key
      final dummyKey = List.filled(32, 0x42);
      final service = ref.read(encryptedAttachmentServiceProvider);

      await service.uploadEncrypted(
        file: file,
        sharedKey: Uint8List.fromList(dummyKey),
        attachableType: type ?? 'chat_message',
        attachableId: widget.conversationId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fichier chiffré envoyé avec succès !'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// ── Message Bubble ──────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeak;

  const _MessageBubble({required this.message, this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onSpeak,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: message.isMe
                ? AppTheme.primaryColor
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkSurface
                    : Colors.white),
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomRight: message.isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(18),
              bottomLeft: message.isMe
                  ? const Radius.circular(18)
                  : const Radius.circular(4),
            ),
            border: message.isMe
                ? null
                : Border.all(color: AppTheme.neutralGray200),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: AppTheme.bodyMedium.copyWith(
                  color: message.isMe ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.timestamp.toLocal()),
                    style: AppTheme.bodySmall.copyWith(
                      color: message.isMe ? Colors.white60 : Colors.black38,
                    ),
                  ),
                  if (message.isMe) ...[
                    const SizedBox(width: 4),
                    _MessageStatusIcon(message: message),
                  ],
                  // TTS button for received messages
                  if (!message.isMe) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onSpeak,
                      child: const Icon(
                        Icons.volume_up_rounded,
                        size: 14,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: message.isMe ? 0.1 : -0.1,
          duration: 300.ms,
        );
  }
}

class _MessageStatusIcon extends StatelessWidget {
  final ChatMessage message;

  const _MessageStatusIcon({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isPending) {
      return const Icon(
        Icons.schedule_rounded,
        size: 14,
        color: Colors.white70,
      );
    }

    switch (message.status) {
      case MessageStatus.sent:
        return const Icon(
          Icons.done_rounded,
          size: 14,
          color: Colors.white70,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all_rounded,
          size: 14,
          color: Colors.white70,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all_rounded,
          size: 14,
          color: Color(0xFFBFE3FF),
        );
    }
  }
}

class _DateSeparator extends StatelessWidget {
  final String label;

  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.neutralGray200.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.neutralGray500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatTimelineEntry {
  final ChatMessage? message;
  final String? label;

  const _ChatTimelineEntry._({
    this.message,
    this.label,
  });

  factory _ChatTimelineEntry.message(ChatMessage message) {
    return _ChatTimelineEntry._(message: message);
  }

  factory _ChatTimelineEntry.date(String label) {
    return _ChatTimelineEntry._(label: label);
  }

  bool get isDateSeparator => label != null;
}

// ── Pulsing Voice Dot ───────────────────────────────────────

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: AppTheme.errorColor,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 0.8, end: 1.2, duration: 600.ms)
        .then()
        .scaleXY(begin: 1.2, end: 0.8, duration: 600.ms);
  }
}

// ── Attach Option Widget ────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
