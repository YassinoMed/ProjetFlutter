/// Application-wide constants for MediConnect Pro
library;

class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────
  static const String appName = 'MediConnect Pro';
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = '1';

  // ── User Roles ────────────────────────────────────────────
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';

  // ── Appointment States (CDC page 14) ──────────────────────
  static const String appointmentPending = 'pending';
  static const String appointmentConfirmed = 'confirmed';
  static const String appointmentInProgress = 'in_progress';
  static const String appointmentCompleted = 'completed';
  static const String appointmentCancelled = 'cancelled';
  static const String appointmentNoShow = 'no_show';

  // ── Message Status (CDC page 12) ──────────────────────────
  static const String messageSent = 'sent';
  static const String messageDelivered = 'delivered';
  static const String messageRead = 'read';

  // ── Notification Types (CDC pages 17-18) ──────────────────
  static const String notifAppointmentReminder = 'appointment_reminder';
  static const String notifAppointmentConfirmed = 'appointment_confirmed';
  static const String notifAppointmentCancelled = 'appointment_cancelled';
  static const String notifNewMessage = 'new_message';
  static const String notifVideoCallIncoming = 'video_call_incoming';
  static const String notifPrescriptionReady = 'prescription_ready';

  // ── Storage Keys ──────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyDbEncryptionKey = 'db_encryption_key';
  static const String keyE2ePrivateKey = 'e2e_private_key';
  static const String keyE2ePublicKey = 'e2e_public_key';

  // ── Date Formats ──────────────────────────────────────────
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

  // ── Validation ────────────────────────────────────────────
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int phoneLength = 10;
  static const int otpLength = 6;

  // ── Animation Durations ───────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 3);
}
