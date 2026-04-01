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

typedef WebSocketEventHandler = FutureOr<void> Function(
  String eventName,
  Map<String, dynamic> data,
);

/// CDC: Client WebSocket (Pusher Protocol) pour se connecter au serveur Reverb Laravel
class WebSocketService {
  final SecureStorageService _secureStorage;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final Map<String, Map<String, WebSocketEventHandler>> _channelListeners = {};
  final Set<String> _activeChannels = <String>{};
  bool _isInit = false;
  int _listenerSequence = 0;

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

  Future<String> subscribeToConsultation(
    String consultationId,
    Function(dynamic) onMessageReceived,
  ) async {
    return subscribeToConsultationEvents(
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

  Future<String> subscribeToConsultationEvents(
    String consultationId,
    WebSocketEventHandler onEvent,
  ) async {
    return _subscribeToPrivateChannel(
      'private-consultations.$consultationId',
      onEvent,
    );
  }

  Future<void> unsubscribeConsultation(
    String consultationId, {
    String? listenerId,
  }) async {
    await _unsubscribeChannel(
      'private-consultations.$consultationId',
      listenerId: listenerId,
    );
  }

  Future<String> subscribeToTeleconsultation(
    String teleconsultationId,
    WebSocketEventHandler onEvent,
  ) async {
    return _subscribeToPrivateChannel(
      'private-teleconsultations.$teleconsultationId',
      onEvent,
    );
  }

  Future<String> subscribeToCallSession(
    String callSessionId,
    WebSocketEventHandler onEvent,
  ) async {
    return _subscribeToPrivateChannel(
      'private-calls.$callSessionId',
      onEvent,
    );
  }

  Future<void> unsubscribeTeleconsultation(
    String teleconsultationId, {
    String? listenerId,
  }) async {
    await _unsubscribeChannel(
      'private-teleconsultations.$teleconsultationId',
      listenerId: listenerId,
    );
  }

  Future<void> unsubscribeCallSession(
    String callSessionId, {
    String? listenerId,
  }) async {
    await _unsubscribeChannel(
      'private-calls.$callSessionId',
      listenerId: listenerId,
    );
  }

  Future<String> _subscribeToPrivateChannel(
    String channelName,
    WebSocketEventHandler onEvent,
  ) async {
    if (!_isInit) await init();

    final listenerId = 'listener-${_listenerSequence++}';
    final listeners =
        _channelListeners.putIfAbsent(channelName, () => <String, WebSocketEventHandler>{});
    listeners[listenerId] = onEvent;

    if (_activeChannels.contains(channelName)) {
      _logger.i('Attached listener to $channelName');
      return listenerId;
    }

    try {
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          final decoded = _decodeEventData(event.data);
          final channel = event.channelName;
          final callbacks =
              _channelListeners[channel]?.values.toList(growable: false) ??
                  const <WebSocketEventHandler>[];

          for (final callback in callbacks) {
            Future.microtask(() async {
              try {
                await callback(event.eventName, decoded);
              } catch (error) {
                _logger.e(
                  'Failed to dispatch ${event.eventName} on $channel: $error',
                );
              }
            });
          }
        },
      );
      _activeChannels.add(channelName);
      _logger.i('Subscribed to $channelName');
    } catch (e) {
      listeners.remove(listenerId);
      if (listeners.isEmpty) {
        _channelListeners.remove(channelName);
      }
      _logger.e('Failed to subscribe $channelName: $e');
    }

    return listenerId;
  }

  Future<void> _unsubscribeChannel(
    String channelName, {
    String? listenerId,
  }) async {
    final listeners = _channelListeners[channelName];
    if (listeners == null) {
      return;
    }

    if (listenerId == null) {
      listeners.clear();
    } else {
      listeners.remove(listenerId);
    }

    if (listeners.isNotEmpty) {
      _logger.i('Detached listener from $channelName');
      return;
    }

    _channelListeners.remove(channelName);

    if (!_activeChannels.contains(channelName)) {
      return;
    }

    try {
      await _pusher.unsubscribe(channelName: channelName);
      _activeChannels.remove(channelName);
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
