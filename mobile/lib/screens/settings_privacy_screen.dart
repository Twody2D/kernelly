import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/device_phone.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/settings_widgets.dart';

/// Всё, что касается данных аккаунта: почта, телефон и удаление аккаунта. Сам
/// вход и выход остались в хабе настроек — здесь только то, что относится к
/// приватности и хранению данных.
class SettingsPrivacyScreen extends StatefulWidget {
  final bool isGuest;
  final String? email;
  final String? phone;
  final VoidCallback onSignIn;
  final VoidCallback onDeleteAccount;

  const SettingsPrivacyScreen({
    super.key,
    required this.isGuest,
    required this.email,
    required this.phone,
    required this.onSignIn,
    required this.onDeleteAccount,
  });

  @override
  State<SettingsPrivacyScreen> createState() => _SettingsPrivacyScreenState();
}

class _SettingsPrivacyScreenState extends State<SettingsPrivacyScreen> {
  // Приходит от родителя вместе с остальным профилем (см. profile_screen.dart) —
  // отдельный запрос при каждом открытии экрана давал заметное мигание
  // "…" → значение, как когда-то было с названием курса.
  late String? _phone = widget.phone;

  Future<void> _editPhone() async {
    // Если номер ещё не привязан, пробуем сразу подтянуть его у системы —
    // работает только на Android и не всегда (см. device_phone.dart), поэтому
    // это лишь предзаполнение поля, а не замена ручного ввода: пользователь
    // всё равно видит и может поправить значение перед сохранением.
    var initial = _phone;
    if (initial == null || initial.isEmpty) {
      initial = await tryGetDevicePhoneNumber();
    }
    if (!mounted) return;
    final controller = TextEditingController(text: initial ?? '');
    String? error;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool saving = false;

            Future<void> save() async {
              final value = controller.text.trim();
              setSheetState(() {
                saving = true;
                error = null;
              });
              try {
                await updatePhone(currentUserId, value.isEmpty ? null : value);
                if (context.mounted) Navigator.pop(context, true);
              } on PhoneTakenException {
                setSheetState(() {
                  saving = false;
                  error = 'Этот номер уже привязан к другому аккаунту';
                });
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  error = 'Не удалось сохранить, попробуй ещё раз';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Номер телефона',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF1B2430),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Необязательно, нужен только для поиска друзей по контактам',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: const Color(0xFF5C6B73),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        color: const Color(0xFF1B2430),
                      ),
                      decoration: InputDecoration(
                        hintText: '+7 900 000-00-00',
                        errorText: error,
                        filled: true,
                        fillColor: const Color(0xFFF6F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9B7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          saving ? 'Сохраняем…' : 'Сохранить',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      final value = controller.text.trim();
      if (!mounted) return;
      setState(() => _phone = value.isEmpty ? null : value);
    }
  }

  Future<void> _signOutOtherDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти со всех устройств?'),
        content: const Text(
          'Аккаунт останется тут, но на всех остальных устройствах понадобится войти заново. '
          'Используй, если подозреваешь, что доступ к аккаунту мог получить кто-то ещё.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Выйти')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await rotateDeviceToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Готово, остальные устройства вышли из аккаунта')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось выполнить, попробуй ещё раз')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          'Конфиденциальность',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: colors.textPrimary,
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
                widget.isGuest ? 'не привязана' : (widget.email ?? 'не привязана'),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
              onTap: widget.isGuest ? widget.onSignIn : null,
            ),
            SettingsRow(
              title: 'Телефон',
              subtitle: 'необязательно, нужен только для поиска друзей по контактам',
              trailing: Text(
                _phone ?? 'не привязан',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: const Color(0xFF5C6B73),
                ),
              ),
              onTap: _editPhone,
            ),
          ]),
          if (!widget.isGuest) ...[
            const SizedBox(height: 18),
            SettingsCard([
              SettingsRow(
                title: 'Выйти со всех устройств',
                subtitle: 'если подозреваешь, что доступ к аккаунту мог получить кто-то ещё',
                trailing: Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
                onTap: _signOutOtherDevices,
              ),
            ]),
          ],
          const SizedBox(height: 18),
          Text(
            'Прогресс хранится на сервере и привязан к аккаунту (или к устройству, пока ты гость). Удаление аккаунта сотрёт весь прогресс без возможности восстановить.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: widget.onDeleteAccount,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.errorBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Удалить аккаунт',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: colors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
