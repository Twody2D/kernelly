import 'package:flutter/material.dart';

/// Медаль достижения — кубок из Icons.emoji_events_rounded с градиентной
/// заливкой и тенью. Раньше форма рисовалась вручную (CustomPainter) и
/// получалась то шаром, то кривым силуэтом с непостоянным отступом до
/// подписи — иконка из Material-набора решает оба вопроса разом: она
/// всегда одной и той же формы и всегда одного размера в своём боксе.
class AchievementBadge extends StatelessWidget {
  final String icon;
  final String style;
  final bool unlocked;
  final double size;

  /// Не используется — оставлен для совместимости вызовов, форма больше не
  /// зависит от конкретного достижения.
  final String? seed;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.style,
    required this.unlocked,
    this.size = 56,
    this.seed,
  });

  // 5 уровней достижений (бронза → бедрок) плюс запертое состояние.
  static const _colors = {
    'bronze': (
      light: Color(0xFFE8B98C),
      base: Color(0xFFC97A3D),
      dark: Color(0xFF8A4E1F),
    ),
    'silver': (
      light: Color(0xFFE8EDF0),
      base: Color(0xFFB8C4CC),
      dark: Color(0xFF7A8A94),
    ),
    'gold': (
      light: Color(0xFFFFE9B0),
      base: Color(0xFFFFC72E),
      dark: Color(0xFFB8791A),
    ),
    'diamond': (
      light: Color(0xFFC2F0F5),
      base: Color(0xFF4FD8E8),
      dark: Color(0xFF1E9CAD),
    ),
    'bedrock': (
      light: Color(0xFFB3A8C4),
      base: Color(0xFF6B5A80),
      dark: Color(0xFF3A2E4D),
    ),
  };

  static const _locked = (
    light: Color(0xFFE3EAEA),
    base: Color(0xFFCED9D9),
    dark: Color(0xFFA0ACAC),
  );

  @override
  Widget build(BuildContext context) {
    final palette = unlocked ? (_colors[style] ?? _colors['bronze']!) : _locked;
    final showChip = unlocked && icon.length > 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.light, palette.base, palette.dark],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(rect),
            child: Icon(
              unlocked
                  ? Icons.emoji_events_rounded
                  : Icons.emoji_events_outlined,
              size: size * 0.86,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: palette.dark.withValues(alpha: 0.45),
                  blurRadius: size * 0.06,
                  offset: Offset(0, size * 0.035),
                ),
              ],
            ),
          ),
          if (!unlocked)
            Positioned(
              bottom: size * 0.08,
              right: size * 0.08,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: palette.dark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: size * 0.03),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_rounded,
                  size: size * 0.18,
                  color: Colors.white,
                ),
              ),
            ),
          if (showChip)
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.09,
                  vertical: size * 0.02,
                ),
                decoration: BoxDecoration(
                  color: palette.dark,
                  borderRadius: BorderRadius.circular(size),
                  border: Border.all(color: Colors.white, width: size * 0.025),
                ),
                child: Text(
                  icon,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.16,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
