/// Enhanced Notification Service
/// Features: Rich Push (images + action buttons), notification channels,
///           deep link handling, and Live Activities support.
library;

import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

// ── Notification Action Callback ────────────────────────────
typedef NotificationActionCallback = void Function(
    String action, Map<String, dynamic> data);

// ── Live Activity State ─────────────────────────────────────
class LiveActivityState {
  final String? appointmentId;
  final String? doctorName;
  final DateTime? startsAt;
  final String? status;
  final bool isActive;

  const LiveActivityState({
    this.appointmentId,
    this.doctorName,
    this.startsAt,
    this.status,
    this.isActive = false,
  });

  LiveActivityState copyWith({
    String? appointmentId,
    String? doctorName,
    DateTime? startsAt,
    String? status,
    bool? isActive,
  }) {
    return LiveActivityState(
      appointmentId: appointmentId ?? this.appointmentId,
      doctorName: doctorName ?? this.doctorName,
      startsAt: startsAt ?? this.startsAt,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ── Enhanced Notification Service ───────────────────────────

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationActionCallback? _onAction;
  LiveActivityState _liveActivityState = const LiveActivityState();

  LiveActivityState get liveActivityState => _liveActivityState;

  /// Initialize with full Rich Push support.
  Future<void> initialize({NotificationActionCallback? onAction}) async {
    _onAction = onAction;

    // ── Request permissions ──────────────────────────────
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true, // For urgent medical notifications
      provisional: false,
    );

    // ── Create Android notification channels ─────────────
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await _createAndroidChannels(androidPlugin);
    }

    // ── Initialize local notifications with action support ─
    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'APPOINTMENT_ACTIONS',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('view', 'Voir le RDV'),
              DarwinNotificationAction.plain('cancel', 'Annuler',
                  options: {DarwinNotificationActionOption.destructive}),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
          DarwinNotificationCategory(
            'CHAT_ACTIONS',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.text('reply', 'Répondre',
                  buttonTitle: 'Envoyer',
                  placeholder: 'Tapez votre réponse...'),
            ],
          ),
          DarwinNotificationCategory(
            'CALL_ACTIONS',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('accept', 'Accepter',
                  options: {DarwinNotificationActionOption.foreground}),
              DarwinNotificationAction.plain('decline', 'Refuser',
                  options: {DarwinNotificationActionOption.destructive}),
            ],
          ),
        ],
      ),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationAction,
      onDidReceiveBackgroundNotificationResponse:
          _backgroundNotificationHandler,
    );

    // ── Listen for foreground messages ────────────────────
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── Handle notification opens (background/terminated) ─
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was launched from a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // ── Get FCM Token ────────────────────────────────────
    String? token = await _fcm.getToken();
    _logger.i('FCM Token: $token');

    _logger
        .i('EnhancedNotificationService initialized with Rich Push support.');
  }

  // ── Create per-type Android notification channels ─────────

  Future<void> _createAndroidChannels(
      AndroidFlutterLocalNotificationsPlugin plugin) async {
    const channels = [
      AndroidNotificationChannel(
        'appointments',
        'Rendez-vous',
        description: 'Notifications de rendez-vous (confirmations, rappels)',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Messages sécurisés de vos médecins',
        importance: Importance.high,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'calls',
        'Appels vidéo',
        description: 'Appels vidéo entrants',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'medical_records',
        'Dossiers médicaux',
        description: 'Nouvelles ordonnances et résultats',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'general',
        'Général',
        description: 'Notifications générales',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await plugin.createNotificationChannel(channel);
    }
  }

  // ── Handle foreground messages (Rich Push) ────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    _logger.d('Foreground message received: ${message.messageId}');

    final data = message.data;
    final notification = message.notification;
    final type = data['type'] ?? 'default';
    final channelId = _resolveChannel(type);

    // Check for Live Activity update
    if (type == 'APPOINTMENT' &&
        (data['event'] == 'reminder_h1' || data['event'] == 'confirmed')) {
      _startLiveActivity(data);
    }

    if (notification != null) {
      _showRichNotification(
        id: message.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        imageUrl:
            notification.android?.imageUrl ?? notification.apple?.imageUrl,
        channelId: channelId,
        category: _resolveCategory(type),
        data: data,
        actions: _parseActions(data),
      );
    }
  }

  // ── Show Rich Local Notification ──────────────────────────

  Future<void> _showRichNotification({
    required int id,
    required String title,
    required String body,
    String? imageUrl,
    required String channelId,
    String? category,
    Map<String, dynamic>? data,
    List<AndroidNotificationAction>? actions,
  }) async {
    // Android notification details with rich features
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF0D6EFD),
      // Rich push: large icon and big picture
      styleInformation: imageUrl != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imageUrl),
              contentTitle: title,
              summaryText: body,
              htmlFormatContentTitle: true,
            )
          : BigTextStyleInformation(
              body,
              contentTitle: title,
              htmlFormatContentTitle: true,
            ),
      actions: actions,
    );

    // iOS notification details with category for action buttons
    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: category,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: channelId == 'calls'
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // ── Live Activities (iOS 16+) ─────────────────────────────

  void _startLiveActivity(Map<String, dynamic> data) {
    _liveActivityState = LiveActivityState(
      appointmentId: data['appointment_id'],
      doctorName: data['doctor_name'],
      startsAt: data['starts_at_utc'] != null
          ? DateTime.tryParse(data['starts_at_utc'])
          : null,
      status: data['event'],
      isActive: true,
    );

    _logger
        .i('Live Activity started for appointment: ${data['appointment_id']}');

    // NOTE: Production integration with flutter_live_activities:
    //   await _liveActivitiesPlugin.createActivity({
    //     'appointmentId': data['appointment_id'],
    //     'doctorName': data['doctor_name'] ?? 'Dr.',
    //     'startsAt': data['starts_at_utc'],
    //     'status': data['event'],
    //   });
  }

  /// End a Live Activity.
  void endLiveActivity() {
    _liveActivityState = const LiveActivityState();
    _logger.i('Live Activity ended.');

    // NOTE: Production:
    //   await _liveActivitiesPlugin.endAllActivities();
  }

  // ── Action handling ───────────────────────────────────────

  void _handleNotificationAction(NotificationResponse response) {
    _logger.d(
        'Notification action: ${response.actionId} | payload: ${response.payload}');

    final data = response.payload != null
        ? jsonDecode(response.payload!) as Map<String, dynamic>
        : <String, dynamic>{};

    final actionId = response.actionId ?? 'tap';
    _onAction?.call(actionId, data);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.d('App opened from notification: ${message.data}');
    final deepLink = message.data['deep_link'] as String?;
    if (deepLink != null) {
      _onAction?.call('deep_link', {'deep_link': deepLink, ...message.data});
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  String _resolveChannel(String type) {
    return switch (type) {
      'APPOINTMENT' => 'appointments',
      'CHAT' => 'messages',
      'CALL' => 'calls',
      'MEDICAL_RECORD' => 'medical_records',
      _ => 'general',
    };
  }

  String? _resolveCategory(String type) {
    return switch (type) {
      'APPOINTMENT' => 'APPOINTMENT_ACTIONS',
      'CHAT' => 'CHAT_ACTIONS',
      'CALL' => 'CALL_ACTIONS',
      _ => null,
    };
  }

  List<AndroidNotificationAction>? _parseActions(Map<String, dynamic> data) {
    final actionsJson = data['actions'];
    if (actionsJson == null) return null;

    try {
      final actions = jsonDecode(actionsJson as String) as List;
      return actions.map<AndroidNotificationAction>((a) {
        return AndroidNotificationAction(
          a['id'] as String,
          a['title'] as String,
          showsUserInterface: true,
        );
      }).toList();
    } catch (e) {
      return null;
    }
  }
}

// ── Background handler (must be top-level) ──────────────────
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse response) {
  // Background action handling (limited)
  Logger().d('Background notification action: ${response.actionId}');
}

// ── Provider ────────────────────────────────────────────────

final enhancedNotificationServiceProvider =
    Provider<EnhancedNotificationService>((ref) {
  return EnhancedNotificationService();
});

final liveActivityStateProvider = Provider<LiveActivityState>((ref) {
  return ref.watch(enhancedNotificationServiceProvider).liveActivityState;
});
