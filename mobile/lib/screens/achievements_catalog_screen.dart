import 'package:flutter/material.dart';
import 'package:mobile/screens/achievement_detail_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/achievement_badge.dart';

/// Полный каталог всех достижений — открытых и ещё нет, в исходном порядке
/// (по категориям: streak → уроки → XP → точность), а не «открытые сначала»,
/// как в компактном превью на профиле — так видно прогрессию внутри категории.
class AchievementsCatalogScreen extends StatelessWidget {
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
                '$unlockedCount / $total',
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
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _badge(context, items[index]),
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, Map<String, dynamic> item) {
    final colors = context.colors;
    final unlocked = item['unlocked'] == true;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AchievementDetailScreen(item: item)),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => AchievementBadge(
              icon: item['icon'] as String,
              style: item['style'] as String,
              unlocked: unlocked,
              size: constraints.maxWidth,
              seed: item['code'] as String?,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['title'] as String,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8.5,
              color: unlocked ? colors.textSecondary : colors.locked,
            ),
          ),
        ],
      ),
    );
  }
}
