import 'package:flutter/material.dart';

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
    Color borderColor = const Color(0xFFE1EAEA);
    Color backgroundColor = Colors.white;
    Color promptColor = const Color(0xFF00A896);
    Color textColor = const Color(0xFF1B2430);

    if (state == OptionState.selected) {
      borderColor = const Color(0xFF00C9B7);
      backgroundColor = const Color(0xFFE3F8F6);
    } else if (state == OptionState.correct) {
      borderColor = const Color(0xFF58CC02);
      backgroundColor = const Color(0xFFEAF9DC);
      promptColor = const Color(0xFF58CC02);
    } else if (state == OptionState.incorrect) {
      borderColor = const Color(0xFFFF4B4B);
      backgroundColor = const Color(0xFFFFEAEA);
      promptColor = const Color(0xFFFF4B4B);
    } else if (locked) {
      borderColor = const Color(0xFFEDF2F2);
      promptColor = const Color(0xFFC2CDCD);
      textColor = const Color(0xFFC2CDCD);
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
