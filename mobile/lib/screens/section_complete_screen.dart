import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/soft_star.dart';

class SectionCompleteScreen extends StatelessWidget {
  final String sectionTitle;
  final int xpEarned;
  final int accuracyPercent;
  final Duration elapsed;
  final int streak;
  final VoidCallback onContinue;
  final VoidCallback onRepeat;

  const SectionCompleteScreen({
    super.key,
    required this.sectionTitle,
    required this.xpEarned,
    required this.accuracyPercent,
    required this.elapsed,
    required this.streak,
    required this.onContinue,
    required this.onRepeat,
  });

  String get _formattedTime {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x2400C9B7), Color(0x0000C9B7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF5C6B73)),
                        onPressed: onContinue,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Text('$streak', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFFFF9500))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const AnimatedMascot(emotion: MascotEmotion.surprised, size: 130),
                        Positioned(
                          left: 10,
                          top: 26,
                          child: Transform.rotate(
                            angle: -14 * 3.1415926535 / 180,
                            child: Text('</>',
                                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00C9B7), fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                        ),
                        const Positioned(
                          right: 8,
                          top: 52,
                          child: Text('✨', style: TextStyle(fontSize: 15)),
                        ),
                        Positioned(
                          right: 26,
                          bottom: 18,
                          child: Transform.rotate(
                            angle: 12 * 3.1415926535 / 180,
                            child: Text('\$',
                                style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFFD98A), fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$ раздел 1 / 4 · завершён',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF00A896)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$sectionTitle\nпройдена!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 26, height: 1.15, color: const Color(0xFF1B2430)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: SoftStar(size: 30),
                        )),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _statCard('XP', '+$xpEarned', highlight: true)),
                      const SizedBox(width: 9),
                      Expanded(child: _statCard('ТОЧНОСТЬ', '$accuracyPercent%')),
                      const SizedBox(width: 9),
                      Expanded(child: _statCard('ВРЕМЯ', _formattedTime)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF29DFCB), Color(0xFF00C9B7)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [BoxShadow(color: Color(0xFF00A896), offset: Offset(0, 3))],
                              ),
                              alignment: Alignment.center,
                              child: Text('>_', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                            Positioned(bottom: -9, left: 14, child: Container(width: 4, height: 9, decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(2)))),
                            Positioned(bottom: -9, right: 14, child: Container(width: 4, height: 9, decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(2)))),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('РАЗБЛОКИРОВАНО', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF9AAAAA))),
                              Text('Раздел 2 · Права доступа',
                                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14.5, color: const Color(0xFF1B2430))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C9B7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0xFF00A896), offset: Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: Text('Продолжить', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onRepeat,
                    child: Text('Повторить раздел',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF5C6B73))),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFEAF9DC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight ? null : Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: highlight ? const Color(0xFF4B8A18) : const Color(0xFF9AAAAA))),
          const SizedBox(height: 5),
          Text(value, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 18, color: highlight ? const Color(0xFF3F9200) : const Color(0xFF1B2430))),
        ],
      ),
    );
  }
}