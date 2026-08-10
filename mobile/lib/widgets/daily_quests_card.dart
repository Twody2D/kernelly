import 'package:flutter/material.dart';

/// Карточка ежедневных квестов — 3 небольшие цели поверх обычной дневной
/// цели уроков, каждая со своей наградой в ядрах. Прогресс и факт
/// начисления считает сервер (см. fetchDailyQuests), тут только отрисовка.
class DailyQuestsCard extends StatelessWidget {
  final List<Map<String, dynamic>> quests;

  const DailyQuestsCard({super.key, required this.quests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Квесты дня',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: const Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < quests.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _questRow(quests[i]),
          ],
        ],
      ),
    );
  }

  Widget _questRow(Map<String, dynamic> quest) {
    final progress = quest['progress'] as int;
    final target = quest['target'] as int;
    final completed = quest['completed'] == true;
    final cores = quest['cores'] as int?;
    final ratio = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: completed ? const Color(0xFF58CC02) : const Color(0xFFE6F8F6),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(
            completed ? Icons.check : Icons.flag_outlined,
            size: 15,
            color: completed ? Colors.white : const Color(0xFF00A896),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quest['title'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        color: completed
                            ? const Color(0xFF3F9200)
                            : const Color(0xFF1B2430),
                      ),
                    ),
                  ),
                  if (cores != null) ...[
                    const SizedBox(width: 6),
                    const Text('📦', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    Text(
                      '+$cores',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3F9200),
                      ),
                    ),
                  ] else
                    Text(
                      '$progress / $target',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5C6B73),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE7EEEE),
                  valueColor: AlwaysStoppedAnimation(
                    completed ? const Color(0xFF58CC02) : const Color(0xFF00C9B7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
