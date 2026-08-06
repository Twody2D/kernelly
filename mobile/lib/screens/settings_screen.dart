import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool remind = true;
  bool shield = false;
  bool sound = true;
  bool mascot = true;
  String theme = 'light';

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.fredoka(fontWeight: FontWeight.w500, fontSize: 14)),
          backgroundColor: const Color(0xFF1B2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
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
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 17, color: const Color(0xFF1B2430)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _sectionLabel('\$ обучение'),
          _card([
            _row(
              title: 'Цель на день',
              subtitle: '3 урока · ~15 минут',
              trailing: _pill('изменить', () => _soon('Выбор цели — в следующем шаге')),
            ),
            _row(
              title: 'Напоминание',
              subtitle: 'каждый день в 20:00',
              trailing: _Toggle(value: remind, onChanged: (v) => setState(() => remind = v)),
            ),
            _row(
              title: 'Защита streak',
              subtitle: 'пропущенный день не сбросит 🔥',
              trailing: _Toggle(value: shield, onChanged: (v) => setState(() => shield = v)),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionLabel('\$ интерфейс'),
          _card([
            _themeRow(),
            _row(
              title: 'Звуки',
              trailing: _Toggle(value: sound, onChanged: (v) => setState(() => sound = v)),
            ),
            _row(
              title: 'Анимации Kernel',
              subtitle: 'маскот реагирует на ответы',
              trailing: _Toggle(value: mascot, onChanged: (v) => setState(() => mascot = v)),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionLabel('\$ аккаунт'),
          _card([
            _row(
              title: 'Почта',
              trailing: Text(
                'не привязана',
                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF5C6B73)),
              ),
              onTap: () => _soon('Вход в аккаунт появится позже'),
            ),
            _row(
              title: 'Выйти',
              trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC2CDCD)),
              onTap: () => _soon('Вход в аккаунт появится позже'),
            ),
          ]),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _soon('Удаление аккаунта появится позже'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Удалить аккаунт',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 13.5, color: const Color(0xFFFF4B4B)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'kernelly 1.0.0 · build 1',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF9AAAAA)),
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
        style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF00A896)),
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
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1B2430)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF5C6B73)),
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
        decoration: BoxDecoration(
          color: const Color(0xFFE6F8F6),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          text,
          style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF00A896)),
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
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1B2430)),
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
      onTap: () => setState(() => theme = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F8F6) : const Color(0xFFF2F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
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