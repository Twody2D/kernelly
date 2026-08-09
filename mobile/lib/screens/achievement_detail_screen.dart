import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/screens/chest_reward_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/achievement_badge.dart';
import 'package:mobile/widgets/primary_button.dart';

const _levelStyles = ['bronze', 'silver', 'gold', 'diamond', 'bedrock'];
const _levelDotColors = {
  'bronze': Color(0xFFC97A3D),
  'silver': Color(0xFFB8C4CC),
  'gold': Color(0xFFFFC72E),
  'diamond': Color(0xFF4FD8E8),
  'bedrock': Color(0xFF6B5A80),
};
const _levelTitles = {
  'bronze': 'Бронза',
  'silver': 'Серебро',
  'gold': 'Золото',
  'diamond': 'Алмаз',
  'bedrock': 'Бедрок',
};

/// Полноэкранное "окошко" достижения — открывается по тапу на медаль как в
/// профиле, так и в чужом профиле. Показывает дату разблокировки (или
/// заглушку для запертых) и позволяет скопировать хвастливую фразу.
class AchievementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const AchievementDetailScreen({super.key, required this.item});

  @override
  State<AchievementDetailScreen> createState() =>
      _AchievementDetailScreenState();
}

class _AchievementDetailScreenState extends State<AchievementDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _sparkle;

  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _confettiBurst;
  late final Animation<double> _pillOpacity;
  late final Animation<Offset> _pillSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _descOpacity;
  late final Animation<Offset> _descSlide;

  int get _level => widget.item['level'] as int? ?? 0;

  int get _maxLevel => widget.item['max_level'] as int? ?? 5;

  bool get _unlocked => _level > 0;

  bool get _maxed => _level >= _maxLevel;

  String get _title => widget.item['title'] as String? ?? '';

  /// Уже полностью сформировано на сервере: следующий порог, либо, если
  /// достигнут максимум — «Получено: …, текущий счёт: N».
  String get _description => widget.item['description'] as String? ?? '';

  /// Стиль текущего уровня — тот же код, что и у бейджа ('locked' если ещё
  /// не разблокировано ни разу).
  String get _currentStyle => widget.item['style'] as String? ?? 'locked';

  /// Отсутствует вовсе при просмотре чужого профиля (сервер не отдаёт это
  /// поле не для себя) — тогда по умолчанию считаем «нечего открывать».
  late bool _hasUnclaimedChest = widget.item['has_unclaimed_chest'] == true;
  late String? _nextUnclaimedCode = widget.item['next_unclaimed_code'] as String?;

  Future<void> _openChest() async {
    final code = _nextUnclaimedCode;
    if (code == null) return;
    final amount = await showClaimableChestReward(
      context,
      reason: 'achievement',
      onOpen: () => claimAchievementChest(currentUserId, code),
    );
    if (amount != null) {
      // Map передаётся по ссылке — правим прямо тот объект, что держит
      // список в родительском экране, чтобы пометка «новое» пропала там
      // сразу после возврата, без отдельной перезагрузки всего списка.
      widget.item['has_unclaimed_chest'] = false;
      widget.item['next_unclaimed_code'] = null;
      if (mounted) {
        setState(() {
          _hasUnclaimedChest = false;
          _nextUnclaimedCode = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _badgeScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    );
    _badgeOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _confettiBurst = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    );

    _pillOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );
    _pillSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );
    _titleSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _descOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );
    _descSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _entrance.forward();
    if (_unlocked) HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  void _share(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: 'Я получил достижение «$_title» в Kernelly! 🎉'),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Скопировано',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          backgroundColor: const Color(0xFF1B2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  String get _pillText {
    if (!_unlocked) return 'ЕЩЁ НЕ ОТКРЫТО';
    if (_maxed) return 'ПОЛУЧЕНО · ${(_levelTitles[_currentStyle] ?? '').toUpperCase()}';
    return 'УРОВЕНЬ $_level ИЗ $_maxLevel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF5C6B73),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Color(0xFF5C6B73),
                    ),
                    onPressed: () => _share(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_unlocked)
                                AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _confettiBurst,
                                    _sparkle,
                                  ]),
                                  builder: (context, _) => _ConfettiFlourish(
                                    burst: _confettiBurst.value,
                                    twinkle: _sparkle.value,
                                  ),
                                ),
                              AnimatedBuilder(
                                animation: _entrance,
                                builder: (context, child) => Opacity(
                                  opacity: _badgeOpacity.value,
                                  child: Transform.scale(
                                    scale: _badgeScale.value,
                                    child: child,
                                  ),
                                ),
                                child: AchievementBadge(
                                  icon: widget.item['icon'] as String,
                                  style: widget.item['style'] as String,
                                  unlocked: _unlocked,
                                  size: 150,
                                  seed: widget.item['family'] as String?,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _pillOpacity,
                          child: SlideTransition(
                            position: _pillSlide,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _unlocked
                                    ? const Color(0xFFEAF9DC)
                                    : const Color(0xFFE7EEEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _pillText,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                  color: _unlocked
                                      ? const Color(0xFF58CC02)
                                      : const Color(0xFFC2CDCD),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeTransition(
                          opacity: _pillOpacity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < _maxLevel; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i < _level
                                        ? (_levelDotColors[_levelStyles[i]] ?? const Color(0xFF00C9B7))
                                        : const Color(0xFFE7EEEE),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Text(
                              _title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                                color: const Color(0xFF1B2430),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _descOpacity,
                          child: SlideTransition(
                            position: _descSlide,
                            child: Text(
                              _description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                height: 1.4,
                                color: const Color(0xFF5C6B73),
                              ),
                            ),
                          ),
                        ),
                        if (_hasUnclaimedChest) ...[
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              text: '📦 Открыть сундук',
                              onPressed: _openChest,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Конфетти позади медали — на входе разлетается из центра наружу (burst
/// 0→1), а после лёгкой россыпью мерцает (twinkle, бесконечный цикл), только
/// для открытых достижений.
class _ConfettiFlourish extends StatelessWidget {
  final double burst;
  final double twinkle;

  const _ConfettiFlourish({required this.burst, required this.twinkle});

  static const _colors = [
    Color(0xFF00C9B7),
    Color(0xFFFFD98A),
    Color(0xFFFF9500),
    Color(0xFF58CC02),
    Color(0xFF00A896),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(220, 220),
      painter: _ConfettiPainter(_colors, burst, twinkle),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<Color> colors;
  final double burst;
  final double twinkle;

  _ConfettiPainter(this.colors, this.burst, this.twinkle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(7);
    final paint = Paint();

    for (int i = 0; i < 14; i++) {
      final angle = (2 * pi / 14) * i + random.nextDouble() * 0.3;
      final targetRadius = 88 + random.nextDouble() * 22;
      final radius = targetRadius * burst;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      final color = colors[i % colors.length];

      // мерцание по фазе, у каждой частицы свой сдвиг, чтобы не мигали синхронно
      final phase = (twinkle + i / 14) % 1.0;
      final flicker = 0.55 + 0.45 * sin(phase * 2 * pi);
      paint.color = color.withValues(alpha: burst * flicker.clamp(0.0, 1.0));

      if (i.isEven) {
        canvas.drawCircle(point, (4 + random.nextDouble() * 2) * burst, paint);
      } else {
        final side = 7.0 * burst;
        final rect = Rect.fromCenter(center: point, width: side, height: side);
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + twinkle * 2 * pi);
        canvas.translate(-point.dx, -point.dy);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.burst != burst || oldDelegate.twinkle != twinkle;
}
