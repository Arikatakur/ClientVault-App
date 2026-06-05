import 'package:flutter/material.dart';

/// Color tokens for ClientVault's dark-first "secure fintech" aesthetic:
/// a deep neutral slate base, one vivid accent, and a small semantic set.
abstract final class AppColors {
  AppColors._();

  // Backgrounds & surfaces.
  static const Color background = Color(0xFF0B0D11);
  static const Color surface = Color(0xFF14171D);
  static const Color surfaceElevated = Color(0xFF1B1F27);
  static const Color outline = Color(0xFF262B34);

  // Brand accent (the single vivid color).
  static const Color accent = Color(0xFF7B61FF);
  static const Color accentSoft = Color(0xFF2A2440);

  // Semantic.
  static const Color success = Color(0xFF34D399); // e.g. paid
  static const Color warning = Color(0xFFF59E0B); // e.g. overdue / attention
  static const Color danger = Color(0xFFF87171);

  // Text.
  static const Color textPrimary = Color(0xFFECEEF2);
  static const Color textSecondary = Color(0xFF9BA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
}
