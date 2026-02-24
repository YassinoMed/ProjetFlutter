/// Bottom Navigation Scaffold
/// Shared scaffold with animated bottom nav for Patient / Doctor roles
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';

class BottomNavScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;
  final String role;

  const BottomNavScaffold({
    super.key,
    required this.child,
    required this.currentPath,
    required this.role,
  });

  int _currentIndex() {
    if (role == 'patient') {
      if (currentPath.startsWith(AppRoutes.patientAppointments)) return 1;
      if (currentPath.startsWith(AppRoutes.patientChat)) return 2;
      if (currentPath.startsWith(AppRoutes.patientProfile)) return 3;
      return 0;
    } else {
      if (currentPath.startsWith(AppRoutes.doctorAppointments)) return 1;
      if (currentPath.startsWith(AppRoutes.doctorChat)) return 2;
      if (currentPath.startsWith(AppRoutes.doctorProfile)) return 3;
      return 0;
    }
  }

  List<BottomNavigationBarItem> _items() {
    if (role == 'patient') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today_rounded),
          label: 'Rendez-vous',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          activeIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today_rounded),
          label: 'Planning',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          activeIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ];
    }
  }

  void _onTap(BuildContext context, int index) {
    if (role == 'patient') {
      switch (index) {
        case 0:
          context.go(AppRoutes.patientHome);
        case 1:
          context.go(AppRoutes.patientAppointments);
        case 2:
          context.go(AppRoutes.patientChat);
        case 3:
          context.go(AppRoutes.patientProfile);
      }
    } else {
      switch (index) {
        case 0:
          context.go(AppRoutes.doctorHome);
        case 1:
          context.go(AppRoutes.doctorAppointments);
        case 2:
          context.go(AppRoutes.doctorChat);
        case 3:
          context.go(AppRoutes.doctorProfile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex(),
            onTap: (index) => _onTap(context, index),
            items: _items(),
          ),
        ),
      ),
    );
  }
}
