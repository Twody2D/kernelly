import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_config.dart';

Future<List<Map<String, dynamic>>> fetchLessonExercises(int lessonId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/lessons/$lessonId/exercises'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lesson exercises');
  }
}

/// Находит или заводит гостевого пользователя по device_token устройства.
Future<Map<String, dynamic>> fetchOrCreateGuest(String deviceToken) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/guest'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'device_token': deviceToken}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to create guest user');
  }
}

/// Возвращает {correct: bool, correct_answer: String} — правильный вариант
/// приходит уже после ответа, чтобы его нельзя было подсмотреть заранее.
Future<Map<String, dynamic>> submitAnswer(int exerciseId, int userId, String answer) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/exercises/$exerciseId/submit'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'answer': {'answer': answer},
      'user_id': userId,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to submit answer');
  }
}

Future<Map<String, dynamic>> fetchUser(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/users/$userId'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load user');
  }
}

Future<int> awardXp(int userId, int correctCount) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/$userId/award-xp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'correct_count': correctCount}),
  );
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  return data['xp'];
}

Future<List<Map<String, dynamic>>> fetchLessonsProgress(int sectionId, int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/sections/$sectionId/lessons-progress?user_id=$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lessons progress');
  }
}

/// Возвращает контекст завершения: прогресс раздела, курса и что дальше.
Future<Map<String, dynamic>> completeLesson(int lessonId, int userId) async {
  final response = await http.post(Uri.parse('$apiBaseUrl/lessons/$lessonId/complete?user_id=$userId'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to complete lesson');
  }
}

/// Раздел, с которого продолжать. null — если проходить нечего.
Future<Map<String, dynamic>?> fetchCurrentSection(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/users/$userId/current-section'));

  if (response.statusCode == 200) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded == null ? null : decoded as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load current section');
  }
}

Future<Map<String, dynamic>> fetchSectionsProgress(int courseId, int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/courses/$courseId/sections-progress?user_id=$userId'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load sections progress');
  }
}

/// Сколько уроков пройдено сегодня — для дневной цели.
Future<Map<String, dynamic>> fetchDailyProgress(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/users/$userId/daily-progress'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load daily progress');
  }
}

Future<Map<String, dynamic>> fetchUserStats(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/users/$userId/stats'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load user stats');
  }
}

Future<Map<String, dynamic>> fetchUserActivity(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/users/$userId/activity'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load user activity');
  }
}

Future<Map<String, dynamic>> fetchUserAchievements(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/users/$userId/achievements'));

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load achievements');
  }
}

Future<List<Map<String, dynamic>>> fetchCoursesOverview(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/courses/overview?user_id=$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load courses overview');
  }
}
