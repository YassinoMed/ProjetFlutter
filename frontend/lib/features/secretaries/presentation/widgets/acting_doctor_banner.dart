library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/doctor_secretary_delegation_entity.dart';
import '../providers/secretary_providers.dart';

class ActingDoctorBanner extends ConsumerWidget {
  final bool compact;

  const ActingDoctorBanner({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDelegation = ref.watch(secretaryContextProvider);

    return activeDelegation.when(
      data: (delegation) {
        if (delegation == null) {
          return _BannerShell(
            compact: compact,
            title: 'Aucun médecin actif',
            subtitle: 'Choisissez un médecin avant toute action déléguée.',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.warningColor,
          );
        }

        final doctorName = delegation.doctor?.fullName.isNotEmpty == true
            ? delegation.doctor!.fullName
            : 'Dr ${delegation.doctorUserId}';

        return _BannerShell(
          compact: compact,
          title: 'Vous agissez pour le compte du $doctorName',
          subtitle: 'Permissions actives: ${delegation.permissions.join(', ')}',
          icon: Icons.verified_user_outlined,
          color: AppTheme.primaryColor,
          trailing: compact
              ? null
              : TextButton(
                  onPressed: () =>
                      ref.read(secretaryContextProvider.notifier).clear(),
                  child: const Text('Quitter'),
                ),
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BannerShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  final bool compact;

  const _BannerShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.compact,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 0 : 16, 12, compact ? 0 : 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
