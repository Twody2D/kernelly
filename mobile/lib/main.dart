import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/services/user_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool(PrefKeys.onboardingDone) ?? false;

  runApp(KernellyApp(onboardingDone: onboardingDone));
}

class KernellyApp extends StatelessWidget {
  final bool onboardingDone;

  const KernellyApp({super.key, required this.onboardingDone});

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
      home: onboardingDone ? const MainShell() : const OnboardingScreen(),
    );
  }
}