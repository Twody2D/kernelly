import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/primary_button.dart';

const _introTopics = ['bash', 'git', 'python', 'sql'];

const _topics = ['linux', 'bash', 'git', 'docker', 'python', 'sql'];

const _goals = [
  {'lessons': 1, 'title': 'Спокойно', 'subtitle': '1 урок · ~5 минут'},
  {'lessons': 3, 'title': 'Обычно', 'subtitle': '3 урока · ~15 минут'},
  {'lessons': 5, 'title': 'Серьёзно', 'subtitle': '5 уроков · ~25 минут'},
  {'lessons': 10, 'title': 'Хардкор', 'subtitle': '10 уроков · ~50 минут'},
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int page = 0;
  final Set<String> selectedTopics = {};
  int goal = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setStringList('onboarding_topics', selectedTopics.toList());
    await prefs.setInt('daily_goal', goal);

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  void _next() {
    if (page == 2) {
      _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.fredoka(fontWeight: FontWeight.w500, fontSize: 14)),
          backgroundColor: const Color(0xFF1B2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  String get _buttonText {
    if (page == 0) return 'Начать учиться';
    if (page == 1) return 'Дальше';
    return 'Поехали';
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF58CC02),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0x3358CC02), spreadRadius: 3, blurRadius: 0),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kernelly',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: const Color(0xFF1B2430),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'v1.0',
                        style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF5C6B73)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) => setState(() => page = index),
                    children: [_introPage(), _topicsPage(), _goalPage()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: PrimaryButton(text: _buttonText, onPressed: _next),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 20,
                  child: page == 0
                      ? GestureDetector(
                          onTap: () => _soon('Вход в аккаунт появится позже'),
                          child: Text(
                            'У меня уже есть аккаунт',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                              color: const Color(0xFF5C6B73),
                            ),
                          ),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 3; i++) ...[
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

  Widget _introPage() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              const Center(child: AnimatedMascot(size: 152)),
              Text(
                '\$ whoami',
                style: GoogleFonts.jetBrainsMono(fontSize: 12.5, color: const Color(0xFF00A896)),
              ),
              const SizedBox(height: 8),
              Text(
                'Привет! Я Kernel',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  height: 1.2,
                  color: const Color(0xFF1B2430),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Научу тебя терминалу, Linux и коду — по 5 минут в день. '
                'Без лекций: только команды, которые правда пригодятся.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15.5, height: 1.5, color: const Color(0xFF5C6B73)),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [for (final topic in _introTopics) _chip(topic, selected: false)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topicsPage() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                '\$ выбери направление',
                style: GoogleFonts.jetBrainsMono(fontSize: 12.5, color: const Color(0xFF00A896)),
              ),
              const SizedBox(height: 8),
              Text(
                'Что хочешь изучать?',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  height: 1.2,
                  color: const Color(0xFF1B2430),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Отметь всё, что интересно. Это можно поменять потом в настройках.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15.5, height: 1.5, color: const Color(0xFF5C6B73)),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final topic in _topics)
                    GestureDetector(
                      onTap: () => setState(() {
                        if (!selectedTopics.remove(topic)) selectedTopics.add(topic);
                      }),
                      child: _chip(topic, selected: selectedTopics.contains(topic)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalPage() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                '\$ цель на день',
                style: GoogleFonts.jetBrainsMono(fontSize: 12.5, color: const Color(0xFF00A896)),
              ),
              const SizedBox(height: 8),
              Text(
                'Сколько занимаемся?',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  height: 1.2,
                  color: const Color(0xFF1B2430),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Небольшая цель, которую легко держать каждый день.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15.5, height: 1.5, color: const Color(0xFF5C6B73)),
              ),
              const SizedBox(height: 20),
              for (final item in _goals) ...[_goalCard(item), const SizedBox(height: 10)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalCard(Map<String, Object> item) {
    final lessons = item['lessons'] as int;
    final selected = goal == lessons;

    return GestureDetector(
      onTap: () => setState(() => goal = lessons),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F8F6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF00C9B7) : const Color(0xFFDCE8E7),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF1B2430),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF5C6B73)),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected ? const Color(0xFF00C9B7) : const Color(0xFFC2CDCD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE3F8F6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? const Color(0xFF00C9B7) : const Color(0xFFDCE8E7), width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF00A896),
        ),
      ),
    );
  }
}
