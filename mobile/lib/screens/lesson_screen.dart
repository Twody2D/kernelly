import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/services/api_service.dart';
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
  int currentIndex = 0;
  String? selectedAnswer;
  bool? isCorrect;
  int attemptCount = 0;
  Map<String, dynamic>? user;
  int correctCount = 0;
  bool finishing = false;
  DateTime? startTime;

  /// Ответ на завершение урока: прогресс раздела, курса и что дальше
  Map<String, dynamic>? completion;

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
    super.dispose();
  }

  Future<void> loadLesson() async {
    final data = await fetchLessonExercises(widget.lessonId);
    final userData = await fetchUser(1);
    setState(() {
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
    final currentExercise = exercises[currentIndex];
    final correct = await submitAnswer(currentExercise['id'], selectedAnswer!);
    final userData = await fetchUser(1);
    setState(() {
      isCorrect = correct;
      attemptCount++;
      user = userData;
      if (correct) correctCount++;
    });
  }

  void _nextExercise() {
    if (currentIndex + 1 >= exercises.length) {
      _finishLesson();
      return;
    }
    setState(() {
      currentIndex++;
      selectedAnswer = null;
      isCorrect = null;
    });
  }

  Future<void> _finishLesson() async {
    if (finishing || completion != null) return;
    setState(() => finishing = true);

    try {
      final newXp = await awardXp(1, correctCount);
      final data = await completeLesson(widget.lessonId);
      if (!mounted) return;
      setState(() {
        user?['xp'] = newXp;
        completion = data;
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

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (completion != null) {
      return SectionCompleteScreen(
        completion: completion!,
        xpEarned: correctCount * 10,
        accuracyPercent: exercises.isEmpty ? 0 : ((correctCount / exercises.length) * 100).round(),
        elapsed: startTime == null ? Duration.zero : DateTime.now().difference(startTime!),
        streak: user?['streak'] ?? 0,
        onContinue: () => Navigator.pop(context),
        onRepeat: () => Navigator.pop(context),
      );
    }

    if (finishing) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentExercise = exercises[currentIndex];
    final question = currentExercise['question'];
    final options = List<String>.from(currentExercise['content']['options']);
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
            Text(
              question,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 21,
                color: const Color(0xFF1B2430),
              ),
            ),
            const SizedBox(height: 24),
            for (final option in options)
              OptionCard(
                text: option,
                onTap: () => _chooseOption(option),
                locked: isCorrect != null,
                state: isCorrect != null
                    ? (option == selectedAnswer
                          ? (isCorrect! ? OptionState.correct : OptionState.incorrect)
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
                      child: Text(
                        isCorrect! ? 'Правильно! +10 XP' : 'Неверно, попробуйте ещё раз',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w600,
                          color: isCorrect! ? const Color(0xFF2E6E00) : const Color(0xFFB33A3A),
                        ),
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
              PrimaryButton(text: 'Проверить', enabled: selectedAnswer != null, onPressed: _checkAnswer)
            else
              PrimaryButton(text: 'Продолжить', onPressed: _nextExercise),
          ],
        ),
      ),
    );
  }
}
