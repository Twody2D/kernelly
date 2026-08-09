import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Ежедневное напоминание в 20:00 — тумблер «Напоминание» в настройках.
/// Инициализируется один раз при старте приложения (см. main.dart), после
/// чего settings_notifications_screen.dart дёргает [scheduleDaily]/[cancelDaily]
/// напрямую по изменению тумблера.
class NotificationsService {
  NotificationsService._();
  static final instance = NotificationsService._();

  static const _dailyReminderId = 1;
  static const _channelId = 'daily_reminder';
  static const _channelName = 'Напоминания';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Планирует ежедневное напоминание на 20:00 по локальному времени
  /// устройства — если время уже прошло сегодня, первое сработает завтра.
  Future<void> scheduleDaily() async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Ежедневное напоминание позаниматься',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Не теряй streak 🔥',
      'Пять минут занятий — и день не пропущен',
      _next20h(),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(_dailyReminderId);
  }

  tz.TZDateTime _next20h() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
