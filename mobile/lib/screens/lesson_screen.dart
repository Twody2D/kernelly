import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/option_card.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

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
    final data = await fetchLessonExercises(1);
    final userData = await fetchUser(1);
    setState(() {
      exercises = data;
      user = userData;
    });
  }

  void _selectAnswer(String answer) async {
    final currentExercise = exercises[currentIndex];
    final correct = await submitAnswer(currentExercise['id'], answer);
    final userData = await fetchUser(1);
    setState(() {
      selectedAnswer = answer;
      isCorrect = correct;
      attemptCount++;
      user = userData;
    });
  }

  void _nextExercise() {
    setState(() {
      currentIndex++;
      selectedAnswer = null;
      isCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentIndex >= exercises.length) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF5C6B73)),
            onPressed: () {},
          ),
          title: null,
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
        ),
        body: const Center(child: Text('Урок завершён! 🎉')),
      );
    }

    final currentExercise = exercises[currentIndex];
    final question = currentExercise['question'];
    final options = List<String>.from(currentExercise['content']['options']);
    final progress = (currentIndex) / exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kernelly'),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: const Color(0xFFE7EEEE),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00C9B7)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '\$ работа с файлами',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFF00A896),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(question, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            for (final option in options)
              OptionCard(
                text: option,
                onTap: () => _selectAnswer(option),
                state: selectedAnswer == null
                    ? OptionState.none
                    : (option == selectedAnswer
                        ? (isCorrect! ? OptionState.correct : OptionState.incorrect)
                        : OptionState.none),
              ),
            if (isCorrect != null)
              SizedBox(
                height: 150,
                child: Lottie.asset(
                  key: ValueKey(attemptCount),
                  isCorrect!
                      ? 'assets/animations/success.json'
                      : 'assets/animations/error.json',
                  controller: _lottieController,
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
            if (isCorrect != null)
              ElevatedButton(
                onPressed: _nextExercise,
                child: const Text('Продолжить'),
              ),
          ],
        ),
      ),
    );
  }
}