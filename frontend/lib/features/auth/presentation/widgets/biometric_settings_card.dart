/// Biometric Settings Card Widget
///
/// Reusable card for profile/settings page to toggle biometric auth.
/// Shows current status, allows enable/disable, handles all error states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class BiometricSettingsCard extends ConsumerStatefulWidget {
  const BiometricSettingsCard({super.key});

  @override
  ConsumerState<BiometricSettingsCard> createState() =>
      _BiometricSettingsCardState();
}

class _BiometricSettingsCardState extends ConsumerState<BiometricSettingsCard> {
  bool _isProcessing = false;

  Future<void> _toggleBiometric(bool currentlyEnabled) async {
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(authNotifierProvider.notifier);

      if (currentlyEnabled) {
        // Disable biometric
        final result = await notifier.disableBiometric();
        if (!mounted) return;

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Empreinte digitale désactivée'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      } else {
        // Enable biometric
        final result = await notifier.enableBiometric();
        if (!mounted) return;

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Empreinte digitale activée avec succès !'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = ref.watch(isBiometricEnabledProvider);
    final biometricAvailableAsync = ref.watch(isBiometricAvailableProvider);

    return biometricAvailableAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (isAvailable) {
        if (!isAvailable) {
          return const SizedBox.shrink(); // Hide if biometric not available
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: biometricEnabled
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Theme.of(context).dividerColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: biometricEnabled
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color:
                        biometricEnabled ? AppTheme.primaryColor : Colors.grey,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connexion par empreinte',
                        style: AppTheme.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        biometricEnabled
                            ? 'Activée — connexion rapide par empreinte'
                            : 'Désactivée — utilisez votre mot de passe',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutralGray500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Toggle
                _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch.adaptive(
                        value: biometricEnabled,
                        onChanged: (value) =>
                            _toggleBiometric(biometricEnabled),
                        activeColor: AppTheme.primaryColor,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
