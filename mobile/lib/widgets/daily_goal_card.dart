import 'package:flutter/material.dart';

/// Прогресс дневной цели: сколько уроков пройдено сегодня из выбранных в настройках.
class DailyGoalCard extends StatelessWidget {
  final int completed;
  final int goal;

  const DailyGoalCard({super.key, required this.completed, required this.goal});

  @override
  Widget build(BuildContext context) {
    final isDone = goal > 0 && completed >= goal;
    final ratio = goal > 0 ? (completed / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFEAF9DC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFFC5EBA0) : const Color(0xFFDCE8E7),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF58CC02) : const Color(0xFFE6F8F6),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check, size: 19, color: Colors.white)
                : const Text(
                    '◎',
                    style: TextStyle(fontSize: 17, color: Color(0xFF00A896)),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isDone ? 'Цель выполнена!' : 'Цель на день',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: isDone ? const Color(0xFF3F9200) : const Color(0xFF1B2430),
                      ),
                    ),
                    Text(
                      '$completed / $goal',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDone ? const Color(0xFF3F9200) : const Color(0xFF5C6B73),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: isDone ? const Color(0xFFD6F0B8) : const Color(0xFFE7EEEE),
                    valueColor: AlwaysStoppedAnimation(
                      isDone ? const Color(0xFF58CC02) : const Color(0xFF00C9B7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
