import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_config.dart';

Future<Map<String, dynamic>> fetchLesson(int lessonId, int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/lessons/$lessonId?user_id=$userId'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load lesson');
  }
}

Future<List<Map<String, dynamic>>> fetchLessonExercises(
  int lessonId,
  int userId,
) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/lessons/$lessonId/exercises?user_id=$userId'),
  );

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

/// Возвращает {correct: bool, correct_answer: String, streak: int} — правильный
/// вариант приходит уже после ответа, чтобы его нельзя было подсмотреть заранее,
/// а streak сразу актуальный, без отдельного похода за пользователем.
Future<Map<String, dynamic>> submitAnswer(
  int exerciseId,
  int userId,
  String answer,
) async {
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

/// Возвращает {xp: int, new_achievements: [...]} — список того, что только
/// что разблокировалось за счёт начисленного XP.
Future<Map<String, dynamic>> awardXp(int userId, int correctCount) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/$userId/award-xp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'correct_count': correctCount}),
  );
  return jsonDecode(utf8.decode(response.bodyBytes));
}

Future<List<Map<String, dynamic>>> fetchLessonsProgress(
  int sectionId,
  int userId,
) async {
  final response = await http.get(
    Uri.parse(
      '$apiBaseUrl/sections/$sectionId/lessons-progress?user_id=$userId',
    ),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lessons progress');
  }
}

/// Возвращает контекст завершения: прогресс раздела, курса и что дальше.
Future<Map<String, dynamic>> completeLesson(int lessonId, int userId) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/lessons/$lessonId/complete?user_id=$userId'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to complete lesson');
  }
}

/// Раздел, с которого продолжать. null — если проходить нечего.
Future<Map<String, dynamic>?> fetchCurrentSection(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/current-section'),
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded == null ? null : decoded as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load current section');
  }
}

Future<Map<String, dynamic>> fetchSectionsProgress(
  int courseId,
  int userId,
) async {
  final response = await http.get(
    Uri.parse(
      '$apiBaseUrl/courses/$courseId/sections-progress?user_id=$userId',
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load sections progress');
  }
}

/// Сколько уроков пройдено сегодня — для дневной цели.
Future<Map<String, dynamic>> fetchDailyProgress(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/daily-progress'),
  );

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
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/activity'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load user activity');
  }
}

Future<Map<String, dynamic>> fetchUserAchievements(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/achievements'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load achievements');
  }
}

/// Бросается, когда имя уже занято другим пользователем (409 от сервера).
class UsernameTakenException implements Exception {}

Future<Map<String, dynamic>> updateProfile(
  int userId,
  String username,
  String avatar,
) async {
  final response = await http.patch(
    Uri.parse('$apiBaseUrl/users/$userId/profile'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'avatar': avatar}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else if (response.statusCode == 409) {
    throw UsernameTakenException();
  } else {
    throw Exception('Failed to update profile');
  }
}

/// Бросается, когда номер телефона уже привязан к другому аккаунту (409 от сервера).
class PhoneTakenException implements Exception {}

Future<Map<String, dynamic>> updatePhone(int userId, String? phone) async {
  final response = await http.patch(
    Uri.parse('$apiBaseUrl/users/$userId/phone'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else if (response.statusCode == 409) {
    throw PhoneTakenException();
  } else {
    throw Exception('Failed to update phone');
  }
}

/// Сопоставляет номера из телефонной книги с пользователями Kernelly,
/// у которых привязан телефон.
Future<List<Map<String, dynamic>>> matchContacts(
  int userId,
  List<String> phones,
) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/$userId/contacts-match'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phones': phones}),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to match contacts');
  }
}

/// Сколько навыков сейчас просрочено для повторения — бейдж на карточке ревью.
Future<int> fetchReviewDue(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/review/due'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['due'] as int;
  } else {
    throw Exception('Failed to load review due count');
  }
}

/// Набор упражнений для сессии повторения — по одному на каждый просроченный навык.
Future<List<Map<String, dynamic>>> fetchReviewSession(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/review/session'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load review session');
  }
}

Future<List<Map<String, dynamic>>> fetchCoursesOverview(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/courses/overview?user_id=$userId'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load courses overview');
  }
}

/// Топ игроков по XP за последние 7 дней: {entries: [...], me: {...}?}.
Future<Map<String, dynamic>> fetchLeaderboard(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/leaderboard?user_id=$userId'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load leaderboard');
  }
}

Future<void> followUser(int userId, int targetId) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/$userId/follow/$targetId'),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to follow user');
  }
}

Future<void> unfollowUser(int userId, int targetId) async {
  final response = await http.delete(
    Uri.parse('$apiBaseUrl/users/$userId/follow/$targetId'),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to unfollow user');
  }
}

/// [viewerId] — от чьего лица считать is_following/is_friend в списке; нужен,
/// когда смотрим подписки чужого профиля, а не свои собственные.
Future<List<Map<String, dynamic>>> fetchFollowing(
  int userId, {
  int? viewerId,
}) async {
  final response = await http.get(
    Uri.parse(
      '$apiBaseUrl/users/$userId/following${viewerId == null ? '' : '?viewer_id=$viewerId'}',
    ),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load following list');
  }
}

Future<List<Map<String, dynamic>>> fetchFollowers(
  int userId, {
  int? viewerId,
}) async {
  final response = await http.get(
    Uri.parse(
      '$apiBaseUrl/users/$userId/followers${viewerId == null ? '' : '?viewer_id=$viewerId'}',
    ),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load followers list');
  }
}

/// «Вы можете их знать» — те, на кого подписаны твои подписки.
Future<List<Map<String, dynamic>>> fetchSuggestions(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/suggestions'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load suggestions');
  }
}

Future<List<Map<String, dynamic>>> searchUsers(int userId, String query) async {
  final response = await http.get(
    Uri.parse(
      '$apiBaseUrl/users/search?user_id=$userId&q=${Uri.encodeQueryComponent(query)}',
    ),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to search users');
  }
}

Future<void> createPost(int userId, String text) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/$userId/posts'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'text': text}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to create post');
  }
}

/// Лента активности: посты и разблокировки достижений от тех, на кого подписан.
Future<List<Map<String, dynamic>>> fetchFeed(int userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/users/$userId/feed'));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load feed');
  }
}
