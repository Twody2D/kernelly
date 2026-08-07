import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_config.dart';
import 'package:mobile/services/user_prefs.dart';

/// Web-клиент из Google Cloud Console — на Android/iOS передаётся как
/// serverClientId, чтобы получить id-токен, проверяемый бэкендом единообразно
/// на всех платформах. Не секрет, безопасно хранить в коде.
const _webClientId = '969523130284-iu9vl4pc3r3rv2n3gcprn7uf2uskgc6t.apps.googleusercontent.com';

final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
bool _initialized = false;

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  await _googleSignIn.initialize(serverClientId: _webClientId);
  _initialized = true;
}

/// Результат успешного входа: данные пользователя с бэкенда (авторитетные —
/// в них видно, заполнен ли профиль) и имя из Google-аккаунта как подсказка
/// для поля имени на экране настройки профиля.
class GoogleSignInResult {
  final Map<String, dynamic> user;
  final String? suggestedName;

  GoogleSignInResult({required this.user, required this.suggestedName});
}

/// Запускает интерактивный вход через Google, шлёт id-токен на бэкенд вместе
/// с device_token этого устройства и обновляет [currentUserId] на аккаунт,
/// с которым теперь связано устройство (гость мог слиться в уже существующий
/// аккаунт, если вход не первый).
///
/// Бросает исключение при отмене входа или ошибке — вызывающий код сам решает,
/// как это показать пользователю.
Future<GoogleSignInResult> signInWithGoogle() async {
  await _ensureInitialized();

  final account = await _googleSignIn.authenticate();
  final idToken = account.authentication.idToken;
  if (idToken == null) {
    throw Exception('Google не вернул id-токен');
  }

  final response = await http.post(
    Uri.parse('$apiBaseUrl/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id_token': idToken, 'device_token': currentDeviceToken}),
  );

  if (response.statusCode != 200) {
    throw Exception('Сервер отклонил вход через Google');
  }

  final user = jsonDecode(utf8.decode(response.bodyBytes));
  currentUserId = user['id'] as int;
  return GoogleSignInResult(user: user, suggestedName: account.displayName);
}
