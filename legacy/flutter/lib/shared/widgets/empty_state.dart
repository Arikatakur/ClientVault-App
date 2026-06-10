import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A centered, friendly placeholder for empty or unavailable screens.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child:
            Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 32, color: AppColors.accent),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      style: textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (action != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      action!,
                    ],
                  ],
                )
                .animate()
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.96, 0.96),
                  end: const Offset(1, 1),
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ),
      ),
    );
  }
}
