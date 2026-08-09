import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';

/// Общие строительные блоки для экранов настроек (хаб + Профиль, Уведомления,
/// Курсы, Конфиденциальность) — раньше жили как приватные методы в одном
/// большом settings_screen.dart, теперь общий набор виджетов.

class SettingsSectionLabel extends StatelessWidget {
  final String text;

  const SettingsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10.5,
          color: context.colors.accentDark,
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final List<Widget> rows;

  const SettingsCard(this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Divider(height: 1.5, thickness: 1.5, color: colors.divider));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                      color: titleColor ?? colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
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
}

class SettingsPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const SettingsPill({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.accentBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.accentDark,
          ),
        ),
      ),
    );
  }
}

class SettingsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? colors.accent : colors.locked,
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
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
