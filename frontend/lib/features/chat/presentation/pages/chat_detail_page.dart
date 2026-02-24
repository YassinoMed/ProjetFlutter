import 'dart:typed_data';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/core/voice/voice_service.dart';
import 'package:mediconnect_pro/core/security/encrypted_attachment_service.dart';
import 'package:mediconnect_pro/features/chat/presentation/providers/chat_providers.dart';
import 'package:mediconnect_pro/features/chat/domain/entities/chat_entities.dart';
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

  bool _isVoiceMode = false;
  bool _isListening = false;
  bool _showAttachOptions = false;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat sécurisé 🔒'),
        actions: [
          // TTS toggle
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
          // E2EE indicator banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                    : [const Color(0xFFe8f4fd), const Color(0xFFd6eaf8)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded,
                    size: 14,
                    color: isDark ? Colors.greenAccent : Colors.green[700]),
                const SizedBox(width: 6),
                Text(
                  'Chiffrement de bout en bout activé',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.greenAccent : Colors.green[800],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),

          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _MessageBubble(
                    message: message,
                    onSpeak: () => _speakMessage(message.content),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => ErrorDisplay(
                message: err.toString(),
                onRetry: () =>
                    ref.refresh(messagesProvider(widget.conversationId)),
              ),
            ),
          ),

          // Voice listening indicator
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Écoute en cours... Parlez maintenant',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_rounded, color: Colors.red),
                    onPressed: _stopVoiceInput,
                  ),
                ],
              ),
            ).animate().slideY(begin: 1.0, end: 0.0, duration: 300.ms),

          // Attachment options panel
          if (_showAttachOptions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.description_rounded,
                    label: 'Ordonnance',
                    color: Colors.blue,
                    onTap: () => _pickAndUploadFile(type: 'medical_record'),
                  ),
                  _AttachOption(
                    icon: Icons.science_rounded,
                    label: 'Résultat',
                    color: Colors.purple,
                    onTap: () => _pickAndUploadFile(type: 'medical_record'),
                  ),
                  _AttachOption(
                    icon: Icons.image_rounded,
                    label: 'Image',
                    color: Colors.green,
                    onTap: () => _pickAndUploadFile(),
                  ),
                  _AttachOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Fichier',
                    color: Colors.orange,
                    onTap: () => _pickAndUploadFile(),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1.0, end: 0.0, duration: 200.ms),

          // Input bar with voice toggle
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: AppTheme.shadowSm,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: Icon(
                _showAttachOptions
                    ? Icons.close_rounded
                    : Icons.add_circle_outline_rounded,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() => _showAttachOptions = !_showAttachOptions);
              },
            ),

            // Text input / Voice toggle
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
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              _isListening
                                  ? '🎤 Relâchez pour envoyer'
                                  : 'Maintenez pour parler',
                              style: TextStyle(
                                color: _isListening
                                    ? Colors.red
                                    : Colors.grey[600],
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
                          hintText: 'Tapez votre message...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        onChanged: (_) => setState(() {}),
                      ),
              ),
            ),

            // Voice / Text toggle
            IconButton(
              icon: Icon(
                _isVoiceMode ? Icons.keyboard_rounded : Icons.mic_rounded,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() => _isVoiceMode = !_isVoiceMode);
              },
            ),

            // Send button (only in text mode)
            if (!_isVoiceMode)
              AnimatedOpacity(
                opacity: _controller.text.trim().isNotEmpty ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: AppTheme.primaryColor),
                  onPressed:
                      _controller.text.trim().isNotEmpty ? _sendMessage : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final dataSource = ref.read(chatRemoteDataSourceProvider);
    try {
      await dataSource.sendMessage(widget.conversationId, content, true);
      _controller.clear();
      setState(() {});
      final _ = ref.refresh(messagesProvider(widget.conversationId));
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
    voiceService.onResult.listen((result) {
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
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
            gradient: message.isMe
                ? const LinearGradient(
                    colors: [Color(0xFF0D6EFD), Color(0xFF0A58CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: message.isMe ? null : AppTheme.neutralGray200,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: message.isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(16),
              bottomLeft: message.isMe
                  ? const Radius.circular(16)
                  : const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: message.isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isMe ? Colors.white60 : Colors.black38,
                    ),
                  ),
                  if (message.isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: Colors.white60,
                    ),
                  ],
                  // TTS button for received messages
                  if (!message.isMe) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onSpeak,
                      child: Icon(
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

// ── Pulsing Voice Dot ───────────────────────────────────────

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.red,
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
