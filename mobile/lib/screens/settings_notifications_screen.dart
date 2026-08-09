import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/notifications_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/settings_widgets.dart';

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> {
  SharedPreferences? prefs;
  bool remind = true;
  bool shield = false;

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
      remind = stored.getBool(PrefKeys.remind) ?? true;
      shield = stored.getBool(PrefKeys.streakShield) ?? false;
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

  Future<void> _onRemindChanged(bool value) async {
    await _saveBool(PrefKeys.remind, value, (x) => remind = x);
    if (value) {
      await NotificationsService.instance.scheduleDaily();
    } else {
      await NotificationsService.instance.cancelDaily();
    }
  }

  Future<void> _onShieldChanged(bool value) async {
    await _saveBool(PrefKeys.streakShield, value, (x) => shield = x);
    try {
      await updateStreakShield(currentUserId, value);
    } catch (e) {
      debugPrint('Не удалось синхронизировать защиту streak: $e');
    }
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
          'Уведомления',
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
                    title: 'Напоминание',
                    subtitle: 'каждый день в 20:00',
                    trailing: SettingsToggle(
                      value: remind,
                      onChanged: _onRemindChanged,
                    ),
                  ),
                  SettingsRow(
                    title: 'Защита streak',
                    subtitle: 'пропущенный день не сбросит 🔥',
                    trailing: SettingsToggle(
                      value: shield,
                      onChanged: _onShieldChanged,
                    ),
                  ),
                ]),
              ],
            ),
    );
  }
}
