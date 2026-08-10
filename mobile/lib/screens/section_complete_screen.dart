import 'package:flutter/material.dart';
import 'package:mobile/widgets/daily_quests_card.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/soft_star.dart';

class SectionCompleteScreen extends StatelessWidget {
  /// Ответ POST /lessons/{id}/complete: прогресс раздела, курса и что дальше
  final Map<String, dynamic> completion;

  /// Квесты дня с прогрессом на момент завершения этого урока
  final List<Map<String, dynamic>> quests;

  final int xpEarned;
  final int accuracyPercent;
  final Duration elapsed;
  final int streak;
  final VoidCallback onContinue;
  final VoidCallback onRepeat;

  const SectionCompleteScreen({
    super.key,
    required this.completion,
    required this.quests,
    required this.xpEarned,
    required this.accuracyPercent,
    required this.elapsed,
    required this.streak,
    required this.onContinue,
    required this.onRepeat,
  });

  Map<String, dynamic> get _section => Map<String, dynamic>.from(completion['section'] ?? {});

  Map<String, dynamic> get _course => Map<String, dynamic>.from(completion['course'] ?? {});

  Map<String, dynamic>? get _next =>
      completion['next'] == null ? null : Map<String, dynamic>.from(completion['next']);

  Map<String, dynamic> get _mastery => Map<String, dynamic>.from(completion['mastery'] ?? {});

  bool get _leveledUp => _mastery['leveled_up'] == true;

  int get _masteryLevel => _mastery['level'] ?? 0;

  bool get _isSectionComplete => _section['is_complete'] == true;

  String get _eyebrow => _isSectionComplete
      ? '\$ раздел ${_section['order']} / ${_course['sections_total']} · завершён'
      : '\$ урок ${_section['completed']} / ${_section['total']} · пройден';

  String get _headline => _isSectionComplete ? 'Раздел пройден!' : 'Урок пройден!';

  String get _subject =>
      _isSectionComplete ? '${_section['title']}' : '${completion['lesson_title'] ?? ''}';

  /// Три звезды за точность от 90%, две от 70%, иначе одна
  int get _earnedStars {
    if (accuracyPercent >= 90) return 3;
    if (accuracyPercent >= 70) return 2;
    return 1;
  }

  String get _formattedTime {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 260,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x2400C9B7), Color(0x0000C9B7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Color(0xFF5C6B73)),
                                    onPressed: onContinue,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 14)),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$streak',
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: const Color(0xFFFF9500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Center(
                                child: SizedBox(
                                  width: 220,
                                  height: 190,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _PulsingOval(width: 164, height: 150),
                                      Positioned(
                                        left: 10,
                                        top: 26,
                                        child: Transform.rotate(
                                          angle: -14 * 3.1415926535 / 180,
                                          child: Text(
                                            '</>',
                                            style: TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              color: const Color(0xFF00C9B7),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Positioned(
                                        right: 8,
                                        top: 52,
                                        child: Text('✨', style: TextStyle(fontSize: 15)),
                                      ),
                                      Positioned(
                                        right: 26,
                                        bottom: 18,
                                        child: Transform.rotate(
                                          angle: 12 * 3.1415926535 / 180,
                                          child: Text(
                                            '\$',
                                            style: TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              color: const Color(0xFFFFD98A),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _FloatingMascot(),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                _eyebrow,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  color: const Color(0xFF00A896),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _headline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 26,
                                  height: 1.15,
                                  color: Color(0xFF1B2430),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _subject,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF5C6B73),
                                ),
                              ),
                              if (_leveledUp) ...[
                                const SizedBox(height: 12),
                                _MasteryLevelUpBadge(level: _masteryLevel),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (i) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: SoftStar(
                                      size: 38,
                                      color: i < _earnedStars ? const Color(0xFFFFD98A) : const Color(0xFFE7EEEE),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(child: _statCard('XP', '+$xpEarned', highlight: true)),
                                  const SizedBox(width: 9),
                                  Expanded(child: _statCard('ТОЧНОСТЬ', '$accuracyPercent%')),
                                  const SizedBox(width: 9),
                                  Expanded(child: _statCard('ВРЕМЯ', _formattedTime)),
                                ],
                              ),
                              if (quests.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                DailyQuestsSummaryTile(quests: quests),
                              ],
                              if (_next != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [Color(0xFF29DFCB), Color(0xFF00C9B7)],
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: const [
                                                BoxShadow(color: Color(0xFF00A896), offset: Offset(0, 3)),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '>_',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -9,
                                            left: 14,
                                            child: Container(
                                              width: 4,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.55),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -9,
                                            right: 14,
                                            child: Container(
                                              width: 4,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.55),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isSectionComplete ? 'РАЗБЛОКИРОВАНО' : 'ДАЛЬШЕ',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 10,
                                                color: const Color(0xFF9AAAAA),
                                              ),
                                            ),
                                            Text(
                                              _next == null
                                                  ? ''
                                                  : '${_next!['type'] == 'section' ? 'Раздел' : 'Урок'} ${_next!['order']} · ${_next!['title']}',
                                              style: TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.5,
                                                color: const Color(0xFF1B2430),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: onContinue,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C9B7),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [BoxShadow(color: Color(0xFF00A896), offset: Offset(0, 4))],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Продолжить',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: onRepeat,
                                child: Text(
                                  'Повторить урок',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: const Color(0xFF5C6B73),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFEAF9DC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight ? null : Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9.5,
              color: highlight ? const Color(0xFF4B8A18) : const Color(0xFF9AAAAA),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: highlight ? const Color(0xFF3F9200) : const Color(0xFF1B2430),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingOval extends StatefulWidget {
  final double width;
  final double height;
  const _PulsingOval({required this.width, required this.height});

  @override
  State<_PulsingOval> createState() => _PulsingOvalState();
}

class _PulsingOvalState extends State<_PulsingOval> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true); //Анимация круга
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curved = Curves.easeInOut.transform(_controller.value);
        final opacity = 0.3 + curved * 0.7;
        final scale = 1.0 + curved * 0.04;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(size: Size(widget.width, widget.height), painter: _DashedOvalPainter()),
          ),
        );
      },
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C9B7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    const dashWidth = 5.0;
    const dashGap = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOvalPainter oldDelegate) => false;
}

/// Празднование повышения уровня мастерства урока — бронза/серебро/золото
/// за 1/2/3 успешных прохождения. Появляется с лёгким "поп"-эффектом.
class _MasteryLevelUpBadge extends StatefulWidget {
  final int level;
  const _MasteryLevelUpBadge({required this.level});

  @override
  State<_MasteryLevelUpBadge> createState() => _MasteryLevelUpBadgeState();
}

class _MasteryLevelUpBadgeState extends State<_MasteryLevelUpBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  static const _levels = {
    1: (label: 'Бронзовый уровень!', color: Color(0xFFCD7F32), bg: Color(0xFFF7E9DD)),
    2: (label: 'Серебряный уровень!', color: Color(0xFF8FA0AB), bg: Color(0xFFEDF1F3)),
    3: (label: 'Золотой уровень!', color: Color(0xFFE0A82E), bg: Color(0xFFFFF3D6)),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _levels[widget.level] ?? _levels[1]!;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, color: style.color, size: 20),
            const SizedBox(width: 8),
            Text(
              style.label,
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 14, color: style.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingMascot extends StatefulWidget {
  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true); //Покачивание маскота
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = Curves.easeInOut.transform(_controller.value) * -7;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: const Mascot(emotion: MascotEmotion.surprised, size: 168),
    );
  }
}
