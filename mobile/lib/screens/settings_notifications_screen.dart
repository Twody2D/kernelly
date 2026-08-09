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

// Должны совпадать с MAX_STREAK_FREEZES/STREAK_FREEZE_PRICE_CORES в backend/app/main.py —
// используются только для подписи и отключения кнопки, сама проверка на сервере.
const _maxStreakFreezes = 3;
const _streakFreezePriceCores = 40;

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> {
  SharedPreferences? prefs;
  bool remind = true;
  TimeOfDay remindTime = const TimeOfDay(hour: 20, minute: 0);
  bool shield = false;
  int cores = 0;
  int streakFreezes = 0;
  bool loadingStats = true;
  bool purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadStats();
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
      shield = stored.getBool(PrefKeys.streakShield) ?? false;
    });
  }

  Future<void> _loadStats() async {
    try {
      final stats = await fetchUserStats(currentUserId);
      if (!mounted) return;
      setState(() {
        cores = stats['cores'] as int? ?? 0;
        streakFreezes = stats['streak_freezes'] as int? ?? 0;
        loadingStats = false;
      });
    } catch (e) {
      debugPrint('Не удалось загрузить ядра/заряды: $e');
      if (!mounted) return;
      setState(() => loadingStats = false);
    }
  }

  Future<void> _purchaseFreeze() async {
    setState(() => purchasing = true);
    try {
      final result = await purchaseStreakFreeze(currentUserId);
      if (!mounted) return;
      setState(() {
        cores = result['cores'] as int;
        streakFreezes = result['streak_freezes'] as int;
        purchasing = false;
      });
    } on InsufficientCoresException {
      if (!mounted) return;
      setState(() => purchasing = false);
      _showSnackBar('Не хватает ядер — нужно $_streakFreezePriceCores');
    } on StreakFreezesMaxedException {
      if (!mounted) return;
      setState(() => purchasing = false);
      _showSnackBar('Уже максимум зарядов ($_maxStreakFreezes)');
    } catch (e) {
      if (!mounted) return;
      setState(() => purchasing = false);
      _showSnackBar('Не удалось купить, попробуй ещё раз');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    } else {
      await NotificationsService.instance.cancelDaily();
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
                  SettingsRow(
                    title: 'Защита streak',
                    subtitle: 'пропущенный день не сбросит 🔥',
                    trailing: SettingsToggle(
                      value: shield,
                      onChanged: _onShieldChanged,
                    ),
                  ),
                  SettingsRow(
                    title: 'Заряды защиты',
                    subtitle: loadingStats
                        ? 'загрузка…'
                        : '$streakFreezes из $_maxStreakFreezes · пополняется раз в неделю',
                    trailing: _freezeAction(),
                  ),
                  SettingsRow(
                    title: 'Ядра',
                    subtitle: 'за золото в уроках, курсы, достижения и вход',
                    trailing: Text(
                      loadingStats ? '…' : '📦 $cores',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.colors.accentDark,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _freezeAction() {
    if (loadingStats || purchasing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (streakFreezes >= _maxStreakFreezes) {
      final colors = context.colors;
      return Text(
        'максимум',
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          color: colors.textSecondary,
        ),
      );
    }
    return SettingsPill(
      text: cores >= _streakFreezePriceCores
          ? 'купить за $_streakFreezePriceCores ядер'
          : 'нужно $_streakFreezePriceCores ядер',
      onTap: _purchaseFreeze,
    );
  }
}
