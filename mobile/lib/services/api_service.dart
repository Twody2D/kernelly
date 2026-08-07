import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchLessonExercises(int lessonId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/lessons/$lessonId/exercises'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lesson exercises');
  }
}

/// Возвращает {correct: bool, correct_answer: String} — правильный вариант
/// приходит уже после ответа, чтобы его нельзя было подсмотреть заранее.
Future<Map<String, dynamic>> submitAnswer(int exerciseId, String answer) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/exercises/$exerciseId/submit'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'answer': {'answer': answer},
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to submit answer');
  }
}

Future<Map<String, dynamic>> fetchUser(int userId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/$userId'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
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
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  return data['xp'];
}

Future<List<Map<String, dynamic>>> fetchLessonsProgress(int sectionId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/sections/$sectionId/lessons-progress'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lessons progress');
  }
}

/// Возвращает контекст завершения: прогресс раздела, курса и что дальше.
Future<Map<String, dynamic>> completeLesson(int lessonId) async {
  final response = await http.post(Uri.parse('http://127.0.0.1:8000/lessons/$lessonId/complete'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to complete lesson');
  }
}

/// Раздел, с которого продолжать. null — если проходить нечего.
Future<Map<String, dynamic>?> fetchCurrentSection(int userId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/$userId/current-section'));

  if (response.statusCode == 200) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded == null ? null : decoded as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load current section');
  }
}

Future<Map<String, dynamic>> fetchSectionsProgress(int courseId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/courses/$courseId/sections-progress'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load sections progress');
  }
}

Future<Map<String, dynamic>> fetchUserStats(int userId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/$userId/stats'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load user stats');
  }
}

Future<Map<String, dynamic>> fetchUserActivity(int userId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/$userId/activity'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load user activity');
  }
}

Future<Map<String, dynamic>> fetchUserAchievements(int userId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/$userId/achievements'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load achievements');
  }
}

Future<List<Map<String, dynamic>>> fetchCoursesOverview() async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/courses/overview'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load courses overview');
  }
}
