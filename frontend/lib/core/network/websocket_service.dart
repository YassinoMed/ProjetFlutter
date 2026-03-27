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
      String consultationId, Function(dynamic) onMessageReceived) async {
    if (!_isInit) await init();

    final channelName = 'private-consultations.$consultationId';
    try {
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          if (event.eventName == 'App\\Events\\ChatMessageSent') {
            final data = jsonDecode(event.data.toString());
            onMessageReceived(data);
          }
        },
      );
      _logger.i('Subscribed to $channelName');
    } catch (e) {
      _logger.e('Failed to subscribe $channelName: $e');
    }
  }

  Future<void> unsubscribe(String consultationId) async {
    final channelName = 'private-consultations.$consultationId';
    await _pusher.unsubscribe(channelName: channelName);
    _logger.i('Unsubscribed from $channelName');
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
