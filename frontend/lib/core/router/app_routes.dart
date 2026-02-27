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

  // ── Patient Sub-routes ──────────────────────────────────
  static const String doctorSearch = '/patient/search';
  static const String doctorDetail = '/patient/doctor/:id';
  static const String bookAppointment = '/patient/book/:doctorId';
  static const String appointmentDetail = '/patient/appointment/:id';
  static const String chatDetail = '/patient/chat/:conversationId';
  static const String videoCall = '/video-call/:appointmentId';

  // ── Doctor Routes ───────────────────────────────────────
  static const String doctorHome = '/doctor';
  static const String doctorAppointments = '/doctor/appointments';
  static const String doctorChat = '/doctor/chat';
  static const String doctorProfile = '/doctor/profile';
  static const String doctorPatients = '/doctor/patients';

  // ── Doctor Sub-routes ───────────────────────────────────
  static const String doctorAppointmentDetail = '/doctor/appointment/:id';
  static const String doctorChatDetail = '/doctor/chat/:conversationId';
  static const String patientDetail = '/doctor/patient/:id';

  // ── Medical Records ─────────────────────────────────────
  static const String recordDetail = '/records/:id';
  static const String addRecord = '/records/add';

  // ── Settings ────────────────────────────────────────────
  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';
  static const String changePassword = '/settings/password';
  static const String gdprSettings = '/settings/gdpr';
  static const String notifications = '/settings/notifications';
}
