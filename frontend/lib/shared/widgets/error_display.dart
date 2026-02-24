import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.errorColor, size: 32),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall,
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oups ! Quelque chose a mal tourné',
              style: AppTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.neutralGray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
