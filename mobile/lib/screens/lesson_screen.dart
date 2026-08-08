import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/option_card.dart';
import 'package:mobile/widgets/primary_button.dart';
import 'package:mobile/screens/section_complete_screen.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;
  final String sectionTitle;

  const LessonScreen({super.key, required this.lessonId, required this.sectionTitle});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> exercises = [];
  Map<String, dynamic>? lesson;
  bool showingStory = false;
  int currentIndex = 0;
  String? selectedAnswer;
  bool? isCorrect;
  final _terminalController = TextEditingController();

  /// Приходит вместе с результатом проверки — показываем при ошибке
  String? correctAnswer;
  int attemptCount = 0;
  Map<String, dynamic>? user;
  int correctCount = 0;
  bool checking = false;
  bool finishing = false;
  DateTime? startTime;

  /// Повторное прохождение: XP за него уже начислялся, второй раз не даём
  bool isRepeat = false;

  /// Ответ на завершение урока: прогресс раздела, курса и что дальше
  Map<String, dynamic>? completion;

  /// Дневная цель на момент завершения урока
  int dailyCompleted = 0;
  int dailyGoal = defaultDailyGoal;

  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    loadLesson();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> loadLesson() async {
    final lessonData = await fetchLesson(widget.lessonId, currentUserId);
    final data = await fetchLessonExercises(widget.lessonId, currentUserId);
    final userData = await fetchUser(currentUserId);
    setState(() {
      lesson = lessonData;
      showingStory = (lessonData['story'] as String?)?.isNotEmpty == true;
      exercises = data;
      user = userData;
      startTime = DateTime.now();
    });
  }

  void _chooseOption(String option) {
    setState(() {
      selectedAnswer = option;
    });
  }

  void _checkAnswer() async {
    if (checking || isCorrect != null) return;
    setState(() => checking = true);

    final currentExercise = exercises[currentIndex];
    final result = await submitAnswer(currentExercise['id'], currentUserId, selectedAnswer!.trim());
    final userData = await fetchUser(currentUserId);
    if (!mounted) return;

    final correct = result['correct'] == true;
    setState(() {
      isCorrect = correct;
      correctAnswer = result['correct_answer'] as String?;
      attemptCount++;
      user = userData;
      if (correct) correctCount++;
      checking = false;
    });
  }

  void _nextExercise() {
    if (currentIndex + 1 >= exercises.length) {
      _finishLesson();
      return;
    }
    _terminalController.clear();
    setState(() {
      currentIndex++;
      selectedAnswer = null;
      isCorrect = null;
      correctAnswer = null;
    });
  }

  /// Шаг LEARN не проверяется — просто засчитывается как пройденный, чтобы
  /// не портить XP/точность (нечего было отвечать неправильно).
  void _acknowledgeTheory() {
    correctCount++;
    _nextExercise();
  }

  void _repeatLesson() {
    _terminalController.clear();
    setState(() {
      currentIndex = 0;
      selectedAnswer = null;
      isCorrect = null;
      correctAnswer = null;
      correctCount = 0;
      completion = null;
      isRepeat = true;
      startTime = DateTime.now();
    });
  }

  Future<void> _finishLesson() async {
    if (finishing || completion != null) return;
    setState(() => finishing = true);

    try {
      if (!isRepeat) {
        final newXp = await awardXp(currentUserId, correctCount);
        if (mounted) setState(() => user?['xp'] = newXp);
      }
      final data = await completeLesson(widget.lessonId, currentUserId);
      final daily = await fetchDailyProgress(currentUserId);
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        completion = data;
        dailyCompleted = daily['lessons_completed'] ?? 0;
        dailyGoal = prefs.getInt(PrefKeys.dailyGoal) ?? defaultDailyGoal;
        finishing = false;
      });
    } catch (e) {
      debugPrint('Ошибка завершения урока: $e');
      if (!mounted) return;
      setState(() => finishing = false);
      Navigator.pop(context);
    }
  }

  PreferredSizeWidget _buildAppBar({double? progress}) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close, color: Color(0xFF5C6B73)),
        onPressed: () => Navigator.pop(context),
      ),
      title: progress != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: const Color(0xFFE7EEEE),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00C9B7)),
              ),
            )
          : null,
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${user!['streak']}'),
                  const SizedBox(width: 12),
                  Text('${user!['xp']} XP'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _theoryScreen(Map<String, dynamic> exercise) {
    final progress = currentIndex / exercises.length;
    final example = exercise['content']?['example'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: _buildAppBar(progress: progress),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AnimatedMascot(size: 96),
                    const SizedBox(height: 12),
                    Text(
                      '\$ ${widget.sectionTitle}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xFF00A896),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFE0F7F4), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF00A896)),
                          const SizedBox(width: 5),
                          Text(
                            'ЧТО НУЖНО ЗНАТЬ',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                              color: const Color(0xFF00A896),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: _parseInlineCode(
                          exercise['question'] as String,
                          baseStyle: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            height: 1.4,
                            color: const Color(0xFF1B2430),
                          ),
                        ),
                      ),
                    ),
                    if (example != null && example.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2430),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [for (final line in example.split('\n')) _terminalLine(line)],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: PrimaryButton(text: 'Понятно', onPressed: _acknowledgeTheory),
            ),
          ],
        ),
      ),
    );
  }

  /// Разбивает текст по `бэктикам` и подсвечивает код как моноширинный чип —
  /// без этого команды вроде `pwd` тонули бы в обычном тексте.
  List<InlineSpan> _parseInlineCode(String text, {required TextStyle baseStyle}) {
    final spans = <InlineSpan>[];
    final parts = text.split('`');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isCode = i.isOdd;
      spans.add(
        TextSpan(
          text: parts[i],
          style: isCode
              ? baseStyle.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w600,
                  fontSize: baseStyle.fontSize! - 2,
                  color: const Color(0xFF00A896),
                  backgroundColor: const Color(0xFFE0F7F4),
                )
              : baseStyle,
        ),
      );
    }
    return spans;
  }

  /// Простая подсветка строк терминального примера: `$ команда` — приглашение
  /// бирюзовое, сама команда белая; всё остальное — приглушённый вывод.
  Widget _terminalLine(String line) {
    const promptColor = Color(0xFF00C9B7);
    const commandColor = Colors.white;
    const outputColor = Color(0xFF8FE4DA);

    if (line.startsWith('\$ ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13.5, height: 1.6),
            children: [
              const TextSpan(text: '\$ ', style: TextStyle(color: promptColor, fontWeight: FontWeight.w700)),
              TextSpan(text: line.substring(2), style: const TextStyle(color: commandColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        line,
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13.5, height: 1.6, color: outputColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (showingStory) {
      return _StoryIntro(
        sectionTitle: widget.sectionTitle,
        lessonTitle: lesson?['title'] as String? ?? '',
        story: lesson?['story'] as String? ?? '',
        onContinue: () => setState(() => showingStory = false),
      );
    }

    if (completion != null) {
      return SectionCompleteScreen(
        completion: completion!,
        dailyCompleted: dailyCompleted,
        dailyGoal: dailyGoal,
        xpEarned: isRepeat ? 0 : correctCount * 10,
        accuracyPercent: exercises.isEmpty ? 0 : ((correctCount / exercises.length) * 100).round(),
        elapsed: startTime == null ? Duration.zero : DateTime.now().difference(startTime!),
        streak: user?['streak'] ?? 0,
        onContinue: () => Navigator.pop(context),
        onRepeat: _repeatLesson,
      );
    }

    if (finishing) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentExercise = exercises[currentIndex];

    if (currentExercise['type'] == 'theory') {
      return _theoryScreen(currentExercise);
    }

    final question = currentExercise['question'];
    final isTerminal = currentExercise['type'] == 'terminal';
    final options = isTerminal ? const <String>[] : List<String>.from(currentExercise['content']['options']);
    final progress = (currentIndex + (isCorrect != null ? 1 : 0)) / exercises.length;

    return Scaffold(
      appBar: _buildAppBar(progress: progress),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '\$ ${widget.sectionTitle}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFF00A896),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: _parseInlineCode(
                  question as String,
                  baseStyle: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    color: const Color(0xFF1B2430),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isTerminal)
              _TerminalInput(
                controller: _terminalController,
                enabled: isCorrect == null,
                onChanged: _chooseOption,
              )
            else
              for (final option in options)
                OptionCard(
                  text: option,
                  onTap: () => _chooseOption(option),
                  locked: isCorrect != null,
                  state: isCorrect != null
                      ? (option == correctAnswer
                            ? OptionState.correct
                            : option == selectedAnswer
                            ? OptionState.incorrect
                            : OptionState.none)
                      : (option == selectedAnswer ? OptionState.selected : OptionState.none),
                ),
            const Spacer(),
            if (isCorrect != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 74, right: 14, top: 14, bottom: 14),
                      decoration: BoxDecoration(
                        color: isCorrect! ? const Color(0xFFEAF9DC) : const Color(0xFFFFEAEA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCorrect! ? 'Правильно! ${isRepeat ? '' : '+10 XP'}'.trim() : 'Неверно',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w600,
                              color: isCorrect! ? const Color(0xFF2E6E00) : const Color(0xFFB33A3A),
                            ),
                          ),
                          if (!isCorrect! && correctAnswer != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Правильный ответ: $correctAnswer',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFB33A3A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      left: -10,
                      top: -20,
                      bottom: -20,
                      child: SizedBox(
                        width: 100,
                        child: Lottie.asset(
                          key: ValueKey(attemptCount),
                          isCorrect! ? 'assets/animations/success.json' : 'assets/animations/error.json',
                          controller: _lottieController,
                          fit: BoxFit.contain,
                          onLoaded: (composition) {
                            if (isCorrect!) {
                              _lottieController.duration = composition.duration ~/ 2;
                            } else {
                              _lottieController.duration = composition.duration;
                            }
                            _lottieController.forward(from: 0);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isCorrect == null)
              PrimaryButton(
                text: 'Проверить',
                enabled: !checking && selectedAnswer != null && selectedAnswer!.trim().isNotEmpty,
                onPressed: _checkAnswer,
              )
            else
              PrimaryButton(text: 'Продолжить', onPressed: _nextExercise),
          ],
        ),
      ),
    );
  }
}

/// Ввод команды текстом вместо выбора варианта — используется упражнениями
/// типа `terminal`, где нужно вспомнить/набрать команду самому.
class _TerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _TerminalInput({required this.controller, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            '\$',
            style: TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF00C9B7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              autocorrect: false,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 15, color: Colors.white),
              cursorColor: const Color(0xFF00C9B7),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Короткий брифинг перед миссией — контекст, зачем вообще нужен этот урок,
/// в духе "STORY"-шага из структуры миссии. Показывается каждый раз при
/// открытии урока, включая повтор — это брифинг, а не одноразовое интро.
class _StoryIntro extends StatefulWidget {
  final String sectionTitle;
  final String lessonTitle;
  final String story;
  final VoidCallback onContinue;

  const _StoryIntro({
    required this.sectionTitle,
    required this.lessonTitle,
    required this.story,
    required this.onContinue,
  });

  @override
  State<_StoryIntro> createState() => _StoryIntroState();
}

class _StoryIntroState extends State<_StoryIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _mascotScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _mascotScale = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack));
    const textInterval = Interval(0.3, 0.8, curve: Curves.easeOut);
    _fade = CurvedAnimation(parent: _controller, curve: textInterval);
    _slide = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: textInterval));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF5C6B73)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(scale: _mascotScale, child: const AnimatedMascot(size: 140)),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      children: [
                        Text(
                          '\$ ${widget.sectionTitle}',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: const Color(0xFF00A896),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.lessonTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            height: 1.2,
                            color: const Color(0xFF1B2430),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.story,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.5, color: const Color(0xFF5C6B73)),
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
                    child: PrimaryButton(text: 'Начать миссию', onPressed: widget.onContinue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
