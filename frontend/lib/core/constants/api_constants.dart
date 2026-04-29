/// API Constants for MediConnect Pro
/// Ref CDC: Configuration réseau et endpoints API
/// v2.1: Added Reverb WebSocket, E2EE attachments, RGPD data retention
library;

class ApiConstants {
  ApiConstants._();

  // ── Base URLs ─────────────────────────────────────────────
  static const String baseUrl = 'http://51.210.243.30:8081/api';
  static const String baseUrlIos = 'http://51.210.243.30:8081/api';
  static const String baseUrlProd = 'http://51.210.243.30:8081/api';

  // ── WebSocket (Reverb – Laravel native) ───────────────────
  static const String wsUrl = 'http://51.210.243.30:8081';
  static const String wsUrlIos = 'http://51.210.243.30:8081';
  static const String wsUrlProd = 'http://51.210.243.30:8081';

  // Reverb app credentials (must match backend .env)
  static const String reverbAppKey = 'mediconnect-key';
  static const String reverbAppCluster = 'mt1';

  // ── Default Tenant ────────────────────────────────────────
  static const String defaultTenantId = 'mediconnect';

  // ── Auth Endpoints ────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ── Biometric & Device Endpoints ──────────────────────────
  static const String enableBiometric = '/auth/enable-biometric';
  static const String disableBiometric = '/auth/disable-biometric';
  static const String devices = '/auth/devices';
  static const String revokeDevice = '/auth/devices'; // + /{deviceId}

  // ── Appointments Endpoints ────────────────────────────────
  static const String appointments = '/appointments';
  static const String appointmentCreate = '/appointments';
  static const String appointmentShow = '/appointments/{id}';
  static const String appointmentCancel = '/appointments/{id}/cancel';
  static const String appointmentConfirm = '/appointments/{id}/confirm';
  static const String appointmentReject = '/appointments/{id}/reject';

  // ── Doctors Endpoints ─────────────────────────────────────
  static const String doctors = '/doctors';
  static const String doctorShow = '/doctors/{id}';
  static const String doctorSlots = '/doctors/{id}/slots';
  static const String doctorSpecialties = '/doctors/specialties';

  // ── Doctor Schedule (doctor-only) ─────────────────────────
  static const String schedule = '/schedule';
  static const String scheduleBulk = '/schedule/bulk';

  // ── Chat Endpoints (consultation-based) ───────────────────
  static const String consultationMessages = '/consultations/{id}/messages';
  static const String consultationMessageAck =
      '/consultations/{id}/messages/{msgId}/ack';

  // ── Secure Conversations / E2EE Transport ─────────────────
  static const String conversations = '/conversations';
  static const String conversationShow = '/conversations/{id}';
  static const String conversationMessages = '/conversations/{id}/messages';
  static const String conversationTyping = '/conversations/{id}/typing';
  static const String secureMessages = '/messages';
  static const String secureMessageDelivered = '/messages/{id}/delivered';
  static const String secureMessageRead = '/messages/{id}/read';
  static const String e2eeDevices = '/e2ee/devices';
  static const String e2eePeerBundle = '/e2ee/users/{userId}/bundle';

  // ── WebRTC Signaling ──────────────────────────────────────
  static const String webrtcJoin = '/consultations/{id}/webrtc/join';
  static const String webrtcOffer = '/consultations/{id}/webrtc/offer';
  static const String webrtcAnswer = '/consultations/{id}/webrtc/answer';
  static const String webrtcIce = '/consultations/{id}/webrtc/ice';

  // ── Medical Records ───────────────────────────────────────
  static const String medicalRecords = '/medical-records';
  static const String medicalRecordShow = '/medical-records/{id}';

  // ── Medical Documents AI ───────────────────────────────
  static const String documents = '/documents';
  static const String documentUpload = '/documents/upload';
  static const String documentShow = '/documents/{id}';
  static const String documentProcessing = '/documents/{id}/processing';
  static const String documentSummary = '/documents/{id}/summary';
  static const String documentEntities = '/documents/{id}/entities';
  static const String documentReanalyze = '/documents/{id}/reanalyze';
  static const String documentAsk = '/documents/{id}/ask';

  // ── Teleconsultations ───────────────────────────────────
  static const String teleconsultations = '/teleconsultations';
  static const String teleconsultationShow = '/teleconsultations/{id}';
  static const String teleconsultationStart = '/teleconsultations/{id}/start';
  static const String teleconsultationJoin = '/teleconsultations/{id}/join';
  static const String teleconsultationCancel = '/teleconsultations/{id}/cancel';
  static const String teleconsultationEnd = '/teleconsultations/{id}/end';
  static const String teleconsultationOffer =
      '/teleconsultations/{id}/signal/offer';
  static const String teleconsultationAnswer =
      '/teleconsultations/{id}/signal/answer';
  static const String teleconsultationIce =
      '/teleconsultations/{id}/signal/ice-candidate';
  static const String teleconsultationEvents = '/teleconsultations/{id}/events';

  // ── E2EE Encrypted Attachments ────────────────────────────
  static const String attachmentUpload = '/attachments/upload';
  static const String attachmentShow = '/attachments/{id}';
  static const String attachmentDownload = '/attachments/{id}/download';
  static const String attachmentDelete = '/attachments/{id}';

  // ── FCM Token ─────────────────────────────────────────────
  static const String fcmTokenUpsert = '/fcm/tokens';
  static const String fcmTokenDelete = '/fcm/tokens';
  static const String fcmTokenHeartbeat = '/fcm/tokens/heartbeat';

  // ── Profile ───────────────────────────────────────────────
  static const String profile = '/profile';
  static const String profilePassword = '/profile/password';

  // ── Secretary Delegation ─────────────────────────────────
  static const String doctorSecretaries = '/doctor/secretaries';
  static const String secretaryInvitationAccept =
      '/secretary/invitations/accept';
  static const String meDelegations = '/me/delegations';
  static const String switchDoctorContext = '/context/switch-doctor';

  // ── RGPD ──────────────────────────────────────────────────
  static const String rgpdExport = '/rgpd/export';
  static const String rgpdConsent = '/rgpd/consent';
  static const String rgpdForget = '/rgpd/forget';

  // ── Timeouts ──────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Pagination ────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int messagesPageSize = 50;

  // ── Data Retention (RGPD) ─────────────────────────────────
  static const int chatMessageTtlDays = 730; // 2 years default
  static const int medicalRecordTtlDays = 3650; // 10 years default
}
