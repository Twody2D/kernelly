import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const OptionCard({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1EAEA), width: 2),
          ),
          child: Row(
            children: [
              Text(
                '> ',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00A896),
                ),
              ),
              Text(text, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}