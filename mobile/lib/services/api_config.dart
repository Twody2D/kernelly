import 'package:flutter/foundation.dart';

/// Адрес бэкенда.
///
/// По умолчанию подбирается под окружение запуска:
/// - веб и десктоп — localhost;
/// - Android-эмулятор — 10.0.2.2, это его алиас для localhost хост-машины.
///
/// Для реального устройства или удалённого сервера адрес задаётся при запуске:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
const _override = String.fromEnvironment('API_BASE_URL');

const _localhost = 'http://127.0.0.1:8000';
const _androidEmulator = 'http://10.0.2.2:8000';

String get apiBaseUrl {
  if (_override.isNotEmpty) return _override;
  if (kIsWeb) return _localhost;
  if (defaultTargetPlatform == TargetPlatform.android) return _androidEmulator;
  return _localhost;
}
