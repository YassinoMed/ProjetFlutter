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

  StreamSubscription? _eventsSub;

  GenUIService({
    required Dio dio,
    required String role,
    this.onSurfaceAdded,
    this.onSurfaceRemoved,
    this.onError,
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

    promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: [systemPrompt],
    );

    // 3. Créer le transport vers Laravel
    transport = LaravelGenUITransport(dio: _dio);

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
  }) async {
    if (text.trim().isEmpty) return;

    try {
      await transport.sendToLaravel(
        userMessage: text.trim(),
        systemPrompt: promptBuilder.systemPromptJoined(),
        patientContext: patientContext,
      );
    } catch (e) {
      onError?.call("Erreur lors de l'envoi du message: $e");
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
