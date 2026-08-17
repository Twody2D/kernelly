import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  TimeOfDay remindTime = const TimeOfDay(hour: 20, minute: 0);

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
      remindTime = TimeOfDay(
        hour: stored.getInt(PrefKeys.remindHour) ?? 20,
        minute: stored.getInt(PrefKeys.remindMinute) ?? 0,
      );
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
      await NotificationsService.instance.scheduleDaily(time: remindTime);
      await NotificationsService.instance.scheduleStreakAtRisk();
    } else {
      await NotificationsService.instance.cancelDaily();
      await NotificationsService.instance.cancelStreakAtRisk();
    }
  }

  Future<void> _pickRemindTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: remindTime,
    );
    if (picked == null) return;
    setState(() => remindTime = picked);
    await prefs?.setInt(PrefKeys.remindHour, picked.hour);
    await prefs?.setInt(PrefKeys.remindMinute, picked.minute);
    if (remind) {
      await NotificationsService.instance.scheduleDaily(time: picked);
    }
  }

  String get _remindTimeLabel {
    final h = remindTime.hour.toString().padLeft(2, '0');
    final m = remindTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
                    subtitle: 'каждый день, если не позанимался',
                    trailing: SettingsToggle(
                      value: remind,
                      onChanged: _onRemindChanged,
                    ),
                  ),
                  if (remind)
                    SettingsRow(
                      title: 'Время напоминания',
                      trailing: SettingsPill(
                        text: _remindTimeLabel,
                        onTap: _pickRemindTime,
                      ),
                    ),
                ]),
              ],
            ),
    );
  }
}
