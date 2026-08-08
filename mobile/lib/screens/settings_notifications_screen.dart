import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/user_prefs.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
        title: Text(
          'Уведомления',
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
                    title: 'Напоминание',
                    subtitle: 'каждый день в 20:00',
                    trailing: SettingsToggle(
                      value: remind,
                      onChanged: (v) =>
                          _saveBool(PrefKeys.remind, v, (x) => remind = x),
                    ),
                  ),
                  SettingsRow(
                    title: 'Защита streak',
                    subtitle: 'пропущенный день не сбросит 🔥',
                    trailing: SettingsToggle(
                      value: shield,
                      onChanged: (v) => _saveBool(
                        PrefKeys.streakShield,
                        v,
                        (x) => shield = x,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
    );
  }
}
