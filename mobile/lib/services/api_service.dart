import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchLessonExercises(int lessonId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/lessons/$lessonId/exercises'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lesson exercises');
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

Future<Map<String, dynamic>> fetchUser(int userId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/$userId'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load user');
  }
}

Future<int> awardXp(int userId, int correctCount) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/users/$userId/award-xp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'correct_count': correctCount}),
  );
  final data = jsonDecode(response.body);
  return data['xp'];
}

Future<List<Map<String, dynamic>>> fetchCourses() async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/courses'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load courses');
  }
}

Future<List<Map<String, dynamic>>> fetchLessonsProgress(int sectionId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/sections/$sectionId/lessons-progress'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lessons progress');
  }
}

Future<List<Map<String, dynamic>>> fetchCourseSections(int courseId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/courses/$courseId/sections'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load course sections');
  }
}

Future<void> completeLesson(int lessonId) async {
  await http.post(Uri.parse('http://127.0.0.1:8000/lessons/$lessonId/complete'));
}