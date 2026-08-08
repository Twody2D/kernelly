import 'package:flutter/material.dart';

/// Карточка-приглашение повторить просроченные навыки — показывается только
/// когда алгоритм Лейтнера отметил что-то как «пора повторить».
class ReviewCard extends StatelessWidget {
  final int due;
  final VoidCallback onTap;

  const ReviewCard({super.key, required this.due, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9500), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Color(0xFFFF9500)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пора повторить',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1B2430)),
                  ),
                  Text(
                    '$due ${_skillWord(due)} — закрепи, пока не забыл',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: const Color(0xFF5C6B73)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF9500)),
          ],
        ),
      ),
    );
  }

  String _skillWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'навык';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'навыка';
    return 'навыков';
  }
}
