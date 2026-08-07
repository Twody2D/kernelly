import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';

/// Ключи локальных настроек и общий список целей на день.
/// Онбординг записывает часть значений, экран настроек их читает и меняет.
class PrefKeys {
  static const onboardingDone = 'onboarding_done';
  static const onboardingTopics = 'onboarding_topics';
  static const dailyGoal = 'daily_goal';
  static const remind = 'settings_remind';
  static const streakShield = 'settings_streak_shield';
  static const sound = 'settings_sound';
  static const mascotAnimations = 'settings_mascot_animations';
  static const theme = 'settings_theme';
  static const deviceToken = 'device_token';
}

/// Id текущего пользователя (гостя) на этом устройстве. Заполняется один раз
/// при старте приложения через [ensureUserId] — до этого момента экраны
/// с обращениями к API запускаться не должны.
late int currentUserId;

/// Отдаёт device_token этого устройства, генерируя его при первом обращении.
Future<String> _deviceToken(SharedPreferences prefs) async {
  final existing = prefs.getString(PrefKeys.deviceToken);
  if (existing != null) return existing;

  final random = Random.secure();
  final token = List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
  await prefs.setString(PrefKeys.deviceToken, token);
  return token;
}

/// Находит или заводит гостевого пользователя для этого устройства и
/// сохраняет его id в [currentUserId]. Вызывается один раз при старте
/// приложения, до runApp.
Future<int> ensureUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final token = await _deviceToken(prefs);
  final user = await fetchOrCreateGuest(token);
  currentUserId = user['id'] as int;
  return currentUserId;
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
