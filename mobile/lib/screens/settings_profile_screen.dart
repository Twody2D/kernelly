import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/avatars.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/primary_button.dart';

/// Редактирование имени и аватарки — тот же набор данных, что и на
/// первичной настройке профиля (profile_setup_screen), но как экран
/// настроек: с текущими значениями и без принудительного шага.
class SettingsProfileScreen extends StatefulWidget {
  final String? username;
  final String? avatar;
  final String? email;
  final bool isGuest;

  const SettingsProfileScreen({
    super.key,
    required this.username,
    required this.avatar,
    required this.email,
    required this.isGuest,
  });

  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  late final TextEditingController _nameController;
  late String _selectedAvatar;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.username ?? '');
    _selectedAvatar = avatarByCode(widget.avatar).$1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введи имя');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await updateProfile(currentUserId, name, _selectedAvatar);
      if (mounted) Navigator.pop(context, true);
    } on UsernameTakenException {
      setState(() {
        _saving = false;
        _error = 'Это имя уже занято, придумай другое';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Не удалось сохранить, попробуй ещё раз';
      });
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
          'Профиль',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Никнейм',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                maxLength: 24,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Никнейм',
                  errorText: _error,
                  filled: true,
                  fillColor: colors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Аватарка',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  for (final avatar in avatarCatalog) _avatarOption(avatar),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Почта',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.isGuest
                                ? 'не привязана'
                                : (widget.email ?? 'не привязана'),
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: _saving ? 'Сохраняем…' : 'Сохранить',
                enabled: !_saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarOption((String, IconData, Color, Color) avatar) {
    final (code, icon, fg, bg) = avatar;
    final selected = _selectedAvatar == code;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _selectedAvatar = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? fg : Colors.transparent,
            width: 2.5,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 26, color: fg),
      ),
    );
  }
}
