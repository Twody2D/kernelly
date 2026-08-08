import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/screens/sections_screen.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/primary_button.dart';

class _Beat {
  final String eyebrow;
  final String title;
  final String text;
  final MascotEmotion emotion;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _Beat({
    required this.eyebrow,
    required this.title,
    required this.text,
    required this.emotion,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

/// Вводная история курса перед первым уроком — контент сейчас захардкожен под
/// единственный курс (DevOps Engineer), поэтому по courseId просто решаем,
/// показывать интро вообще или сразу открывать разделы. Когда курсов станет
/// больше, содержимое стоит вынести на бэкенд вместо списка ниже.
const _beats = [
  _Beat(
    eyebrow: '\$ man devops',
    title: 'Что такое DevOps?',
    text: 'Когда разработчик меняет код, его нужно собрать, проверить и '
        'доставить на сервер — и так много раз в день. DevOps — это когда '
        'весь этот путь автоматизирован и происходит сам, без ручной '
        'возни. Это называется CI/CD.',
    emotion: MascotEmotion.happy,
    icon: Icons.autorenew_rounded,
    iconColor: Color(0xFF00A896),
    iconBg: Color(0xFFE0F7F4),
  ),
  _Beat(
    eyebrow: '\$ new_hire --start',
    title: 'Твой первый день в офисе Acme Cloud',
    text: 'Acme Cloud — быстрорастущий стартап. Тебя только что наняли '
        'инженером, который будет всё это настраивать, и сегодня — твой '
        'первый рабочий день.',
    emotion: MascotEmotion.surprised,
    icon: Icons.apartment_rounded,
    iconColor: Color(0xFFFF9500),
    iconBg: Color(0xFFFFF1DC),
  ),
  _Beat(
    eyebrow: '\$ cat README.md',
    title: 'Здесь не будет лекций',
    text: 'Только реальные задачи: терминал, конфиги, упавшие сервисы. '
        'Каждая миссия — что-то, что тебе правда придётся чинить.',
    emotion: MascotEmotion.happy,
    icon: Icons.terminal_rounded,
    iconColor: Color(0xFF58CC02),
    iconBg: Color(0xFFEAF9DC),
  ),
  _Beat(
    eyebrow: '\$ ./start.sh',
    title: 'Готов начать?',
    text: 'Первая миссия уже ждёт на сервере. Погнали.',
    emotion: MascotEmotion.excited,
    icon: Icons.rocket_launch_rounded,
    iconColor: Color(0xFFCC9327),
    iconBg: Color(0xFFFFF3D6),
  ),
];

class CourseIntroScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  /// true — открыт кнопкой «пересмотреть» поверх уже существующего экрана
  /// разделов, поэтому по завершении нужно просто закрыться (pop), а не
  /// заменять текущий маршрут новым SectionsScreen.
  final bool isReplay;

  const CourseIntroScreen({super.key, required this.courseId, required this.courseTitle, this.isReplay = false});

  @override
  State<CourseIntroScreen> createState() => _CourseIntroScreenState();
}

class _CourseIntroScreenState extends State<CourseIntroScreen> with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int page = 0;

  late final AnimationController _beatController;
  late final Animation<double> _mascotScale;
  late final Animation<double> _mascotShake;
  late final Animation<double> _iconScale;
  late final Animation<double> _eyebrowFade;
  late final Animation<Offset> _eyebrowSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _beatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _mascotScale = CurvedAnimation(parent: _beatController, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack));
    _mascotShake = CurvedAnimation(parent: _beatController, curve: const Interval(0.05, 0.6, curve: Curves.elasticOut));
    _iconScale = CurvedAnimation(parent: _beatController, curve: const Interval(0.35, 0.75, curve: Curves.easeOutBack));

    const eyebrowInterval = Interval(0.3, 0.7, curve: Curves.easeOut);
    _eyebrowFade = CurvedAnimation(parent: _beatController, curve: eyebrowInterval);
    _eyebrowSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _beatController, curve: eyebrowInterval));

    const titleInterval = Interval(0.4, 0.8, curve: Curves.easeOut);
    _titleFade = CurvedAnimation(parent: _beatController, curve: titleInterval);
    _titleSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _beatController, curve: titleInterval));

    const textInterval = Interval(0.5, 0.9, curve: Curves.easeOut);
    _textFade = CurvedAnimation(parent: _beatController, curve: textInterval);
    _textSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _beatController, curve: textInterval));

    _beatController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _beatController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (page == _beats.length - 1) {
      await _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  Future<void> _skip() async {
    await _finish();
  }

  Future<void> _finish() async {
    await markCourseIntroSeen(widget.courseId);
    if (!mounted) return;

    if (widget.isReplay) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SectionsScreen(courseId: widget.courseId, courseTitle: widget.courseTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Пропустить',
                          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: const Color(0xFF9AAAAA)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) {
                      setState(() => page = index);
                      _beatController.forward(from: 0);
                    },
                    children: [for (final beat in _beats) _beatPage(beat)],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: PrimaryButton(
                    text: page == _beats.length - 1 ? 'Начать' : 'Дальше',
                    onPressed: _next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _beats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: page == i ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: page == i ? const Color(0xFF00C9B7) : const Color(0xFFC2CDCD),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _beatPage(_Beat beat) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _beatController,
                builder: (context, child) {
                  final shakeT = _mascotShake.value;
                  final angle = beat.emotion == MascotEmotion.surprised
                      ? sin(shakeT * pi * 6) * (1 - shakeT) * 0.12
                      : 0.0;
                  return Transform.rotate(
                    angle: angle,
                    child: Transform.scale(scale: _mascotScale.value, child: child),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedMascot(size: 152, emotion: beat.emotion),
                    Positioned(
                      right: 18,
                      bottom: 14,
                      child: ScaleTransition(
                        scale: _iconScale,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: beat.iconBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF6F9F9), width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(beat.icon, size: 20, color: beat.iconColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _eyebrowFade,
                child: SlideTransition(
                  position: _eyebrowSlide,
                  child: Text(
                    beat.eyebrow,
                    style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, color: const Color(0xFF00A896)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Text(
                    beat.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 26,
                      height: 1.2,
                      color: const Color(0xFF1B2430),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Text(
                    beat.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15.5, height: 1.5, color: const Color(0xFF5C6B73)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
