/// GoRouter Configuration
/// CDC: Navigation with role-based redirects (Patient / Médecin)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/pages/booking_page.dart';
import '../../features/appointments/presentation/pages/doctor_detail_page.dart';
import '../../features/appointments/presentation/pages/appointment_detail_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/trusted_devices_page.dart';
import '../../features/chat/presentation/pages/chat_detail_page.dart';
import '../../features/documents/presentation/pages/document_detail_page.dart';
import '../../features/documents/presentation/pages/document_upload_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/medical_records/presentation/pages/add_record_page.dart';
import '../../features/medical_records/presentation/pages/medical_records_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/gdpr_settings_page.dart';
import '../../features/secretaries/presentation/pages/doctor_secretaries_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/video_call/presentation/pages/video_call_page.dart';
import '../constants/app_constants.dart';
import 'app_routes.dart';
import 'shell_routes.dart';

/// Global navigator keys
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuth = authState.valueOrNull?.isAuthenticated ?? false;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.onboarding;

      if (isOnSplash) return null;
      if (!isAuth && !isOnAuth) return AppRoutes.login;

      if (isAuth && isOnAuth) {
        final role = authState.valueOrNull?.user?.role;
        if (role == AppConstants.roleDoctor) {
          return AppRoutes.doctorHome;
        }
        if (role == AppConstants.roleSecretary) {
          return AppRoutes.secretaryHome;
        }
        return AppRoutes.patientHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.bookAppointment,
        name: 'book-appointment',
        builder: (context, state) {
          final doctorId = state.pathParameters['doctorId']!;
          return BookingPage(doctorId: doctorId);
        },
      ),
      GoRoute(
        path: AppRoutes.doctorDetail,
        name: 'doctor-detail',
        builder: (context, state) {
          final doctorId = state.pathParameters['id']!;
          return DoctorDetailPage(doctorId: doctorId);
        },
      ),
      GoRoute(
        path: AppRoutes.appointmentDetail,
        name: 'appointment-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AppointmentDetailPage(appointmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.doctorAppointmentDetail,
        name: 'doctor-appointment-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AppointmentDetailPage(appointmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        name: 'chat-detail',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatDetailPage(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: AppRoutes.videoCall,
        name: 'video-call',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId']!;
          return VideoCallPage(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: AppRoutes.documents,
        name: 'documents',
        builder: (context, state) => const DocumentsPage(),
      ),
      GoRoute(
        path: AppRoutes.documentDetail,
        name: 'document-detail',
        builder: (context, state) {
          final documentId = state.pathParameters['id']!;
          return DocumentDetailPage(documentId: documentId);
        },
      ),
      GoRoute(
        path: AppRoutes.documentUpload,
        name: 'document-upload',
        builder: (context, state) => const DocumentUploadPage(),
      ),
      GoRoute(
        path: AppRoutes.patientRecords,
        name: 'medical-records',
        builder: (context, state) => const MedicalRecordsPage(),
      ),
      GoRoute(
        path: AppRoutes.addRecord,
        name: 'add-record',
        builder: (context, state) => const AddRecordPage(),
      ),
      GoRoute(
        path: AppRoutes.gdprSettings,
        name: 'gdpr-settings',
        builder: (context, state) => const GdprSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.trustedDevices,
        name: 'trusted-devices',
        builder: (context, state) => const TrustedDevicesPage(),
      ),
      GoRoute(
        path: AppRoutes.doctorSecretaries,
        name: 'doctor-secretaries',
        builder: (context, state) => const DoctorSecretariesPage(),
      ),
      patientShellRoute,
      doctorShellRoute,
      secretaryShellRoute,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page non trouvée',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});
