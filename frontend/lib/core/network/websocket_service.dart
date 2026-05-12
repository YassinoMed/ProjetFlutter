import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/api_constants.dart';
import 'dio_client.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final dio = ref.watch(dioProvider);
  return WebSocketService(dio);
});

typedef WebSocketEventHandler = FutureOr<void> Function(
  String eventName,
  Map<String, dynamic> data,
);

/// Pusher-protocol client for Laravel Reverb private channels.
class WebSocketService {
  final Dio _dio;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final Map<String, Map<String, WebSocketEventHandler>> _channelListeners = {};
  final Set<String> _activeChannels = <String>{};
  final Set<String> _pendingSubscriptions = <String>{};

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  Completer<void>? _connectCompleter;
  Timer? _reconnectTimer;
  String? _socketId;
  int _listenerSequence = 0;
  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;
  bool _configurationRejected = false;

  WebSocketService(this._dio);

  bool get _isConnected => _channel != null && _socketId != null;

  Future<void> init() async {
    if (_configurationRejected) {
      throw StateError(
        'Reverb application key rejected by server. Verify REVERB_APP_KEY.',
      );
    }

    if (_isConnected) {
      return;
    }

    final pendingConnect = _connectCompleter;
    if (pendingConnect != null) {
      return pendingConnect.future;
    }

    _manuallyClosed = false;
    final completer = Completer<void>();
    unawaited(completer.future.catchError((_) {}));
    _connectCompleter = completer;

    try {
      final uri = _buildSocketUri();
      _logger.i('Connecting Reverb WebSocket: $uri');

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      unawaited(
        channel.ready.timeout(const Duration(seconds: 12)).catchError(
          (Object error, StackTrace stackTrace) {
            _logger.e('Reverb socket ready failed: $error');
            if (identical(_channel, channel)) {
              _completeConnectError(error, stackTrace);
              _handleDisconnect();
            }
          },
        ),
      );
      _socketSubscription = channel.stream.listen(
        _handleSocketMessage,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        cancelOnError: true,
      );

      return completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          final error = TimeoutException('Reverb connection timed out');
          _completeConnectError(error);
          _handleDisconnect();
          throw error;
        },
      );
    } catch (error, stackTrace) {
      _completeConnectError(error, stackTrace);
      _cleanupSocket();
      rethrow;
    }
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
    final listenerId = 'listener-${_listenerSequence++}';
    final listeners = _channelListeners.putIfAbsent(channelName, () => {});
    listeners[listenerId] = onEvent;

    try {
      await init();
      await _subscribeChannel(channelName);
    } catch (error) {
      _logger.e('Failed to subscribe $channelName: $error');
      if (!_isConnected) {
        _scheduleReconnect();
      }
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
    _pendingSubscriptions.remove(channelName);

    if (_activeChannels.remove(channelName) && _channel != null) {
      _send({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channelName},
      });
      _logger.i('Unsubscribed from $channelName');
    }

    if (_channelListeners.isEmpty) {
      await _closeIfIdle();
    }
  }

  Future<void> _subscribeChannel(String channelName) async {
    if (_activeChannels.contains(channelName) ||
        _pendingSubscriptions.contains(channelName)) {
      return;
    }

    if (!_isConnected) {
      await init();
    }

    _pendingSubscriptions.add(channelName);

    try {
      final authPayload = await _authorizeChannel(channelName);
      final data = <String, dynamic>{
        'channel': channelName,
        if (authPayload['auth'] != null) 'auth': authPayload['auth'],
        if (authPayload['channel_data'] != null)
          'channel_data': authPayload['channel_data'],
      };

      _send({
        'event': 'pusher:subscribe',
        'data': data,
      });
    } catch (error) {
      _pendingSubscriptions.remove(channelName);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _authorizeChannel(String channelName) async {
    final socketId = _socketId;
    if (socketId == null) {
      throw StateError('Reverb socket id is not ready');
    }

    final response = await _dio.post(
      '/broadcasting/auth',
      data: {
        'socket_id': socketId,
        'channel_name': channelName,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw StateError('Invalid Reverb auth response');
  }

  void _handleSocketMessage(dynamic rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage.toString());
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final eventName = decoded['event']?.toString() ?? '';
      final channelName = decoded['channel']?.toString();
      final data = _decodeEventData(decoded['data']);

      if (eventName == 'pusher:connection_established') {
        _handleConnectionEstablished(data);
        return;
      }

      if (eventName == 'pusher_internal:subscription_succeeded' ||
          eventName == 'pusher:subscription_succeeded') {
        if (channelName != null) {
          _pendingSubscriptions.remove(channelName);
          _activeChannels.add(channelName);
          _logger.i('Subscribed to $channelName');
        }
        return;
      }

      if (eventName == 'pusher_internal:subscription_error' ||
          eventName == 'pusher:subscription_error') {
        if (channelName != null) {
          _pendingSubscriptions.remove(channelName);
        }
        _logger.e('Reverb subscription error on $channelName: $data');
        return;
      }

      if (eventName == 'pusher:error') {
        _logger.e('Reverb error event: $data');
        if (data['code']?.toString() == '4001') {
          _configurationRejected = true;
          _completeConnectError(
            StateError(
              'Reverb application does not exist for the configured key.',
            ),
          );
          unawaited(_channel?.sink.close());
        }
        return;
      }

      if (channelName == null || channelName.isEmpty) {
        return;
      }

      final callbacks =
          _channelListeners[channelName]?.values.toList(growable: false) ??
              const <WebSocketEventHandler>[];

      for (final callback in callbacks) {
        Future.microtask(() async {
          try {
            await callback(eventName, data);
          } catch (error) {
            _logger.e(
              'Failed to dispatch $eventName on $channelName: $error',
            );
          }
        });
      }
    } catch (error) {
      _logger.e('Failed to decode Reverb message: $error');
    }
  }

  void _handleConnectionEstablished(Map<String, dynamic> data) {
    _socketId = data['socket_id']?.toString();
    _reconnectAttempts = 0;
    _configurationRejected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_socketId == null || _socketId!.isEmpty) {
      _completeConnectError(StateError('Reverb socket id missing'));
      return;
    }

    final connectCompleter = _connectCompleter;
    if (connectCompleter != null && !connectCompleter.isCompleted) {
      connectCompleter.complete();
    }
    _connectCompleter = null;

    _logger.i('Reverb connected with socket $_socketId');

    final channels = _channelListeners.keys.toList(growable: false);
    for (final channelName in channels) {
      unawaited(
        _subscribeChannel(channelName).catchError((Object error) {
          _logger.e('Failed to resubscribe $channelName: $error');
        }),
      );
    }
  }

  void _handleSocketError(Object error, [StackTrace? stackTrace]) {
    _logger.e('Reverb socket error: $error');
    _completeConnectError(error, stackTrace);
    _handleDisconnect();
  }

  void _handleSocketDone() {
    _logger.w('Reverb socket closed');
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _cleanupSocket();
    _activeChannels.clear();
    _pendingSubscriptions.clear();

    if (!_manuallyClosed &&
        !_configurationRejected &&
        _channelListeners.isNotEmpty) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_manuallyClosed ||
        _configurationRejected ||
        _channelListeners.isEmpty) {
      return;
    }

    if (_reconnectTimer?.isActive == true) {
      return;
    }

    const delays = [1, 2, 4, 8, 15, 30];
    final index = _reconnectAttempts.clamp(0, delays.length - 1).toInt();
    final delay = Duration(seconds: delays[index]);
    _reconnectAttempts++;

    _logger.w('Reconnecting Reverb in ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      try {
        await init();
      } catch (error) {
        _logger.e('Reverb reconnect failed: $error');
        _scheduleReconnect();
      }
    });
  }

  Future<void> _closeIfIdle() async {
    if (_channelListeners.isNotEmpty || _channel == null) {
      return;
    }

    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _cleanupSocket();
  }

  void _send(Map<String, dynamic> payload) {
    final socket = _channel;
    if (socket == null) {
      throw StateError('Reverb socket is not connected');
    }

    socket.sink.add(jsonEncode(payload));
  }

  void _completeConnectError(Object error, [StackTrace? stackTrace]) {
    final connectCompleter = _connectCompleter;
    if (connectCompleter != null && !connectCompleter.isCompleted) {
      connectCompleter.completeError(error, stackTrace ?? StackTrace.current);
    }
    _connectCompleter = null;
  }

  void _cleanupSocket() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel = null;
    _socketId = null;
    _connectCompleter = null;
  }

  Map<String, dynamic> _decodeEventData(dynamic rawData) {
    if (rawData == null) {
      return <String, dynamic>{};
    }

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
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
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore malformed payloads and return the raw string.
    }

    return <String, dynamic>{'raw': data};
  }

  Uri _buildSocketUri() {
    final base = Uri.parse(_getWebSocketBaseUrl());
    final scheme = switch (base.scheme) {
      'https' || 'wss' => 'wss',
      _ => 'ws',
    };
    final normalizedBasePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final path =
        '$normalizedBasePath/app/${Uri.encodeComponent(ApiConstants.reverbAppKey)}';

    return base.replace(
      scheme: scheme,
      path: path,
      queryParameters: {
        ...base.queryParameters,
        'protocol': '7',
        'client': 'flutter',
        'version': '1.0.0',
        'flash': 'false',
      },
    );
  }

  String _getWebSocketBaseUrl() {
    if (kReleaseMode) {
      return ApiConstants.wsUrlProd;
    }

    if (kIsWeb) {
      return ApiConstants.wsUrlWeb;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ApiConstants.wsUrlIos;
    }

    return ApiConstants.wsUrl;
  }
}
