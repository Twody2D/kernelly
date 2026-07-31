import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/primary_button.dart';

class SectionCompleteScreen extends StatelessWidget {
  final String sectionTitle;
  final int xpEarned;
  final int accuracyPercent;
  final VoidCallback onContinue;

  const SectionCompleteScreen({
    super.key,
    required this.sectionTitle,
    required this.xpEarned,
    required this.accuracyPercent,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Mascot(emotion: MascotEmotion.surprised, size: 140),
              const SizedBox(height: 16),
              Text(
                '$sectionTitle пройдена!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20, color: const Color(0xFF1B2430)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.star_rounded, color: Color(0xFFFFD98A), size: 22),
                    )),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFEAF9DC), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('XP', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF4C8A1F))),
                    Text('+$xpEarned', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 22, color: const Color(0xFF2E6E00))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1EAEA), width: 2),
                ),
                child: Column(
                  children: [
                    Text('ТОЧНОСТЬ', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF5C6B73))),
                    Text('$accuracyPercent%', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 22, color: const Color(0xFF1B2430))),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(text: 'Продолжить', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}