import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect_pro/core/network/websocket_service.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/features/chat/presentation/providers/chat_providers.dart';

class InlineCallChatPanel extends ConsumerStatefulWidget {
  final String appointmentId;
  final VoidCallback onClose;

  const InlineCallChatPanel({
    super.key,
    required this.appointmentId,
    required this.onClose,
  });

  @override
  ConsumerState<InlineCallChatPanel> createState() =>
      _InlineCallChatPanelState();
}

class _InlineCallChatPanelState extends ConsumerState<InlineCallChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final WebSocketService _websocketService;
  String? _consultationListenerId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _websocketService = ref.read(websocketServiceProvider);
    Future.microtask(_subscribeToRealtime);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    if (_consultationListenerId != null) {
      unawaited(
        _websocketService.unsubscribeConsultation(
          widget.appointmentId,
          listenerId: _consultationListenerId,
        ),
      );
    }
    super.dispose();
  }

  Future<void> _subscribeToRealtime() async {
    if (!mounted || _consultationListenerId != null) {
      return;
    }

    final listenerId = await _websocketService.subscribeToConsultationEvents(
      widget.appointmentId,
      (eventName, data) {
        if (!mounted) {
          return;
        }

        ref
            .read(messagesProvider(widget.appointmentId).notifier)
            .applyRealtimeEvent(eventName, data);
      },
    );

    if (!mounted) {
      await _websocketService.unsubscribeConsultation(
        widget.appointmentId,
        listenerId: listenerId,
      );
      return;
    }

    _consultationListenerId = listenerId;
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);

    try {
      await ref.read(messagesProvider(widget.appointmentId).notifier)
          .sendMessage(content);
      _controller.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'envoi: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.appointmentId));

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Chat pendant l’appel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  final ordered = [...messages]
                    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  if (ordered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun message pour le moment.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: ordered.length,
                    itemBuilder: (context, index) {
                      final message = ordered[index];
                      final alignment = message.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start;
                      final bubbleColor = message.isMe
                          ? AppTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.12);

                      return Column(
                        crossAxisAlignment: alignment,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: alignment,
                              children: [
                                Text(
                                  message.content,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('HH:mm')
                                      .format(message.timestamp.toLocal()),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message…',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
