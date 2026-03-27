library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ClinicalSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool dark;
  final bool elevated;
  final BorderRadius? borderRadius;

  const ClinicalSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingMd),
    this.onTap,
    this.color,
    this.dark = false,
    this.elevated = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = dark
        ? AppTheme.darkSurfaceDecoration(
            color: color,
            borderRadius: borderRadius,
          )
        : AppTheme.surfaceDecoration(
            color: color,
            borderRadius: borderRadius,
            elevated: elevated,
          );

    final content = Container(
      decoration: decoration,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class ClinicalSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? eyebrow;

  const ClinicalSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.neutralGray400,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: AppTheme.titleLarge),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class ClinicalStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  const ClinicalStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.softColor(color),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class ClinicalAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final bool online;
  final Color? accentColor;

  const ClinicalAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.online = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor:
              (accentColor ?? AppTheme.primaryColor).withValues(alpha: 0.12),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  initials.isEmpty ? '?' : initials,
                  style: AppTheme.titleSmall.copyWith(
                    color: accentColor ?? AppTheme.primaryColor,
                  ),
                )
              : null,
        ),
        if (online)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: radius * 0.58,
              height: radius * 0.58,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ClinicalSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const ClinicalSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: const Icon(Icons.tune_rounded),
      ),
    );
  }
}

class ClinicalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const ClinicalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.neutralGray500,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
