import 'package:flutter/material.dart';
import 'package:mobile/widgets/settings_widgets.dart';

/// Всё, что касается данных аккаунта: почта и удаление аккаунта. Сам вход и
/// выход остались в хабе настроек — здесь только то, что относится к
/// приватности и хранению данных.
class SettingsPrivacyScreen extends StatelessWidget {
  final bool isGuest;
  final String? email;
  final VoidCallback onSignIn;
  final VoidCallback onDeleteAccount;

  const SettingsPrivacyScreen({
    super.key,
    required this.isGuest,
    required this.email,
    required this.onSignIn,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
        title: Text(
          'Конфиденциальность',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: const Color(0xFF1B2430),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SettingsCard([
            SettingsRow(
              title: 'Почта',
              trailing: Text(
                isGuest ? 'не привязана' : (email ?? 'не привязана'),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: const Color(0xFF5C6B73),
                ),
              ),
              onTap: isGuest ? onSignIn : null,
            ),
          ]),
          const SizedBox(height: 18),
          Text(
            'Прогресс хранится на сервере и привязан к аккаунту (или к устройству, пока ты гость). Удаление аккаунта сотрёт весь прогресс без возможности восстановить.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.5,
              color: const Color(0xFF5C6B73),
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onDeleteAccount,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Удалить аккаунт',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: const Color(0xFFFF4B4B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
