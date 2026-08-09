import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/theme_controller.dart';
import 'package:mobile/widgets/settings_widgets.dart';

/// Настройки, связанные с прохождением курсов: цель на день, звук и анимации
/// во время урока, тема оформления, а также повтор онбординга.
class SettingsCoursesScreen extends StatefulWidget {
  const SettingsCoursesScreen({super.key});

  @override
  State<SettingsCoursesScreen> createState() => _SettingsCoursesScreenState();
}

class _SettingsCoursesScreenState extends State<SettingsCoursesScreen> {
  SharedPreferences? prefs;
  bool sound = true;
  bool mascot = true;
  String theme = 'light';
  int goal = defaultDailyGoal;
  int? selectedCourseId;
  List<Map<String, dynamic>>? courses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      prefs = stored;
      sound = stored.getBool(PrefKeys.sound) ?? true;
      mascot = stored.getBool(PrefKeys.mascotAnimations) ?? true;
      theme = stored.getString(PrefKeys.theme) ?? 'light';
      goal = stored.getInt(PrefKeys.dailyGoal) ?? defaultDailyGoal;
      selectedCourseId = stored.getInt(PrefKeys.selectedCourseId);
    });

    try {
      final result = await fetchCoursesOverview(currentUserId);
      if (!mounted) return;
      setState(() => courses = result);
    } catch (e) {
      debugPrint('Ошибка загрузки курсов: $e');
    }
  }

  String get _selectedCourseTitle {
    if (courses == null || selectedCourseId == null) return 'автоматически';
    for (final course in courses!) {
      if (course['id'] == selectedCourseId) return course['title'] as String;
    }
    return 'автоматически';
  }

  Future<void> _pickCourse() async {
    if (courses == null || courses!.isEmpty) return;
    final colors = context.colors;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Курс',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            for (final course in courses!) ...[
              _courseOption(sheetContext, course, colors),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() => selectedCourseId = selected);
      await prefs?.setInt(PrefKeys.selectedCourseId, selected);
    }
  }

  Widget _courseOption(BuildContext sheetContext, Map<String, dynamic> course, AppColors colors) {
    final id = course['id'] as int;
    final locked = course['locked'] == true;
    final selected = !locked && selectedCourseId == id;

    return GestureDetector(
      onTap: locked ? null : () => Navigator.pop(sheetContext, id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? colors.accentBg : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] as String,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: locked ? colors.locked : colors.textPrimary,
                    ),
                  ),
                  if (locked && course['requirement'] != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      course['requirement'] as String,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              locked
                  ? Icons.lock_rounded
                  : (selected ? Icons.check_circle : Icons.circle_outlined),
              size: 22,
              color: locked ? colors.locked : (selected ? colors.accent : colors.locked),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBool(
    String key,
    bool value,
    ValueChanged<bool> apply,
  ) async {
    setState(() => apply(value));
    await prefs?.setBool(key, value);
  }

  Future<void> _saveTheme(String value) async {
    setState(() => theme = value);
    await prefs?.setString(PrefKeys.theme, value);
    themeController.setTheme(value);
  }

  Future<void> _saveGoal(int lessons) async {
    setState(() => goal = lessons);
    await prefs?.setInt(PrefKeys.dailyGoal, lessons);
  }

  Future<void> _pickGoal() async {
    final colors = context.colors;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Цель на день',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            for (final item in dailyGoals) ...[
              _goalOption(sheetContext, item, colors),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );

    if (selected != null) await _saveGoal(selected);
  }

  Widget _goalOption(BuildContext sheetContext, Map<String, Object> item, AppColors colors) {
    final lessons = item['lessons'] as int;
    final selected = goal == lessons;

    return GestureDetector(
      onTap: () => Navigator.pop(sheetContext, lessons),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? colors.accentBg : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['subtitle'] as String,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected ? colors.accent : colors.locked,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restartOnboarding() async {
    await prefs?.setBool(PrefKeys.onboardingDone, false);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          'Курсы',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                SettingsCard([
                  SettingsRow(
                    title: 'Курс',
                    subtitle: 'с какого курса продолжать путь',
                    trailing: SettingsPill(text: _selectedCourseTitle, onTap: _pickCourse),
                  ),
                  SettingsRow(
                    title: 'Цель на день',
                    subtitle: goalSubtitle(goal),
                    trailing: SettingsPill(text: 'изменить', onTap: _pickGoal),
                  ),
                  SettingsRow(
                    title: 'Пройти онбординг заново',
                    subtitle: 'знакомство с Kernel, темы и цель',
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colors.locked,
                    ),
                    onTap: _restartOnboarding,
                  ),
                ]),
                const SizedBox(height: 18),
                SettingsSectionLabel('\$ во время урока'),
                SettingsCard([
                  SettingsRow(
                    title: 'Звуки',
                    trailing: SettingsToggle(
                      value: sound,
                      onChanged: (v) =>
                          _saveBool(PrefKeys.sound, v, (x) => sound = x),
                    ),
                  ),
                  SettingsRow(
                    title: 'Анимации Kernel',
                    subtitle: 'маскот реагирует на ответы',
                    trailing: SettingsToggle(
                      value: mascot,
                      onChanged: (v) => _saveBool(
                        PrefKeys.mascotAnimations,
                        v,
                        (x) => mascot = x,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                SettingsSectionLabel('\$ оформление'),
                SettingsCard([_themeRow()]),
              ],
            ),
    );
  }

  Widget _themeRow() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тема',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _themeOption('светлая', 'light', colors)),
              const SizedBox(width: 8),
              Expanded(child: _themeOption('тёмная', 'dark', colors)),
              const SizedBox(width: 8),
              Expanded(child: _themeOption('авто', 'auto', colors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeOption(String label, String value, AppColors colors) {
    final selected = theme == value;

    return GestureDetector(
      onTap: () => _saveTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accentBg : colors.divider,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? colors.accentDark : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
