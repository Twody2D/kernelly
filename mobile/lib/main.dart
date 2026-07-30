import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const KernellyApp());
}

class KernellyApp extends StatelessWidget {
  const KernellyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kernelly',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F9F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9B7),
          primary: const Color(0xFF00C9B7),
        ),
        textTheme: TextTheme(
          headlineSmall: GoogleFonts.fredoka(
            fontWeight: FontWeight.w600,
            fontSize: 21,
            color: const Color(0xFF1B2430),
          ),
          bodyMedium: GoogleFonts.inter(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C9B7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
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

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? exercise;
  String? selectedAnswer;
  bool? isCorrect;
  int attemptCount = 0;
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
    setState(() {
      exercise = data;
    });
  }

  void _selectAnswer(String answer) async {
    final correct = await submitAnswer(exercise!['id'], answer);
    setState(() {
      selectedAnswer = answer;
      isCorrect = correct;
      attemptCount++;
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
              child: InkWell(
                onTap: () => _selectAnswer(option),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE1EAEA), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '> ',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00A896),
                        ),
                      ),
                      Text(
                        option,
                        style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isCorrect != null)
              SizedBox(
                height: 150,
                child: Lottie.asset(
                  key: ValueKey(attemptCount),
                  isCorrect! ? 'assets/animations/success.json' : 'assets/animations/error.json',
                  controller: _lottieController,
                  onLoaded: (composition) {
                    if (isCorrect!) {
                      _lottieController.duration = composition.duration ~/ 3;
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
