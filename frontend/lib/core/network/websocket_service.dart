import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../constants/api_constants.dart';
import '../security/secure_storage_service.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return WebSocketService(secureStorage);
});

/// CDC: Client WebSocket (Pusher Protocol) pour se connecter au serveur Reverb Laravel
class WebSocketService {
  final SecureStorageService _secureStorage;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  bool _isInit = false;

  WebSocketService(this._secureStorage);

  Future<void> init() async {
    if (_isInit) return;

    try {
      final token = await _secureStorage.read(key: 'access_token');

      await _pusher.init(
        apiKey: ApiConstants.reverbAppKey,
        cluster: ApiConstants.reverbAppCluster,
        useTLS: ApiConstants.wsUrl.startsWith('https') ||
            ApiConstants.wsUrlIos.startsWith('https'),
        authEndpoint: '${_getBaseUrl()}/broadcasting/auth',
        authParams: {
          'headers': {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          }
        },
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onEvent,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
      );

      await _pusher.connect();
      _isInit = true;
      _logger.i('WebSocket (Reverb) Initialized & Connecting...');
    } catch (e) {
      _logger.e('Failed to init Reverb WebSocket: $e');
    }
  }

  String _getBaseUrl() {
    if (kReleaseMode) return ApiConstants.baseUrlProd;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ApiConstants.baseUrlIos;
    }
    return ApiConstants.baseUrl; // Android emulator
  }

  Future<void> subscribeToConsultation(
    String consultationId,
    Function(dynamic) onMessageReceived,
  ) async {
    await subscribeToConsultationEvents(
      consultationId,
      (eventName, data) {
        if (eventName == 'App\\Events\\ChatMessageSent' ||
            data['type'] == 'CHAT_MESSAGE') {
          onMessageReceived(data);
        }
      },
    );
  }

  Future<void> unsubscribe(String consultationId) async {
    await unsubscribeConsultation(consultationId);
  }

  Future<void> subscribeToConsultationEvents(
    String consultationId,
    FutureOr<void> Function(String eventName, Map<String, dynamic> data)
        onEvent,
  ) async {
    await _subscribeToPrivateChannel(
      'private-consultations.$consultationId',
      onEvent,
    );
  }

  Future<void> unsubscribeConsultation(String consultationId) async {
    await _unsubscribeChannel('private-consultations.$consultationId');
  }

  Future<void> subscribeToTeleconsultation(
    String teleconsultationId,
    FutureOr<void> Function(String eventName, Map<String, dynamic> data)
        onEvent,
  ) async {
    await _subscribeToPrivateChannel(
      'private-teleconsultations.$teleconsultationId',
      onEvent,
    );
  }

  Future<void> subscribeToCallSession(
    String callSessionId,
    FutureOr<void> Function(String eventName, Map<String, dynamic> data)
        onEvent,
  ) async {
    await _subscribeToPrivateChannel(
      'private-calls.$callSessionId',
      onEvent,
    );
  }

  Future<void> unsubscribeTeleconsultation(String teleconsultationId) async {
    await _unsubscribeChannel('private-teleconsultations.$teleconsultationId');
  }

  Future<void> unsubscribeCallSession(String callSessionId) async {
    await _unsubscribeChannel('private-calls.$callSessionId');
  }

  Future<void> _subscribeToPrivateChannel(
    String channelName,
    FutureOr<void> Function(String eventName, Map<String, dynamic> data)
        onEvent,
  ) async {
    if (!_isInit) await init();

    try {
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          final decoded = _decodeEventData(event.data);
          Future.microtask(() => onEvent(event.eventName, decoded));
        },
      );
      _logger.i('Subscribed to $channelName');
    } catch (e) {
      _logger.e('Failed to subscribe $channelName: $e');
    }
  }

  Future<void> _unsubscribeChannel(String channelName) async {
    try {
      await _pusher.unsubscribe(channelName: channelName);
      _logger.i('Unsubscribed from $channelName');
    } catch (e) {
      _logger.e('Failed to unsubscribe $channelName: $e');
    }
  }

  Map<String, dynamic> _decodeEventData(dynamic rawData) {
    if (rawData == null) {
      return <String, dynamic>{};
    }

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    final data = rawData.toString();
    if (data.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed payloads and return an empty map.
    }

    return <String, dynamic>{'raw': data};
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    _logger.i('Reverb Connection State: $previousState -> $currentState');
  }

  void _onError(String message, int? code, dynamic e) {
    _logger.e('Reverb Error: $message (code: $code)');
  }

  void _onEvent(PusherEvent event) {
    _logger.d('Reverb Event: ${event.eventName} on ${event.channelName}');
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    _logger.i('Reverb Subscription Succeeded: $channelName');
  }

  void _onSubscriptionError(String message, dynamic e) {
    _logger.e('Reverb Subscription Error: $message');
  }
}
