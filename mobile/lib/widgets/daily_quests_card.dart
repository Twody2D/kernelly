import 'package:flutter/material.dart';

/// Компактная плашка «Цель на день» на вкладке Путь и экране результата
/// урока — по тапу открывает выплывающий список квестов (см.
/// showDailyQuestsSheet). Прогресс и факт начисления считает сервер (см.
/// fetchDailyQuests), тут только отрисовка.
class DailyQuestsSummaryTile extends StatelessWidget {
  final List<Map<String, dynamic>> quests;
  /// Сегодняшний XP превысил лучший день за последние 30 (см.
  /// get_daily_quests в backend) — просто бейдж-мотиватор, ничего не начисляет.
  final bool personalBest;

  const DailyQuestsSummaryTile({
    super.key,
    required this.quests,
    this.personalBest = false,
  });

  @override
  Widget build(BuildContext context) {
    final completed = quests.where((q) => q['completed'] == true).length;
    final allDone = quests.isNotEmpty && completed == quests.length;

    return GestureDetector(
      onTap: () => showDailyQuestsSheet(context, quests),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: allDone ? const Color(0xFFEAF9DC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: allDone ? const Color(0xFFC5EBA0) : const Color(0xFFDCE8E7),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: allDone ? const Color(0xFF58CC02) : const Color(0xFFE6F8F6),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    allDone ? Icons.check : Icons.flag_outlined,
                    size: 18,
                    color: allDone ? Colors.white : const Color(0xFF00A896),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Цель на день',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: allDone ? const Color(0xFF3F9200) : const Color(0xFF1B2430),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        allDone ? 'Все квесты выполнены!' : '$completed / ${quests.length} квестов выполнено',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: allDone ? const Color(0xFF3F9200) : const Color(0xFF5C6B73),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: const Color(0xFF9AAAAA)),
              ],
            ),
            if (personalBest) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      'Личный рекорд дня по XP!',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        color: const Color(0xFF9A6B00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showDailyQuestsSheet(BuildContext context, List<Map<String, dynamic>> quests) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEEE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Квесты дня',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF1B2430),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < quests.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _questRow(quests[i]),
            ],
          ],
        ),
      ),
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: completed ? const Color(0xFF58CC02) : const Color(0xFFE6F8F6),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          completed ? Icons.check : Icons.flag_outlined,
          size: 16,
          color: completed ? Colors.white : const Color(0xFF00A896),
        ),
      ),
      const SizedBox(width: 11),
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
                      fontSize: 13,
                      color: completed ? const Color(0xFF3F9200) : const Color(0xFF1B2430),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3F9200),
                    ),
                  ),
                ] else
                  Text(
                    '$progress / $target',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C6B73),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
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
