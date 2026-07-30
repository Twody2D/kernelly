import 'package:flutter/material.dart';

void main() {
  runApp(const KernellyApp());
}

class KernellyApp extends StatelessWidget {
  const KernellyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kernelly',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const LessonScreen(),
    );
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final String question = 'Какая команда показывает содержимое текущей папки в Linux?';
  final List<String> options = ['ls', 'cd', 'pwd', 'rm'];
  final String correctAnswer = 'ls';

  String? selectedAnswer;
  bool? isCorrect;

  void _selectAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      isCorrect = answer == correctAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kernelly')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => _selectAnswer(option),
                  child: Text(option),
                ),
              ),
            if (isCorrect != null)
              Text(
                isCorrect! ? 'Правильно!' : 'Неверно, попробуйте ещё раз',
                style: TextStyle(
                  color: isCorrect! ? Colors.green : Colors.red,
                  fontSize: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}