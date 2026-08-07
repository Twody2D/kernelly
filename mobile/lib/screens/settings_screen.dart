import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/user_prefs.dart';

class SettingsScreen extends StatefulWidget {
  final bool isGuest;
  final String? email;

  const SettingsScreen({super.key, required this.isGuest, this.email});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? prefs;

  bool remind = true;
  bool shield = false;
  bool sound = true;
  bool mascot = true;
  String theme = 'light';
  int goal = defaultDailyGoal;
  bool signingOut = false;

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
      sound = stored.getBool(PrefKeys.sound) ?? true;
      mascot = stored.getBool(PrefKeys.mascotAnimations) ?? true;
      theme = stored.getString(PrefKeys.theme) ?? 'light';
      goal = stored.getInt(PrefKeys.dailyGoal) ?? defaultDailyGoal;
    });
  }

  Future<void> _saveBool(String key, bool value, ValueChanged<bool> apply) async {
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

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, fontSize: 14),
          ),
          backgroundColor: const Color(0xFF1B2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
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
              decoration: BoxDecoration(color: const Color(0xFFDCE8E7), borderRadius: BorderRadius.circular(2)),
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
            for (final item in dailyGoals) ...[_goalOption(sheetContext, item), const SizedBox(height: 10)],
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
                    style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, color: const Color(0xFF5C6B73)),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected ? const Color(0xFF00C9B7) : const Color(0xFFC2CDCD),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Выйти из аккаунта?',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 17, color: const Color(0xFF1B2430)),
        ),
        content: Text(
          'Прогресс останется в аккаунте. Чтобы продолжить с ним на этом устройстве, нужно будет войти снова.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, height: 1.4, color: const Color(0xFF5C6B73)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Отмена',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF5C6B73)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Выйти',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFFFF4B4B)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => signingOut = true);
    try {
      await signOutAndResetToGuest();
    } catch (e) {
      if (mounted) {
        setState(() => signingOut = false);
        _soon('Не удалось выйти, попробуй ещё раз');
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
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
    if (prefs == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF5C6B73)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Настройки',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: const Color(0xFF1B2430),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _sectionLabel('\$ обучение'),
          _card([
            _row(title: 'Цель на день', subtitle: goalSubtitle(goal), trailing: _pill('изменить', _pickGoal)),
            _row(
              title: 'Напоминание',
              subtitle: 'каждый день в 20:00',
              trailing: _Toggle(value: remind, onChanged: (v) => _saveBool(PrefKeys.remind, v, (x) => remind = x)),
            ),
            _row(
              title: 'Защита streak',
              subtitle: 'пропущенный день не сбросит 🔥',
              trailing: _Toggle(
                value: shield,
                onChanged: (v) => _saveBool(PrefKeys.streakShield, v, (x) => shield = x),
              ),
            ),
            _row(
              title: 'Пройти онбординг заново',
              subtitle: 'знакомство с Kernel, темы и цель',
              trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC2CDCD)),
              onTap: _restartOnboarding,
            ),
          ]),
          const SizedBox(height: 18),
          _sectionLabel('\$ интерфейс'),
          _card([
            _themeRow(),
            _row(
              title: 'Звуки',
              trailing: _Toggle(value: sound, onChanged: (v) => _saveBool(PrefKeys.sound, v, (x) => sound = x)),
            ),
            _row(
              title: 'Анимации Kernel',
              subtitle: 'маскот реагирует на ответы',
              trailing: _Toggle(
                value: mascot,
                onChanged: (v) => _saveBool(PrefKeys.mascotAnimations, v, (x) => mascot = x),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionLabel('\$ аккаунт'),
          _card([
            _row(
              title: 'Почта',
              trailing: Text(
                widget.isGuest ? 'не привязана' : (widget.email ?? 'не привязана'),
                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: const Color(0xFF5C6B73)),
              ),
              onTap: widget.isGuest ? () => _soon('Вход в аккаунт появится позже') : null,
            ),
            if (!widget.isGuest)
              _row(
                title: 'Выйти',
                trailing: signingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC2CDCD)),
                      )
                    : const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC2CDCD)),
                onTap: signingOut ? null : _confirmSignOut,
              ),
          ]),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _soon('Удаление аккаунта появится позже'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFFFEAEA), borderRadius: BorderRadius.circular(16)),
              child: Text(
                'Удалить аккаунт',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: const Color(0xFFFF4B4B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'kernelly 1.0.0 · build 1',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: const Color(0xFF9AAAAA)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10.5, color: const Color(0xFF00A896)),
      ),
    );
  }

  Widget _card(List<Widget> rows) {
    final children = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(const Divider(height: 1.5, thickness: 1.5, color: Color(0xFFEEF4F3)));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _row({required String title, String? subtitle, required Widget trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF1B2430),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: const Color(0xFF5C6B73)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFE6F8F6), borderRadius: BorderRadius.circular(11)),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00A896),
          ),
        ),
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

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF00C9B7) : const Color(0xFFC2CDCD),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}
