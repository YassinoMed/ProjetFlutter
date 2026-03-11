/// Profile Page - User profile management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../secretaries/presentation/widgets/acting_doctor_banner.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (user?.isSecretary == true) const ActingDoctorBanner(compact: true),
            if (user?.isSecretary == true) const SizedBox(height: 20),
            // ── Avatar ────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.medicalGradient,
                      boxShadow: AppTheme.shadowPrimary,
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: AppTheme.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Utilisateur',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user?.isDoctor == true
                          ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                          : user?.isSecretary == true
                              ? AppTheme.warningColor.withValues(alpha: 0.1)
                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleLabel(user),
                      style: AppTheme.labelSmall.copyWith(
                        color: user?.isDoctor == true
                            ? AppTheme.secondaryColor
                            : user?.isSecretary == true
                                ? AppTheme.warningColor
                                : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neutralGray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Menu Items ────────────────────────
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Informations personnelles',
              onTap: () {
                context.push(AppRoutes.editProfile);
              },
            ),
            if (user?.isDoctor == true)
              _buildMenuItem(
                icon: Icons.support_agent_rounded,
                title: 'Mes secrétaires',
                subtitle: 'Invitations, permissions, suspension',
                onTap: () {
                  context.push(AppRoutes.doctorSecretaries);
                },
              ),
            if (user?.isSecretary == true)
              _buildMenuItem(
                icon: Icons.badge_outlined,
                title: 'Mes délégations',
                subtitle: 'Choisir le médecin actif',
                onTap: () {
                  context.go(AppRoutes.secretaryHome);
                },
              ),
            _buildMenuItem(
              icon: Icons.folder_open_rounded,
              title: 'Dossier médical',
              onTap: () {
                context.push(AppRoutes.documents);
              },
            ),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.shield_outlined,
              title: 'Confidentialité & RGPD',
              onTap: () {
                context.push(AppRoutes.gdprSettings);
              },
            ),
            _buildMenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Sécurité & Mot de passe',
              onTap: () {
                context.push(AppRoutes.changePassword);
              },
            ),
            _buildMenuItem(
              icon: Icons.dark_mode_outlined,
              title: 'Apparence',
              subtitle: 'Clair',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.language_outlined,
              title: 'Langue',
              subtitle: 'Français',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Aide & Support',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // ── Logout Button ─────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text(
                        'Êtes-vous sûr de vouloir vous déconnecter ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                          ),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Se déconnecter'),
              ),
            ),
            const SizedBox(height: 16),

            // ── Version ───────────────────────────
            Text(
              'MediConnect Pro v2.0.0',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray400,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _roleLabel(user) {
    if (user?.isDoctor == true) return 'Médecin';
    if (user?.isSecretary == true) return 'Secrétaire';
    return 'Patient';
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.neutralGray100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.neutralGray600, size: 20),
      ),
      title: Text(title, style: AppTheme.titleSmall),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray500,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.neutralGray400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onTap: onTap,
    );
  }
}
