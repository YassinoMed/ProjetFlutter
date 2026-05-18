/// GenUI Service — Orchestration principale
/// Gère le SurfaceController, le transport et la Conversation GenUI
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as logging;

import 'laravel_transport.dart';
import 'mediconnect_catalog.dart';
import 'system_prompts.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service principal GenUI pour MediConnect Pro.
/// Orchestre la communication entre l'UI Flutter, le transport Laravel
/// et le SurfaceController qui gère les surfaces générées par l'IA.
class GenUIService {
  late final SurfaceController surfaceController;
  late final LaravelGenUITransport transport;
  late final Conversation conversation;
  late final PromptBuilder promptBuilder;

  final Dio _dio;
  final String _role;

  /// Callback quand une nouvelle surface est ajoutée
  final void Function(String surfaceId)? onSurfaceAdded;

  /// Callback quand une surface est supprimée
  final void Function(String surfaceId)? onSurfaceRemoved;

  /// Callback pour les erreurs
  final void Function(String error)? onError;

  /// Callback quand du texte conversationnel est reçu
  final void Function(String text)? onTextReceived;

  /// Callback quand l'état d'attente change
  final void Function(bool isWaiting)? onWaitingChanged;

  StreamSubscription? _eventsSub;

  GenUIService({
    required Dio dio,
    required String role,
    this.onSurfaceAdded,
    this.onSurfaceRemoved,
    this.onError,
    this.onTextReceived,
    this.onWaitingChanged,
  })  : _dio = dio,
        _role = role {
    _initialize();
  }

  void _initialize() {
    // Activer le logging GenUI en debug
    if (kDebugMode) {
      configureLogging(
        level: logging.Level.INFO,
        logCallback: (level, message) {
          _logger.d('GenUI [$level]: $message');
        },
      );
    }

    // 1. Créer le SurfaceController avec le catalogue
    final catalog = MediConnectCatalog.catalog;
    surfaceController = SurfaceController(catalogs: [catalog]);

    // 2. Créer le PromptBuilder avec le prompt adapté au rôle
    final systemPrompt = switch (_role) {
      'doctor' => MediConnectPrompts.doctorPrompt,
      'secretary' => MediConnectPrompts.secretaryPrompt,
      _ => MediConnectPrompts.patientPrompt,
    };

    promptBuilder = PromptBuilder.custom(
      catalog: catalog,
      allowedOperations: SurfaceOperations.all(dataModel: true),
      systemPromptFragments: [
        PromptFragments.currentDate(prefix: 'Contexte: '),
        PromptFragments.acknowledgeUser(prefix: 'Règle: '),
        PromptFragments.requireAtLeastOneSubmitElement(prefix: 'Règle: '),
        systemPrompt,
      ],
    );

    // 3. Créer le transport vers Laravel
    transport = LaravelGenUITransport.withConversationAdapter(
      dio: _dio,
      systemPromptProvider: () => promptBuilder.systemPromptJoined(),
    );

    // 4. Créer la Conversation
    conversation = Conversation(
      controller: surfaceController,
      transport: transport.adapter,
    );

    // 5. Écouter les événements de surface
    _eventsSub = conversation.events.listen(
      (event) {
        if (event is ConversationSurfaceAdded) {
          onSurfaceAdded?.call(event.surfaceId);
        } else if (event is ConversationSurfaceRemoved) {
          onSurfaceRemoved?.call(event.surfaceId);
        } else if (event is ConversationContentReceived) {
          onTextReceived?.call(event.text);
        } else if (event is ConversationWaiting) {
          onWaitingChanged?.call(true);
        } else if (event is ConversationError) {
          onError?.call(event.error.toString());
        }
      },
      onError: (error) {
        onError?.call(error.toString());
      },
    );
  }

  /// Envoie un message utilisateur et déclenche la génération d'UI
  Future<void> sendMessage(
    String text, {
    Map<String, dynamic>? patientContext,
    String? cacheKey,
    bool useCache = false,
  }) async {
    if (text.trim().isEmpty) return;

    try {
      transport.configureNextRequest(
        context: patientContext,
        cacheKey: cacheKey,
        useCache: useCache,
      );
      await conversation.sendRequest(ChatMessage.user(text.trim()));
    } catch (e) {
      onError?.call("Erreur lors de l'envoi du message: $e");
    } finally {
      onWaitingChanged?.call(false);
    }
  }

  /// Indique si un envoi est en cours
  bool get isSending => transport.isSending;

  /// Réinitialise la conversation (nouveau chat)
  void resetConversation() {
    transport.clearHistory();
  }

  /// Libère les ressources
  void dispose() {
    _eventsSub?.cancel();
    conversation.dispose();
    transport.dispose();
  }
}
