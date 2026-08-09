import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

const _channel = MethodChannel('com.kernelly.app/phone');

/// Пытается получить номер телефона этого устройства у системы — только
/// Android (line1Number из TelephonyManager) и только с разрешением
/// READ_PHONE_STATE. На iOS такого API вообще нет, а на части
/// Android-прошивок/операторов/eSIM телефон всё равно не отдаёт номер —
/// в обоих случаях возвращаем null, и вызывающий код просто показывает
/// обычное поле для ручного ввода.
Future<String?> tryGetDevicePhoneNumber() async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;

  final status = await Permission.phone.request();
  if (!status.isGranted) return null;

  try {
    final number = await _channel.invokeMethod<String>('getLine1Number');
    return (number == null || number.isEmpty) ? null : number;
  } on PlatformException {
    return null;
  }
}
