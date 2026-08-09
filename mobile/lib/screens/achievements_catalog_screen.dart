import 'package:flutter/material.dart';
import 'package:mobile/screens/achievement_detail_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/achievement_badge.dart';

const _levelStyles = ['bronze', 'silver', 'gold', 'diamond', 'bedrock'];
const _levelDotColors = {
  'bronze': Color(0xFFC97A3D),
  'silver': Color(0xFFB8C4CC),
  'gold': Color(0xFFFFC72E),
  'diamond': Color(0xFF4FD8E8),
  'bedrock': Color(0xFF6B5A80),
};

/// Полный каталог достижений — 4 семьи (streak/XP/уроки/точность), каждая со
/// своими 5 уровнями (бронза → бедрок). Крупные карточки вместо плотной
/// сетки — тут есть куда поместить описание следующего порога.
class AchievementsCatalogScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int unlockedCount;
  final int total;

  const AchievementsCatalogScreen({
    super.key,
    required this.items,
    required this.unlockedCount,
    required this.total,
  });

  @override
  State<AchievementsCatalogScreen> createState() => _AchievementsCatalogScreenState();
}

class _AchievementsCatalogScreenState extends State<AchievementsCatalogScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          'Достижения',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${widget.unlockedCount} / ${widget.total}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: colors.accentDark,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _card(widget.items[index]),
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final colors = context.colors;
    final level = item['level'] as int? ?? 0;
    final maxLevel = item['max_level'] as int? ?? 5;
    final unlocked = level > 0;
    final hasUnclaimedChest = item['has_unclaimed_chest'] == true;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AchievementDetailScreen(item: item)),
        );
        // item мутируется деталями по ссылке при открытии сундука —
        // перерисовываем, чтобы пометка «новое» пропала.
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AchievementBadge(
                  icon: item['icon'] as String,
                  style: item['style'] as String,
                  unlocked: unlocked,
                  size: 56,
                  seed: item['family'] as String?,
                ),
                if (hasUnclaimedChest)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B4B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.card, width: 1.5),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int i = 0; i < maxLevel; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < level
                                ? (_levelDotColors[_levelStyles[i]] ?? colors.accent)
                                : colors.locked,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
