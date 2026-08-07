import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/services/user_prefs.dart';

/// На Android 12+ Flutter по умолчанию растягивает контент при овер-скролле
/// (StretchingOverscrollIndicator) — визуально ломает жёстко заданные по
/// макету экраны. Возвращаем классический «glow»-индикатор.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: const Color(0xFF00C9B7),
      // Если контент и так помещается на экран (нечего скроллить), не
      // показываем индикатор — иначе он "загорается" от любого свайпа.
      notificationPredicate: (notification) =>
          notification.metrics.maxScrollExtent > 0 && defaultScrollNotificationPredicate(notification),
      child: child,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool(PrefKeys.onboardingDone) ?? false;

  await ensureUserId();

  runApp(KernellyApp(onboardingDone: onboardingDone));
}

class KernellyApp extends StatelessWidget {
  final bool onboardingDone;

  const KernellyApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kernelly',
      scrollBehavior: _AppScrollBehavior(),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F9F9),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C9B7), primary: const Color(0xFF00C9B7)),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 21,
            color: const Color(0xFF1B2430),
          ),
          bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C9B7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
      home: onboardingDone ? const MainShell() : const OnboardingScreen(),
    );
  }
}
