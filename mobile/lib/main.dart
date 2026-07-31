import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/course_overview_screen.dart';

void main() {
  runApp(const KernellyApp());
}

class KernellyApp extends StatelessWidget {
  const KernellyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kernelly',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F9F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9B7),
          primary: const Color(0xFF00C9B7),
        ),
        textTheme: TextTheme(
          headlineSmall: GoogleFonts.fredoka(
            fontWeight: FontWeight.w600,
            fontSize: 21,
            color: const Color(0xFF1B2430),
          ),
          bodyMedium: GoogleFonts.inter(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C9B7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
      home: const CourseOverviewScreen(),
    );
  }
}