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
}

const defaultDailyGoal = 3;

const dailyGoals = [
  {'lessons': 1, 'title': 'Спокойно', 'subtitle': '1 урок · ~5 минут'},
  {'lessons': 3, 'title': 'Обычно', 'subtitle': '3 урока · ~15 минут'},
  {'lessons': 5, 'title': 'Серьёзно', 'subtitle': '5 уроков · ~25 минут'},
  {'lessons': 10, 'title': 'Хардкор', 'subtitle': '10 уроков · ~50 минут'},
];

String goalSubtitle(int lessons) {
  final goal = dailyGoals.firstWhere(
    (g) => g['lessons'] == lessons,
    orElse: () => dailyGoals[1],
  );
  return goal['subtitle'] as String;
}
