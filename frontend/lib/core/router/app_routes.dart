/// Route Constants
/// All named routes for the application
library;

class AppRoutes {
  AppRoutes._();

  // ── Core ────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Patient Routes ──────────────────────────────────────
  static const String patientHome = '/patient';
  static const String patientAppointments = '/patient/appointments';
  static const String patientChat = '/patient/chat';
  static const String patientProfile = '/patient/profile';
  static const String patientRecords = '/patient/records';
  static const String documents = '/documents';
  static const String teleconsultations = '/teleconsultations';

  // ── Patient Sub-routes ──────────────────────────────────
  static const String doctorSearch = '/patient/search';
  static const String doctorDetail = '/patient/doctor/:id';
  static const String bookAppointment = '/patient/book/:doctorId';
  static const String appointmentDetail = '/patient/appointment/:id';
  static const String chatDetail = '/patient/chat/:conversationId';
  static const String videoCall = '/video-call/:appointmentId';
  static const String teleconsultationDetail = '/teleconsultations/:id';
  static const String incomingTeleconsultationCall =
      '/teleconsultations/incoming/:id';

  // ── Doctor Routes ───────────────────────────────────────
  static const String doctorHome = '/doctor';
  static const String doctorAppointments = '/doctor/appointments';
  static const String doctorChat = '/doctor/chat';
  static const String doctorProfile = '/doctor/profile';
  static const String doctorPatients = '/doctor/patients';
  static const String doctorSecretaries = '/doctor/secretaries';

  // ── Doctor Sub-routes ───────────────────────────────────
  static const String doctorAppointmentDetail = '/doctor/appointment/:id';
  static const String doctorChatDetail = '/doctor/chat/:conversationId';
  static const String patientDetail = '/doctor/patient/:id';

  // ── Secretary Routes ────────────────────────────────────
  static const String secretaryHome = '/secretary';
  static const String secretaryAppointments = '/secretary/appointments';
  static const String secretaryProfile = '/secretary/profile';

  // ── Medical Records ─────────────────────────────────────
  static const String recordDetail = '/records/:id';
  static const String addRecord = '/records/add';
  static const String documentUpload = '/documents/upload';
  static const String documentDetail = '/documents/:id';

  // ── Settings ────────────────────────────────────────────
  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';
  static const String changePassword = '/settings/password';
  static const String gdprSettings = '/settings/gdpr';
  static const String notifications = '/settings/notifications';
  static const String trustedDevices = '/settings/devices';
}
