import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';

/// Ключи локальных настроек и общий список целей на день.
/// Онбординг записывает часть значений, экран настроек их читает и меняет.
class PrefKeys {
  static const onboardingDone = 'onboarding_done';
  static const selectedCourseId = 'selected_course_id';
  static const dailyGoal = 'daily_goal';
  static const remind = 'settings_remind';
  static const streakShield = 'settings_streak_shield';
  static const sound = 'settings_sound';
  static const mascotAnimations = 'settings_mascot_animations';
  static const theme = 'settings_theme';
  static const deviceToken = 'device_token';
  static const introSeenCourses = 'intro_seen_courses';
}

/// Показывали ли уже вводный экран-историю для этого курса на этом устройстве —
/// чтобы не повторять её при каждом входе в курс.
Future<bool> hasSeenCourseIntro(int courseId) async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getStringList(PrefKeys.introSeenCourses) ?? [];
  return seen.contains(courseId.toString());
}

Future<void> markCourseIntroSeen(int courseId) async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getStringList(PrefKeys.introSeenCourses) ?? [];
  if (!seen.contains(courseId.toString())) {
    await prefs.setStringList(PrefKeys.introSeenCourses, [...seen, courseId.toString()]);
  }
}

/// Id текущего пользователя на этом устройстве — гостя или того, в чей
/// аккаунт он вошёл через Google. Заполняется один раз при старте приложения
/// через [ensureUserId], а после успешного входа обновляется на месте (см.
/// auth_service.dart), пока до перезапуска не прочитается заново.
late int currentUserId;

/// device_token этого устройства — единственный ключ, по которому сервер
/// находит пользователя (гостя или уже вошедшего) заново при каждом старте.
late String currentDeviceToken;

String _generateToken() {
  final random = Random.secure();
  return List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
}

/// Отдаёт device_token этого устройства, генерируя его при первом обращении.
Future<String> _deviceToken(SharedPreferences prefs) async {
  final existing = prefs.getString(PrefKeys.deviceToken);
  if (existing != null) return existing;

  final token = _generateToken();
  await prefs.setString(PrefKeys.deviceToken, token);
  return token;
}

/// Находит или заводит пользователя для этого устройства и сохраняет его id
/// в [currentUserId]. Вызывается один раз при старте приложения, до runApp.
Future<int> ensureUserId() async {
  final prefs = await SharedPreferences.getInstance();
  currentDeviceToken = await _deviceToken(prefs);
  final user = await fetchOrCreateGuest(currentDeviceToken);
  currentUserId = user['id'] as int;
  return currentUserId;
}

/// Отвязывает устройство от текущего аккаунта и заводит нового гостя — вызывается
/// при выходе из аккаунта. Меняем device_token на новый, иначе /users/guest снова
/// нашёл бы прежнего (уже привязанного к Google) пользователя, а не создал гостя.
Future<int> resetGuestIdentity() async {
  final prefs = await SharedPreferences.getInstance();
  final token = _generateToken();
  await prefs.setString(PrefKeys.deviceToken, token);
  currentDeviceToken = token;

  final user = await fetchOrCreateGuest(token);
  currentUserId = user['id'] as int;
  return currentUserId;
}

/// Обесценивает текущий device_token на сервере и запоминает новый локально —
/// на случай подозрения, что старый токен мог утечь (в отличие от
/// [resetGuestIdentity], аккаунт остаётся тем же, меняется только ключ доступа).
Future<void> rotateDeviceToken() async {
  final newToken = await rotateToken(currentUserId);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PrefKeys.deviceToken, newToken);
  currentDeviceToken = newToken;
}

const defaultDailyGoal = 3;

const dailyGoals = [
  {'lessons': 1, 'title': 'Спокойно', 'subtitle': '1 урок · ~5 минут'},
  {'lessons': 3, 'title': 'Обычно', 'subtitle': '3 урока · ~15 минут'},
  {'lessons': 5, 'title': 'Серьёзно', 'subtitle': '5 уроков · ~25 минут'},
  {'lessons': 10, 'title': 'Хардкор', 'subtitle': '10 уроков · ~50 минут'},
];

String goalSubtitle(int lessons) {
  final goal = dailyGoals.firstWhere((g) => g['lessons'] == lessons, orElse: () => dailyGoals[1]);
  return goal['subtitle'] as String;
}
