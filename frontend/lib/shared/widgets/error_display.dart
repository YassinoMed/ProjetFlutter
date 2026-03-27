import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'clinical_ui.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  const ErrorDisplay({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: ClinicalSurface(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.errorColor,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClinicalEmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Connexion indisponible',
      message: message,
      action: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: onRetry,
          child: const Text('Réessayer'),
        ),
      ),
    );
  }
}
