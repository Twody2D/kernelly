import 'package:flutter/material.dart';

/// Медаль достижения — общий вид для сетки в профиле и экрана поздравления.
/// Раньше в профиле это был просто квадрат с иконкой; теперь — круглая медаль
/// с бликом и мягкой тенью в цвет уровня, как настоящая награда.
class AchievementBadge extends StatelessWidget {
  final String icon;
  final String style;
  final bool unlocked;
  final double size;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.style,
    required this.unlocked,
    this.size = 56,
  });

  static const _styles = {
    'gold': (
      gradient: [Color(0xFFFFE7B8), Color(0xFFFFD98A), Color(0xFFE8BC66)],
      shadow: Color(0xFFE8BC66),
    ),
    'green': (
      gradient: [Color(0xFF8FEA4C), Color(0xFF58CC02), Color(0xFF3F9200)],
      shadow: Color(0xFF3F9200),
    ),
    'teal': (
      gradient: [Color(0xFF5CEBDA), Color(0xFF00C9B7), Color(0xFF00A896)],
      shadow: Color(0xFF00A896),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final palette = _styles[style] ?? _styles['teal']!;

    if (!unlocked) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE7EEEE),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.lock_rounded,
          size: size * 0.36,
          color: const Color(0xFFC2CDCD),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 0.95,
          colors: palette.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.55),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.08),
          ),
        ],
        border: Border.all(color: Colors.white, width: size * 0.045),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.12,
            left: size * 0.16,
            child: Container(
              width: size * 0.34,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          icon.length > 2
              ? Text(
                  icon,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.24,
                    color: Colors.white,
                  ),
                )
              : Text(icon, style: TextStyle(fontSize: size * 0.42)),
        ],
      ),
    );
  }
}
