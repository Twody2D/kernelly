import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OptionState { none, correct, incorrect }

class OptionCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final OptionState state;

  const OptionCard({
    super.key,
    required this.text,
    required this.onTap,
    this.state = OptionState.none,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFFE1EAEA);
    Color backgroundColor = Colors.white;
    Color promptColor = const Color(0xFF00A896);

    if (state == OptionState.correct) {
      borderColor = const Color(0xFF58CC02);
      backgroundColor = const Color(0xFFEAF9DC);
      promptColor = const Color(0xFF58CC02);
    } else if (state == OptionState.incorrect) {
      borderColor = const Color(0xFFFF4B4B);
      backgroundColor = const Color(0xFFFFEAEA);
      promptColor = const Color(0xFFFF4B4B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: state == OptionState.none ? onTap : null,
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
            children: [
              Text('> ', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, color: promptColor)),
              Text(text, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}