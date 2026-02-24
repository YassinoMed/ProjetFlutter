/// API Constants for MediConnect Pro
/// Ref CDC: Configuration réseau et endpoints API
/// v2.1: Added Reverb WebSocket, E2EE attachments, RGPD data retention
library;

class ApiConstants {
  ApiConstants._();

  // ── Base URLs ─────────────────────────────────────────────
  /// Auto: use baseUrlIos on iOS simulator, baseUrl on Android emulator
  static const String baseUrl = 'http://192.168.1.173:8080/api';
  static const String baseUrlIos = 'http://192.168.1.173:8080/api';
  static const String baseUrlProd = 'https://api.mediconnect.pro/api/v1';

  // ── WebSocket (Reverb – Laravel native) ───────────────────
  static const String wsUrl = 'http://192.168.1.173:8080';
  static const String wsUrlIos = 'http://192.168.1.173:8080';
  static const String wsUrlProd = 'wss://ws.mediconnect.pro';

  // Reverb app credentials (must match backend .env)
  static const String reverbAppKey = 'mediconnect-key';
  static const String reverbAppCluster = 'mt1';

  // ── Auth Endpoints ────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String profile = '/auth/profile';

  // ── Appointments Endpoints ────────────────────────────────
  static const String appointments = '/appointments';
  static const String appointmentCreate = '/appointments';
  static const String appointmentCancel = '/appointments/{id}/cancel';
  static const String appointmentConfirm = '/appointments/{id}/confirm';
  static const String appointmentComplete = '/appointments/{id}/complete';

  // ── Doctors Endpoints ─────────────────────────────────────
  static const String doctors = '/doctors';
  static const String doctorSearch = '/doctors/search';
  static const String doctorAvailability = '/doctors/{id}/availability';
  static const String doctorReviews = '/doctors/{id}/reviews';

  // ── Chat Endpoints ────────────────────────────────────────
  static const String conversations = '/conversations';
  static const String messages = '/conversations/{id}/messages';
  static const String sendMessage = '/conversations/{id}/messages';
  static const String markAsRead = '/conversations/{id}/read';

  // ── Medical Records ───────────────────────────────────────
  static const String medicalRecords = '/medical-records';
  static const String medicalRecordUpload = '/medical-records/upload';
  static const String medicalRecordExport = '/medical-records/export';

  // ── E2EE Encrypted Attachments (v2.1) ─────────────────────
  static const String attachmentUpload = '/attachments/upload';
  static const String attachmentShow = '/attachments/{id}';
  static const String attachmentDownload = '/attachments/{id}/download';
  static const String attachmentDelete = '/attachments/{id}';

  // ── RGPD ──────────────────────────────────────────────────
  static const String gdprExport = '/rgpd/export';
  static const String gdprConsent = '/rgpd/consent';
  static const String gdprForget = '/rgpd/forget';

  // ── Video Call ────────────────────────────────────────────
  static const String videoCallToken = '/video-call/token';
  static const String videoCallSignal = '/video-call/signal';

  // ── Notifications ─────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationRead = '/notifications/{id}/read';
  static const String fcmToken = '/notifications/fcm-token';

  // ── Timeouts ──────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── JWT ───────────────────────────────────────────────────
  static const int accessTokenExpiryMinutes = 15;
  static const int refreshTokenExpiryDays = 7;

  // ── Pagination ────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int messagesPageSize = 50;

  // ── Data Retention (RGPD v2.1) ────────────────────────────
  static const int chatMessageTtlDays = 730; // 2 years default
  static const int medicalRecordTtlDays = 3650; // 10 years default
}
