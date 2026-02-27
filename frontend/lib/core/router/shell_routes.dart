/// Shell Routes - Bottom Navigation for Patient and Doctor
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/appointments/presentation/pages/doctor_search_page.dart';
import '../../features/chat/presentation/pages/conversations_page.dart';
import '../../features/home/presentation/pages/doctor_home_page.dart';
import '../../features/home/presentation/pages/patient_home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../shared/widgets/bottom_nav_scaffold.dart';
import 'app_routes.dart';

// ── Patient Shell Route ─────────────────────────────────────

final patientShellRoute = ShellRoute(
  builder: (context, state, child) {
    return BottomNavScaffold(
      currentPath: state.matchedLocation,
      role: 'patient',
      child: child,
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.patientHome,
      name: 'patient-home',
      builder: (context, state) => const PatientHomePage(),
      routes: [
        GoRoute(
          path: 'search', // This maps to /patient/search
          name: 'doctor-search',
          builder: (context, state) => const DoctorSearchPage(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.patientAppointments,
      name: 'patient-appointments',
      builder: (context, state) => const AppointmentsPage(),
    ),
    GoRoute(
      path: AppRoutes.patientChat,
      name: 'patient-chat',
      builder: (context, state) => const ConversationsPage(),
    ),
    GoRoute(
      path: AppRoutes.patientProfile,
      name: 'patient-profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);

// ── Doctor Shell Route ──────────────────────────────────────

final doctorShellRoute = ShellRoute(
  builder: (context, state, child) {
    return BottomNavScaffold(
      currentPath: state.matchedLocation,
      role: 'doctor',
      child: child,
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.doctorHome,
      name: 'doctor-home',
      builder: (context, state) => const DoctorHomePage(),
    ),
    GoRoute(
      path: AppRoutes.doctorAppointments,
      name: 'doctor-appointments',
      builder: (context, state) => const AppointmentsPage(),
    ),
    GoRoute(
      path: AppRoutes.doctorChat,
      name: 'doctor-chat',
      builder: (context, state) => const ConversationsPage(),
    ),
    GoRoute(
      path: AppRoutes.doctorProfile,
      name: 'doctor-profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);

// ── Temporary Placeholder Widgets ───────────────────────────

class PatientHomePlaceholder extends StatelessWidget {
  const PatientHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Patient Home - Coming Soon')),
    );
  }
}
