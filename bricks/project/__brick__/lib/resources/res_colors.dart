import 'package:flutter/material.dart';

/// Design token: essential color constants.
///
/// Clean, minimal color palette tokens for the application.
abstract final class ResColors {
  // ── Brand ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Purple

  // ── Surfaces ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // White

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444); // Red
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // ── On-colors & Text ─────────────────────────────────────────────────
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1E293B);
  static const Color onSurface = Color(0xFF334155);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // ── Utility ──────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
