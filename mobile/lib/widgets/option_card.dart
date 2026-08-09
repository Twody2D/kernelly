import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';

enum OptionState { none, selected, correct, incorrect }

class OptionCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final OptionState state;
  final bool locked;

  const OptionCard({
    super.key,
    required this.text,
    required this.onTap,
    this.state = OptionState.none,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color borderColor = colors.border;
    Color backgroundColor = colors.card;
    Color promptColor = colors.accentDark;
    Color textColor = colors.textPrimary;

    if (state == OptionState.selected) {
      borderColor = colors.accent;
      backgroundColor = colors.accentBg;
    } else if (state == OptionState.correct) {
      borderColor = colors.success;
      backgroundColor = colors.successBg;
      promptColor = colors.success;
    } else if (state == OptionState.incorrect) {
      borderColor = colors.error;
      backgroundColor = colors.errorBg;
      promptColor = colors.error;
    } else if (locked) {
      borderColor = colors.divider;
      promptColor = colors.locked;
      textColor = colors.locked;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '> ',
                style: TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w600, color: promptColor),
              ),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w500, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
