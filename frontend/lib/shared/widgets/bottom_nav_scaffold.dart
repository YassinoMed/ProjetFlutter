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

  List<_NavItemData> _navItems() {
    if (role == 'patient') {
      return const [
        _NavItemData(
          label: 'ACCUEIL',
          route: AppRoutes.patientHome,
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        _NavItemData(
          label: 'RDV',
          route: AppRoutes.patientAppointments,
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
        ),
        _NavItemData(
          label: 'CHAT',
          route: AppRoutes.patientChat,
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
        ),
        _NavItemData(
          label: 'PROFIL',
          route: AppRoutes.patientProfile,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ];
    }

    if (role == 'secretary') {
      return const [
        _NavItemData(
          label: 'CONTEXTE',
          route: AppRoutes.secretaryHome,
          icon: Icons.badge_outlined,
          activeIcon: Icons.badge_rounded,
        ),
        _NavItemData(
          label: 'PLANNING',
          route: AppRoutes.secretaryAppointments,
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
        ),
        _NavItemData(
          label: 'PROFIL',
          route: AppRoutes.secretaryProfile,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ];
    }

    return const [
      _NavItemData(
        label: 'ACCUEIL',
        route: AppRoutes.doctorHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _NavItemData(
        label: 'RDV',
        route: AppRoutes.doctorAppointments,
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      _NavItemData(
        label: 'CHAT',
        route: AppRoutes.doctorChat,
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
      ),
      _NavItemData(
        label: 'PROFIL',
        route: AppRoutes.doctorProfile,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];
  }

  int _currentIndex() {
    if (role == 'patient') {
      if (currentPath.startsWith(AppRoutes.patientAppointments)) return 1;
      if (currentPath.startsWith(AppRoutes.patientChat)) return 2;
      if (currentPath.startsWith(AppRoutes.patientProfile)) return 3;
      return 0;
    } else if (role == 'secretary') {
      if (currentPath.startsWith(AppRoutes.secretaryAppointments)) return 1;
      if (currentPath.startsWith(AppRoutes.secretaryProfile)) return 2;
      return 0;
    } else {
      if (currentPath.startsWith(AppRoutes.doctorAppointments)) return 1;
      if (currentPath.startsWith(AppRoutes.doctorChat)) return 2;
      if (currentPath.startsWith(AppRoutes.doctorProfile)) return 3;
      return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    if (role == 'patient') {
      switch (index) {
        case 0:
          context.go(AppRoutes.patientHome);
          return;
        case 1:
          context.go(AppRoutes.patientAppointments);
          return;
        case 2:
          context.go(AppRoutes.patientChat);
          return;
        case 3:
          context.go(AppRoutes.patientProfile);
          return;
      }
    } else if (role == 'secretary') {
      switch (index) {
        case 0:
          context.go(AppRoutes.secretaryHome);
          return;
        case 1:
          context.go(AppRoutes.secretaryAppointments);
          return;
        case 2:
          context.go(AppRoutes.secretaryProfile);
          return;
      }
    } else {
      switch (index) {
        case 0:
          context.go(AppRoutes.doctorHome);
          return;
        case 1:
          context.go(AppRoutes.doctorAppointments);
          return;
        case 2:
          context.go(AppRoutes.doctorChat);
          return;
        case 3:
          context.go(AppRoutes.doctorProfile);
          return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _navItems();

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: isDark
              ? AppTheme.darkSurfaceDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(22),
                )
              : AppTheme.surfaceDecoration(
                  color: AppTheme.neutralWhite,
                  borderRadius: BorderRadius.circular(22),
                ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == _currentIndex();
              final selectedColor =
                  isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      onTap: () => _onTap(context, index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? (isDark
                                  ? AppTheme.darkCard
                                  : AppTheme.primarySurface)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 20,
                              color: selected
                                  ? selectedColor
                                  : (isDark
                                      ? AppTheme.neutralGray500
                                      : AppTheme.neutralGray500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: AppTheme.labelSmall.copyWith(
                                color: selected
                                    ? selectedColor
                                    : (isDark
                                        ? AppTheme.neutralGray500
                                        : AppTheme.neutralGray500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.route,
    required this.icon,
    required this.activeIcon,
  });
}
