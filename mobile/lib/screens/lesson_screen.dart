import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/option_card.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? exercise;
  String? selectedAnswer;
  bool? isCorrect;
  int attemptCount = 0;
  Map<String, dynamic>? user;

  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    loadExercise();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> loadExercise() async {
    final data = await fetchExercise();
    final userData = await fetchUser(1);
    setState(() {
      exercise = data;
      user = userData;
    });
  }

  void _selectAnswer(String answer) async {
    final correct = await submitAnswer(exercise!['id'], answer);
    final userData = await fetchUser(1);
    setState(() {
      selectedAnswer = answer;
      isCorrect = correct;
      attemptCount++;
      user = userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (exercise == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = exercise!['question'];
    final options = List<String>.from(exercise!['content']['options']);

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
            Text(question, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            for (final option in options)
              OptionCard(text: option, onTap: () => _selectAnswer(option)),
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
          ],
        ),
      ),
    );
  }
}