library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/clinical_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../secretaries/presentation/widgets/acting_doctor_banner.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (user?.isSecretary == true)
              const ActingDoctorBanner(compact: true),
            if (user?.isSecretary == true) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mon profil',
                    style: AppTheme.headlineSmall,
                  ),
                ),
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClinicalSurface(
              child: Column(
                children: [
                  ClinicalAvatar(
                    name: user?.name ?? 'Utilisateur',
                    imageUrl: user?.avatarUrl,
                    radius: 44,
                  ),
                  const SizedBox(height: 16),
                  Text(user?.name ?? 'Utilisateur',
                      style: AppTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    _roleSubtitle(user),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.neutralGray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ClinicalStatusChip(
                        label: _roleLabel(user).toUpperCase(),
                        color: user?.isDoctor == true
                            ? AppTheme.successColor
                            : user?.isSecretary == true
                                ? AppTheme.warningColor
                                : AppTheme.primaryColor,
                        compact: true,
                      ),
                      if ((user?.email ?? '').isNotEmpty)
                        ClinicalStatusChip(
                          label: user!.email,
                          color: AppTheme.neutralGray500,
                          compact: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ClinicalSurface(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Santé Pass', style: AppTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Votre identité numérique sécurisée pour vos rendez-vous et vos échanges cliniques.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.neutralGray500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const ClinicalStatusChip(
                          label: 'CHIFFRÉ E2E',
                          color: AppTheme.successColor,
                          icon: Icons.lock_rounded,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppTheme.softColor(AppTheme.warningColor, 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppTheme.warningColor,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const ClinicalSectionHeader(title: 'Dossier médical'),
            const SizedBox(height: 12),
            ClinicalSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Informations personnelles',
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  _DividerLine(),
                  _ProfileTile(
                    icon: Icons.folder_open_rounded,
                    title: 'Documents',
                    trailing: const ClinicalStatusChip(
                      label: '12',
                      color: AppTheme.primaryColor,
                      compact: true,
                    ),
                    onTap: () => context.push(AppRoutes.documents),
                  ),
                  if (user?.isDoctor == true) ...[
                    _DividerLine(),
                    _ProfileTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Mes secrétaires',
                      subtitle: 'Invitations et permissions',
                      onTap: () => context.push(AppRoutes.doctorSecretaries),
                    ),
                  ],
                  if (user?.isSecretary == true) ...[
                    _DividerLine(),
                    _ProfileTile(
                      icon: Icons.badge_outlined,
                      title: 'Mes délégations',
                      subtitle: 'Choisir le médecin actif',
                      onTap: () => context.go(AppRoutes.secretaryHome),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const ClinicalSectionHeader(title: 'Préférences'),
            const SizedBox(height: 12),
            ClinicalSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.shield_outlined,
                    title: 'Confidentialité & RGPD',
                    onTap: () => context.push(AppRoutes.gdprSettings),
                  ),
                  _DividerLine(),
                  _ProfileTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sécurité & mot de passe',
                    onTap: () => context.push(AppRoutes.changePassword),
                  ),
                  _DividerLine(),
                  _ProfileTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Exporter données RGPD'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text(
                      'Voulez-vous vraiment fermer votre session ?',
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

                if (shouldLogout != true) return;

                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Déconnexion'),
            ),
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

  String _roleSubtitle(user) {
    if (user?.isDoctor == true) {
      return user?.speciality ?? 'Professionnel de santé';
    }
    if (user?.isSecretary == true) {
      return 'Assistante rattachée à un praticien';
    }
    return 'Patient depuis MediConnect Pro';
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.neutralGray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: AppTheme.titleSmall),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray500,
              ),
            ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.neutralGray400,
          ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}
