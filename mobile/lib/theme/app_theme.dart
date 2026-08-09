import 'package:flutter/material.dart';

/// Семантические цвета дизайн-системы, которых не хватает в стандартном
/// [ColorScheme] (карточки, границы, фон блокировки и т.д.) — единая точка,
/// через которую экраны читают цвета вместо `Color(0xFF...)` литералов, чтобы
/// тёмная тема применялась автоматически везде, где экран сконвертирован.
///
/// Конвертированы: main_shell, все settings_*.dart, settings_widgets.dart,
/// primary_button.dart, option_card.dart, course_map_tab.dart, profile_screen
/// (основная хром-разметка), lesson_screen (основной фон/аппбар/заголовки).
/// НЕ тронуты: остальные экраны с большим числом хардкод-цветов (см. отчёт) —
/// там тёмная тема пока не работает, они используют цвета светлой темы всегда.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color card;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentDark;
  final Color accentBg;
  final Color success;
  final Color successBg;
  final Color error;
  final Color errorBg;
  final Color streak;
  final Color stars;
  final Color locked;
  final Color lockedBg;
  final Color terminalBg;

  const AppColors({
    required this.background,
    required this.card,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentDark,
    required this.accentBg,
    required this.success,
    required this.successBg,
    required this.error,
    required this.errorBg,
    required this.streak,
    required this.stars,
    required this.locked,
    required this.lockedBg,
    required this.terminalBg,
  });

  static const light = AppColors(
    background: Color(0xFFF6F9F9),
    card: Colors.white,
    border: Color(0xFFDCE8E7),
    divider: Color(0xFFEEF4F3),
    textPrimary: Color(0xFF1B2430),
    textSecondary: Color(0xFF5C6B73),
    accent: Color(0xFF00C9B7),
    accentDark: Color(0xFF00A896),
    accentBg: Color(0xFFE3F8F6),
    success: Color(0xFF58CC02),
    successBg: Color(0xFFEAF9DC),
    error: Color(0xFFFF4B4B),
    errorBg: Color(0xFFFFEAEA),
    streak: Color(0xFFFF9500),
    stars: Color(0xFFFFD98A),
    locked: Color(0xFFC2CDCD),
    lockedBg: Color(0xFFE7EEEE),
    terminalBg: Color(0xFF1B2430),
  );

  static const dark = AppColors(
    background: Color(0xFF12181A),
    card: Color(0xFF1C2426),
    border: Color(0xFF2A3436),
    divider: Color(0xFF26302F),
    textPrimary: Color(0xFFEAF1F1),
    textSecondary: Color(0xFF8FA0A0),
    accent: Color(0xFF00C9B7),
    accentDark: Color(0xFF3FDCC9),
    accentBg: Color(0xFF163430),
    success: Color(0xFF6FDA1E),
    successBg: Color(0xFF1E3410),
    error: Color(0xFFFF6B6B),
    errorBg: Color(0xFF3A1616),
    streak: Color(0xFFFF9F1A),
    stars: Color(0xFFFFD98A),
    locked: Color(0xFF56605F),
    lockedBg: Color(0xFF20292A),
    terminalBg: Color(0xFF0C1112),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentDark,
    Color? accentBg,
    Color? success,
    Color? successBg,
    Color? error,
    Color? errorBg,
    Color? streak,
    Color? stars,
    Color? locked,
    Color? lockedBg,
    Color? terminalBg,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      accentBg: accentBg ?? this.accentBg,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      streak: streak ?? this.streak,
      stars: stars ?? this.stars,
      locked: locked ?? this.locked,
      lockedBg: lockedBg ?? this.lockedBg,
      terminalBg: terminalBg ?? this.terminalBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentBg: Color.lerp(accentBg, other.accentBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      stars: Color.lerp(stars, other.stars, t)!,
      locked: Color.lerp(locked, other.locked, t)!,
      lockedBg: Color.lerp(lockedBg, other.lockedBg, t)!,
      terminalBg: Color.lerp(terminalBg, other.terminalBg, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00C9B7),
        primary: colors.accent,
        brightness: brightness,
        surface: colors.card,
      ),
      extensions: [colors],
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w600,
          fontSize: 21,
          color: colors.textPrimary,
        ),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: colors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C9B7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
