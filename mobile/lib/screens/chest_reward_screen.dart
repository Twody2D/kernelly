import 'package:flutter/material.dart';
import 'package:mobile/widgets/confetti_overlay.dart';
import 'package:mobile/widgets/primary_button.dart';

const _chestReasonTitles = {
  'lesson_gold': 'УРОК НА ЗОЛОТО',
  'course_complete': 'КУРС ПРОЙДЕН',
  'daily_login': 'ЕЖЕДНЕВНЫЙ ВХОД',
  'achievement': 'ДОСТИЖЕНИЕ',
};

/// Показывает награды за сундуки одну за другой, полноэкранно — очередь
/// нужна по той же причине, что и у showAchievementUnlocks: за один урок
/// сундуков может выпасть сразу несколько (золото + курс пройден разом).
Future<void> showChestRewards(
  BuildContext context,
  List<Map<String, dynamic>> chests,
) async {
  for (final chest in chests) {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChestRewardScreen(chest: chest),
        fullscreenDialog: true,
      ),
    );
  }
}

class ChestRewardScreen extends StatefulWidget {
  final Map<String, dynamic> chest;

  const ChestRewardScreen({super.key, required this.chest});

  @override
  State<ChestRewardScreen> createState() => _ChestRewardScreenState();
}

class _ChestRewardScreenState extends State<ChestRewardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _chestScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _chestScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    const textInterval = Interval(0.35, 0.85, curve: Curves.easeOut);
    _fade = CurvedAnimation(parent: _entrance, curve: textInterval);
    _slide = Tween(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: textInterval));
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chest = widget.chest;
    final amount = chest['amount'] as int;
    final reason = chest['reason'] as String;
    final title = _chestReasonTitles[reason] ?? 'СУНДУК';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: Stack(
        children: [
          const Positioned.fill(child: ConfettiOverlay()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 1.2,
                          color: const Color(0xFF00A896),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ScaleTransition(
                      scale: _chestScale,
                      child: const Text('📦', style: TextStyle(fontSize: 96)),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          children: [
                            Text(
                              '+$amount ядер',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w600,
                                fontSize: 26,
                                color: const Color(0xFF1B2430),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Потрать их на заморозку streak в настройках',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                height: 1.5,
                                color: const Color(0xFF5C6B73),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _fade,
                      child: SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: 'Круто!',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
