import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = enabled ? const Color(0xFF00C9B7) : const Color(0xFFE7EEEE);
    final Color textColor = enabled ? Colors.white : const Color(0xFFB6C2C2);
    final Color shadowColor = enabled ? const Color(0xFF00A896) : const Color(0xFFD3DEDE);

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
            boxShadow: [
              BoxShadow(color: shadowColor, offset: const Offset(0, 4), blurRadius: 0),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
          ),
        ),
      ),
    );
  }
}