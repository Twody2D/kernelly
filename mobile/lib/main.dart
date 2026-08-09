import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/services/notifications_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/theme_controller.dart';

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
  await themeController.loadFromPrefs();

  // если пропущенный тумблер уже был включён (переустановка приложения —
  // локальные запланированные уведомления Android не переживают её), нужно
  // заново поставить напоминание в систему
  if (prefs.getBool(PrefKeys.remind) ?? true) {
    await NotificationsService.instance.scheduleDaily();
  }

  runApp(KernellyApp(onboardingDone: onboardingDone));
}

class KernellyApp extends StatelessWidget {
  final bool onboardingDone;

  const KernellyApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Kernelly',
          scrollBehavior: _AppScrollBehavior(),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: onboardingDone ? const MainShell() : const OnboardingScreen(),
        );
      },
    );
  }
}
