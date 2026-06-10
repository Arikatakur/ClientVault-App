import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Compact metric card used on the dashboard overview. The value counts up on
/// first build and eases to its new total whenever the underlying data
/// changes.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.format,
    this.accent = AppColors.accent,
  });

  final IconData icon;
  final String label;
  final double value;

  /// Renders the animated value; defaults to a whole-number count.
  final String Function(double value)? format;

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final format = this.format ?? (v) => v.round().toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: AppSpacing.md),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) =>
                  Text(format(animated), style: textTheme.headlineSmall),
            ),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
