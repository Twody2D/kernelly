import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

Future<bool> submitAnswer(int exerciseId, String answer) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/exercises/$exerciseId/submit'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'answer': {'answer': answer}}),
  );

  final data = jsonDecode(response.body);
  return data['correct'];
}

Future<Map<String, dynamic>> fetchExercise() async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/exercises'));

  if (response.statusCode == 200) {
    final List<dynamic> exercises = jsonDecode(response.body);
    return exercises.first as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load exercise');
  }
}

class _LessonScreenState extends State<LessonScreen> {
  Map<String, dynamic>? exercise;
  String? selectedAnswer;
  bool? isCorrect;

  @override
  void initState() {
    super.initState();
    loadExercise();
  }

  Future<void> loadExercise() async {
    final data = await fetchExercise();
    setState(() {
      exercise = data;
    });
  }

  void _selectAnswer(String answer) async {
    final correct = await submitAnswer(exercise!['id'], answer);
      setState(() {
        selectedAnswer = answer;
        isCorrect = correct;
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
