import 'package:flutter/material.dart';
import 'package:mobile/widgets/achievement_badge.dart';
import 'package:mobile/widgets/confetti_overlay.dart';
import 'package:mobile/widgets/primary_button.dart';

/// Показывает разблокированные достижения одно за другим, полноэкранно и с
/// конфетти — очередь нужна, потому что за один урок может открыться сразу
/// несколько (например streak и xp одновременно).
Future<void> showAchievementUnlocks(
  BuildContext context,
  List<Map<String, dynamic>> achievements,
) async {
  for (final achievement in achievements) {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AchievementUnlockScreen(achievement: achievement),
        fullscreenDialog: true,
      ),
    );
  }
}

class AchievementUnlockScreen extends StatefulWidget {
  final Map<String, dynamic> achievement;

  const AchievementUnlockScreen({super.key, required this.achievement});

  @override
  State<AchievementUnlockScreen> createState() =>
      _AchievementUnlockScreenState();
}

class _AchievementUnlockScreenState extends State<AchievementUnlockScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _badgeScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _badgeScale = CurvedAnimation(
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

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;

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
                        'ДОСТИЖЕНИЕ ОТКРЫТО',
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
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) {
                              final v = Curves.easeInOut.transform(
                                _pulse.value,
                              );
                              return Transform.scale(
                                scale: 1.0 + v * 0.14,
                                child: Opacity(
                                  opacity: 0.3 + v * 0.3,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFD98A),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _badgeScale,
                            child: AchievementBadge(
                              icon: achievement['icon'] as String,
                              style: achievement['style'] as String,
                              unlocked: true,
                              size: 140,
                              seed: achievement['code'] as String?,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          children: [
                            Text(
                              achievement['title'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                                color: const Color(0xFF1B2430),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              achievement['description'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                height: 1.5,
                                color: const Color(0xFF5C6B73),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '📦 Сундук с ядрами ждёт в профиле',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: const Color(0xFF00A896),
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
