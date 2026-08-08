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
