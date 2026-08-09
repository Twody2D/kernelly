import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_config.dart';
import 'package:mobile/services/user_prefs.dart' show currentDeviceToken;

/// device_token этого устройства как Bearer-токен — сервер проверяет им, что
/// запрос действительно от заявленного пользователя, а не просто доверяет
/// user_id, присланному в параметрах (раньше так и было — любой мог
/// подставить чужой id и читать/менять чужие данные).
Map<String, String> _authHeaders([Map<String, String>? extra]) => {
  'Authorization': 'Bearer $currentDeviceToken',
  ...?extra,
};

const _jsonHeaders = {'Content-Type': 'application/json'};

Future<Map<String, dynamic>> fetchLesson(int lessonId, int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/lessons/$lessonId?user_id=$userId'),
    headers: _authHeaders(),
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
    headers: _authHeaders(),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load lesson exercises');
  }
}

/// Находит или заводит гостевого пользователя по device_token устройства —
/// единственный запрос, который выполняется ещё без токена (он его и выдаёт).
Future<Map<String, dynamic>> fetchOrCreateGuest(String deviceToken) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/guest'),
    headers: _jsonHeaders,
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
    headers: _authHeaders(_jsonHeaders),
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
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId'),
    headers: _authHeaders(),
  );

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
    headers: _authHeaders(_jsonHeaders),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load daily progress');
  }
}

Future<Map<String, dynamic>> fetchUserStats(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/stats'),
    headers: _authHeaders(),
  );

  if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Failed to load user stats');
  }
}

Future<Map<String, dynamic>> fetchUserActivity(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/activity'),
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(_jsonHeaders),
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

/// Синхронизирует тумблер «Защита streak» с бэкендом — сама логика заморозки
/// применяется на сервере при обработке следующего пропущенного дня.
Future<void> updateStreakShield(int userId, bool enabled) async {
  final response = await http.patch(
    Uri.parse('$apiBaseUrl/users/$userId/streak-shield'),
    headers: _authHeaders(_jsonHeaders),
    body: jsonEncode({'enabled': enabled}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to update streak shield');
  }
}

/// Бросается, когда номер телефона уже привязан к другому аккаунту (409 от сервера).
class PhoneTakenException implements Exception {}

Future<Map<String, dynamic>> updatePhone(int userId, String? phone) async {
  final response = await http.patch(
    Uri.parse('$apiBaseUrl/users/$userId/phone'),
    headers: _authHeaders(_jsonHeaders),
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

/// Меняет device_token на сервере на новый, обесценивая прежний — на случай,
/// если он мог утечь. Сам локальный токен на устройстве обновляет вызывающий
/// код (см. rotateDeviceToken в user_prefs.dart), иначе следующий же запрос
/// с этого устройства пойдёт со старым, уже недействительным токеном.
Future<String> rotateToken(int userId) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/$userId/rotate-token'),
    headers: _authHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to rotate token');
  }
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  return data['device_token'] as String;
}

/// Сопоставляет номера из телефонной книги с пользователями Kernelly,
/// у которых привязан телефон.
Future<List<Map<String, dynamic>>> matchContacts(
  int userId,
  List<String> phones,
) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/users/$userId/contacts-match'),
    headers: _authHeaders(_jsonHeaders),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to follow user');
  }
}

Future<void> unfollowUser(int userId, int targetId) async {
  final response = await http.delete(
    Uri.parse('$apiBaseUrl/users/$userId/follow/$targetId'),
    headers: _authHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to unfollow user');
  }
}

/// [viewerId] сохранён для обратной совместимости вызовов, но сервер больше
/// не доверяет этому параметру — is_following/is_friend всегда считаются от
/// токена, поэтому по факту он теперь ни на что не влияет.
Future<List<Map<String, dynamic>>> fetchFollowing(
  int userId, {
  int? viewerId,
}) async {
  final response = await http.get(
    Uri.parse(
      '$apiBaseUrl/users/$userId/following${viewerId == null ? '' : '?viewer_id=$viewerId'}',
    ),
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(),
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
    headers: _authHeaders(_jsonHeaders),
    body: jsonEncode({'text': text}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to create post');
  }
}

/// Лента активности: посты и разблокировки достижений от тех, на кого подписан.
Future<List<Map<String, dynamic>>> fetchFeed(int userId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/users/$userId/feed'),
    headers: _authHeaders(),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load feed');
  }
}
