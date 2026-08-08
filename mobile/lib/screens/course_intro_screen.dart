import 'package:flutter/material.dart';
import 'package:mobile/screens/sections_screen.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/primary_button.dart';

class _Beat {
  final String eyebrow;
  final String title;
  final String text;

  const _Beat({required this.eyebrow, required this.title, required this.text});
}

/// Вводная история курса перед первым уроком — контент сейчас захардкожен под
/// единственный курс (DevOps Engineer), поэтому по courseId просто решаем,
/// показывать интро вообще или сразу открывать разделы. Когда курсов станет
/// больше, содержимое стоит вынести на бэкенд вместо списка ниже.
const _beats = [
  _Beat(
    eyebrow: '\$ new_hire --start',
    title: 'Добро пожаловать в Acme Cloud',
    text: 'Сегодня твой первый день. Acme Cloud — быстрорастущий стартап, '
        'и тебя наняли инженером в команду эксплуатации.',
  ),
  _Beat(
    eyebrow: '\$ whoami --role',
    title: 'Кто такой DevOps-инженер',
    text: 'Ты в ответе за то, чтобы код разработчиков доезжал до серверов '
        'и продолжал там работать — даже когда что-то ломается.',
  ),
  _Beat(
    eyebrow: '\$ cat README.md',
    title: 'Здесь не будет лекций',
    text: 'Только реальные задачи: терминал, конфиги, упавшие сервисы. '
        'Каждая миссия — что-то, что тебе правда придётся чинить.',
  ),
  _Beat(
    eyebrow: '\$ ./start.sh',
    title: 'Готов начать?',
    text: 'Первая миссия уже ждёт на сервере. Погнали.',
  ),
];

class CourseIntroScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CourseIntroScreen({super.key, required this.courseId, required this.courseTitle});

  @override
  State<CourseIntroScreen> createState() => _CourseIntroScreenState();
}

class _CourseIntroScreenState extends State<CourseIntroScreen> {
  final PageController _controller = PageController();
  int page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (page == _beats.length - 1) {
      await markCourseIntroSeen(widget.courseId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SectionsScreen(courseId: widget.courseId, courseTitle: widget.courseTitle),
        ),
      );
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  Future<void> _skip() async {
    await markCourseIntroSeen(widget.courseId);
    if (!mounted) return;
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
                    onPageChanged: (index) => setState(() => page = index),
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
              const AnimatedMascot(size: 152),
              const SizedBox(height: 16),
              Text(
                beat.eyebrow,
                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, color: const Color(0xFF00A896)),
              ),
              const SizedBox(height: 8),
              Text(
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
              const SizedBox(height: 10),
              Text(
                beat.text,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 15.5, height: 1.5, color: const Color(0xFF5C6B73)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
