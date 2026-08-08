import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/onboarding_screen.dart';
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
    });
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
  }

  Future<void> _saveGoal(int lessons) async {
    setState(() => goal = lessons);
    await prefs?.setInt(PrefKeys.dailyGoal, lessons);
  }

  Future<void> _pickGoal() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F9F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE8E7),
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
                color: const Color(0xFF1B2430),
              ),
            ),
            const SizedBox(height: 14),
            for (final item in dailyGoals) ...[
              _goalOption(sheetContext, item),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );

    if (selected != null) await _saveGoal(selected);
  }

  Widget _goalOption(BuildContext sheetContext, Map<String, Object> item) {
    final lessons = item['lessons'] as int;
    final selected = goal == lessons;

    return GestureDetector(
      onTap: () => Navigator.pop(sheetContext, lessons),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F8F6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF00C9B7) : const Color(0xFFDCE8E7),
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
                      color: const Color(0xFF1B2430),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['subtitle'] as String,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.5,
                      color: const Color(0xFF5C6B73),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected
                  ? const Color(0xFF00C9B7)
                  : const Color(0xFFC2CDCD),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
        title: Text(
          'Курсы',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: const Color(0xFF1B2430),
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
                    title: 'Цель на день',
                    subtitle: goalSubtitle(goal),
                    trailing: SettingsPill(text: 'изменить', onTap: _pickGoal),
                  ),
                  SettingsRow(
                    title: 'Пройти онбординг заново',
                    subtitle: 'знакомство с Kernel, темы и цель',
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFFC2CDCD),
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
              color: const Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _themeOption('светлая', 'light')),
              const SizedBox(width: 8),
              Expanded(child: _themeOption('тёмная', 'dark')),
              const SizedBox(width: 8),
              Expanded(child: _themeOption('авто', 'auto')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeOption(String label, String value) {
    final selected = theme == value;

    return GestureDetector(
      onTap: () => _saveTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F8F6) : const Color(0xFFF2F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF00A896) : const Color(0xFF8D9C9C),
          ),
        ),
      ),
    );
  }
}
