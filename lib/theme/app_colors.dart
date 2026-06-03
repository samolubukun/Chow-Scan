import 'package:flutter/material.dart';

/// Immutable set of surface/text/border colors for one brightness mode.
class AppColorSet {
  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color cardElevated;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnBrand;
  final Color border;
  final Color borderLight;
  final List<Color> surfaceGradient;
  final List<Color> cardGradient;

  const AppColorSet({
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.cardElevated,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnBrand,
    required this.border,
    required this.borderLight,
    required this.surfaceGradient,
    required this.cardGradient,
  });
}

class AppColors {
  // ── Brand / State / Nutrient (same in both themes) ──────────────────
  static const Color brand         = Color(0xFF2ECC71);
  static const Color brandSoft     = Color(0xFF27AE60);
  static const Color brandDim      = Color(0xFF1A8C4A);
  static const Color accent        = Color(0xFFF39C12);
  static const Color accentGlow    = Color(0x33F39C12);

  static const Color success       = Color(0xFF2ECC71);
  static const Color warning       = Color(0xFFF39C12);
  static const Color error         = Color(0xFFE74C3C);
  static const Color info          = Color(0xFF3498DB);

  static const Color nutrientHigh     = Color(0xFF2ECC71);
  static const Color nutrientModerate = Color(0xFFF39C12);
  static const Color nutrientLow      = Color(0xFFE74C3C);

  static const List<Color> brandGradient  = [Color(0xFF2ECC71), Color(0xFF27AE60)];
  static const List<Color> accentGradient = [Color(0xFFF39C12), Color(0xFFE67E22)];

  // ── Legacy dark statics (kept so AppTheme.dark & const widgets compile) ──
  static const Color scaffold     = Color(0xFF0A0A0F);
  static const Color surface      = Color(0xFF141419);
  static const Color surfaceAlt   = Color(0xFF1A1A22);
  static const Color card         = Color(0xFF1E1E28);
  static const Color cardElevated = Color(0xFF252530);
  static const Color background   = Color(0xFF0D0D12);
  static const Color textPrimary  = Color(0xFFF5F5FA);
  static const Color textSecondary= Color(0xFF8E8E9A);
  static const Color textTertiary = Color(0xFF5E5E6E);
  static const Color textOnBrand  = Color(0xFF0D0D12);
  static const Color border       = Color(0xFF2A2A35);
  static const Color borderLight  = Color(0xFF353540);
  static const List<Color> surfaceGradient = [Color(0xFF141419), Color(0xFF1A1A22)];
  static const List<Color> cardGradient    = [Color(0xFF1E1E28), Color(0xFF22222E)];

  // ── Context-aware lookup ─────────────────────────────────────────────
  static AppColorSet of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _dark = AppColorSet(
    scaffold:      Color(0xFF0A0A0F),
    surface:       Color(0xFF141419),
    surfaceAlt:    Color(0xFF1A1A22),
    card:          Color(0xFF1E1E28),
    cardElevated:  Color(0xFF252530),
    background:    Color(0xFF0D0D12),
    textPrimary:   Color(0xFFF5F5FA),
    textSecondary: Color(0xFF8E8E9A),
    textTertiary:  Color(0xFF5E5E6E),
    textOnBrand:   Color(0xFF0D0D12),
    border:        Color(0xFF2A2A35),
    borderLight:   Color(0xFF353540),
    surfaceGradient: [Color(0xFF141419), Color(0xFF1A1A22)],
    cardGradient:    [Color(0xFF1E1E28), Color(0xFF22222E)],
  );

  static const _light = AppColorSet(
    scaffold:      Color(0xFFF4F6F8),
    surface:       Color(0xFFFFFFFF),
    surfaceAlt:    Color(0xFFF0F2F5),
    card:          Color(0xFFFFFFFF),
    cardElevated:  Color(0xFFF9FAFB),
    background:    Color(0xFFF4F6F8),
    textPrimary:   Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textTertiary:  Color(0xFF9CA3AF),
    textOnBrand:   Color(0xFFFFFFFF),
    border:        Color(0xFFE5E7EB),
    borderLight:   Color(0xFFD1D5DB),
    surfaceGradient: [Color(0xFFFFFFFF), Color(0xFFF0F2F5)],
    cardGradient:    [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
  );
}
