import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchExercise() async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/exercises'));

  if (response.statusCode == 200) {
    final List<dynamic> exercises = jsonDecode(response.body);
    return exercises.first as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load exercise');
  }
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