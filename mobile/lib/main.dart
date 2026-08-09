import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/chest_reward_screen.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/notifications_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/theme_controller.dart';
import 'package:mobile/widgets/mascot.dart';

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

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return _SlowerScrollPhysics(parent: super.getScrollPhysics(context));
  }
}

/// Стандартная скорость скролла ощущалась слишком резкой — что палец
/// проходит по экрану, что бросок (fling) списка, контент улетал заметно
/// дальше, чем на привычных приложениях. Множим и перетаскивание пальцем,
/// и скорость броска на один и тот же коэффициент, а платформенную физику
/// (bounce на iOS / clamping на Android) оставляем как есть через parent —
/// меняется только "скорость", а не характер скролла.
class _SlowerScrollPhysics extends ScrollPhysics {
  const _SlowerScrollPhysics({super.parent});

  static const _factor = 0.4;

  @override
  _SlowerScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SlowerScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset * _factor);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(position, velocity * _factor);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool(PrefKeys.onboardingDone) ?? false;

  // Тема — синхронная, читается локально, поэтому не задерживает первый кадр.
  await themeController.loadFromPrefs();

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
          home: _Startup(onboardingDone: onboardingDone),
        );
      },
    );
  }
}

/// Раньше сетевой запрос за пользователем и системный диалог разрешения на
/// уведомления блокировали первый кадр приложения (runApp вызывался только
/// после обоих) — на слабой сети или медленном холодном старте бэкенда это
/// было заметное чёрное окно перед любой отрисовкой. Теперь runApp происходит
/// сразу, а currentUserId (обязателен для загрузки любого экрана) дожидаемся
/// за лёгким сплэшем; уведомления и вовсе планируются в фоне, не блокируя UI.
class _Startup extends StatefulWidget {
  final bool onboardingDone;

  const _Startup({required this.onboardingDone});

  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await ensureUserId();
    if (mounted) setState(() => _ready = true);

    // если тумблер напоминания уже был включён (переустановка приложения —
    // локальные запланированные уведомления Android не переживают её), нужно
    // заново поставить напоминание в систему; делаем это фоном, не блокируя UI
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PrefKeys.remind) ?? true) {
      final hour = prefs.getInt(PrefKeys.remindHour) ?? 20;
      final minute = prefs.getInt(PrefKeys.remindMinute) ?? 0;
      unawaited(NotificationsService.instance.scheduleDaily(
        time: TimeOfDay(hour: hour, minute: minute),
      ));
    }

    // Только для уже прошедших онбординг — не мешаем сундуком первому
    // знакомству с приложением, за сегодняшний вход это просто не сгорит.
    if (widget.onboardingDone) {
      unawaited(_claimDailyChest());
    }
  }

  Future<void> _claimDailyChest() async {
    try {
      final result = await claimDailyLoginChest(currentUserId);
      if (result['awarded'] != true || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showChestRewards(context, [
          {'reason': 'daily_login', 'amount': result['amount']},
        ]);
      });
    } catch (e) {
      debugPrint('Не удалось получить ежедневный сундук: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _SplashScreen();
    return widget.onboardingDone ? const MainShell() : const OnboardingScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F9F9),
      body: Center(child: Mascot(size: 110)),
    );
  }
}
