import 'package:flutter/material.dart';

/// Общий каталог аватарок — используется при первой настройке профиля и при
/// редактировании профиля из настроек, чтобы не дублировать список.
const List<(String, IconData, Color, Color)> avatarCatalog = [
  ('terminal', Icons.terminal, Color(0xFF00C9B7), Color(0xFFE0F7F4)),
  ('code', Icons.code, Color(0xFF00A896), Color(0xFFE0F7F4)),
  ('rocket', Icons.rocket_launch, Color(0xFFFF9500), Color(0xFFFFF1DC)),
  ('flame', Icons.local_fire_department, Color(0xFFFF9500), Color(0xFFFFF1DC)),
  ('bolt', Icons.bolt, Color(0xFFCC9327), Color(0xFFFFF3D6)),
  ('star', Icons.star, Color(0xFFCC9327), Color(0xFFFFF3D6)),
  ('shield', Icons.shield, Color(0xFF58CC02), Color(0xFFEAF9DC)),
  ('bug', Icons.bug_report, Color(0xFFFF4B4B), Color(0xFFFFEAEA)),
];

(String, IconData, Color, Color) avatarByCode(String? code) {
  return avatarCatalog.firstWhere(
    (a) => a.$1 == code,
    orElse: () => avatarCatalog.first,
  );
}

/// Рамки профиля — косметика за ядра (см. FRAME_PRICES в backend/app/main.py,
/// коды и цены должны совпадать). Кольцо градиентом вокруг аватарки, а не
/// иконка — чтобы не путать с самими аватарками в каталоге выше.
typedef FrameSpec = (String code, String label, int price, Color c1, Color c2);

const List<FrameSpec> frameCatalog = [
  ('gold', 'Золотая', 60, Color(0xFFFFD700), Color(0xFFFF9500)),
  ('neon', 'Неоновая', 50, Color(0xFF00FFD1), Color(0xFF00C9B7)),
  ('fire', 'Огненная', 80, Color(0xFFFF4B4B), Color(0xFFCC9327)),
  ('ice', 'Ледяная', 45, Color(0xFF7EC8FF), Color(0xFF00C9B7)),
];

FrameSpec? frameByCode(String? code) {
  if (code == null) return null;
  for (final f in frameCatalog) {
    if (f.$1 == code) return f;
  }
  return null;
}

/// Оборачивает готовый виджет аватарки градиентным кольцом рамки, если она
/// надета — иначе возвращает [child] как есть. [circle] — форма аватарки
/// (follow-строки — круг, банеры профиля — скруглённый квадрат).
class FramedAvatar extends StatelessWidget {
  final Widget child;
  final String? frameCode;
  final bool circle;
  final double radius;

  const FramedAvatar({
    super.key,
    required this.child,
    required this.frameCode,
    this.circle = true,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final frame = frameByCode(frameCode);
    if (frame == null) return child;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [frame.$4, frame.$5],
        ),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
