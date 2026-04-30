import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/network/dio_client.dart';
import 'package:mediconnect_pro/core/notifications/notification_service.dart';

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for FCM token operations
final fcmTokenProvider =
    StateNotifierProvider<FcmTokenNotifier, String?>((ref) {
  final dio = ref.watch(dioProvider);
  return FcmTokenNotifier(dio);
});

class FcmTokenNotifier extends StateNotifier<String?> {
  final dynamic _dio;

  FcmTokenNotifier(this._dio) : super(null);

  /// Register FCM token with the backend
  Future<void> registerToken(String token, String platform) async {
    try {
      await _dio.post(ApiConstants.fcmTokenUpsert, data: {
        'token': token,
        'platform': platform,
      });

      await _dio.post(ApiConstants.devicePushTokenRegister, data: {
        'token': token,
        'provider': 'FCM',
        'platform': platform,
      });

      state = token;
    } catch (e) {
      // Silently fail — token will be retried on next app launch
    }
  }

  /// Remove FCM token from backend
  Future<void> removeToken() async {
    final token = state;
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _dio.delete(ApiConstants.fcmTokenDelete, data: {'token': token});
      await _dio.delete(
        ApiConstants.devicePushTokenDelete,
        data: {'token': token},
      );
      state = null;
    } catch (e) {
      // Silently fail
    }
  }

  /// Heartbeat to keep token alive
  Future<void> heartbeat() async {
    final token = state;
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _dio.post(ApiConstants.fcmTokenHeartbeat, data: {'token': token});
      await _dio.post(
        ApiConstants.devicePushTokenHeartbeat,
        data: {'token': token},
      );
    } catch (e) {
      // Silently fail
    }
  }
}

/// Notification payload data class
class NotificationPayload {
  final String type;
  final String? appointmentId;
  final String? callerUserId;
  final String? callerName;
  final String? callType;
  final String? messagePreview;
  final String? timestampUtc;

  NotificationPayload({
    required this.type,
    this.appointmentId,
    this.callerUserId,
    this.callerName,
    this.callType,
    this.messagePreview,
    this.timestampUtc,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type']?.toString() ?? 'unknown',
      appointmentId: json['appointment_id']?.toString(),
      callerUserId: json['caller_user_id']?.toString(),
      callerName: json['caller_name']?.toString(),
      callType: json['call_type']?.toString(),
      messagePreview: json['message_preview']?.toString(),
      timestampUtc: json['timestamp_utc']?.toString(),
    );
  }

  /// Whether this is an incoming call notification
  bool get isIncomingCall => type == 'incoming_call';

  /// Whether this is a chat message notification
  bool get isChatMessage => type == 'new_message';

  /// Whether this is an appointment notification
  bool get isAppointment =>
      type.startsWith('appointment_') || type.startsWith('reminder_');
}
