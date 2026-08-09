import 'package:flutter/material.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/settings_profile_screen.dart';
import 'package:mobile/screens/settings_notifications_screen.dart';
import 'package:mobile/screens/settings_courses_screen.dart';
import 'package:mobile/screens/settings_privacy_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/settings_widgets.dart';

/// Хаб настроек «Параметры» — раньше был одним длинным экраном со всеми
/// переключателями подряд, теперь просто список разделов: Профиль,
/// Уведомления, Курсы, Конфиденциальность, плюс отдельно Выйти.
class SettingsScreen extends StatefulWidget {
  final bool isGuest;
  final String? email;
  final String? username;
  final String? avatar;
  final VoidCallback? onProfileChanged;

  const SettingsScreen({
    super.key,
    required this.isGuest,
    this.email,
    this.username,
    this.avatar,
    this.onProfileChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool signingOut = false;

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          backgroundColor: const Color(0xFF1B2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _openProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsProfileScreen(
          username: widget.username,
          avatar: widget.avatar,
          email: widget.email,
          isGuest: widget.isGuest,
        ),
      ),
    );
    if (changed == true) widget.onProfileChanged?.call();
  }

  Future<void> _confirmSignOut() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Выйти из аккаунта?',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Прогресс останется в аккаунте. Чтобы продолжить с ним на этом устройстве, нужно будет войти снова.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Отмена',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Выйти',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFFFF4B4B),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => signingOut = true);
    try {
      await signOutAndResetToGuest();
    } catch (e) {
      if (mounted) {
        setState(() => signingOut = false);
        _soon('Не удалось выйти, попробуй ещё раз');
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Параметры',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          SettingsCard([
            SettingsRow(
              title: 'Профиль',
              subtitle: 'никнейм и аватарка',
              trailing: Icon(Icons.chevron_right, size: 20, color: colors.locked),
              onTap: _openProfile,
            ),
            SettingsRow(
              title: 'Уведомления',
              subtitle: 'напоминание и защита streak',
              trailing: Icon(Icons.chevron_right, size: 20, color: colors.locked),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsNotificationsScreen(),
                ),
              ),
            ),
            SettingsRow(
              title: 'Курсы',
              subtitle: 'цель на день, звук, тема',
              trailing: Icon(Icons.chevron_right, size: 20, color: colors.locked),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsCoursesScreen(),
                ),
              ),
            ),
            SettingsRow(
              title: 'Конфиденциальность',
              subtitle: 'почта, удаление аккаунта',
              trailing: Icon(Icons.chevron_right, size: 20, color: colors.locked),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPrivacyScreen(
                    isGuest: widget.isGuest,
                    email: widget.email,
                    onSignIn: () => _soon('Вход в аккаунт появится позже'),
                    onDeleteAccount: () =>
                        _soon('Удаление аккаунта появится позже'),
                  ),
                ),
              ),
            ),
          ]),
          if (!widget.isGuest) ...[
            const SizedBox(height: 18),
            SettingsCard([
              SettingsRow(
                title: 'Выйти',
                titleColor: colors.error,
                trailing: signingOut
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.locked,
                        ),
                      )
                    : Icon(Icons.logout_rounded, size: 18, color: colors.error),
                onTap: signingOut ? null : _confirmSignOut,
              ),
            ]),
          ],
          const SizedBox(height: 20),
          Text(
            'kernelly 1.0.0 · build 1',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
