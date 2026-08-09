import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  const PrimaryButton({super.key, required this.text, required this.onPressed, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color bgColor = enabled ? colors.accent : colors.lockedBg;
    final Color textColor = enabled ? Colors.white : colors.locked;
    final Color shadowColor = enabled ? colors.accentDark : colors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 4), blurRadius: 0)],
          ),
          child: Text(
            text,
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
          ),
        ),
      ),
    );
  }
}
