import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/primary_button.dart';

const _avatars = [
  ('terminal', Icons.terminal, Color(0xFF00C9B7), Color(0xFFE0F7F4)),
  ('code', Icons.code, Color(0xFF00A896), Color(0xFFE0F7F4)),
  ('rocket', Icons.rocket_launch, Color(0xFFFF9500), Color(0xFFFFF1DC)),
  ('flame', Icons.local_fire_department, Color(0xFFFF9500), Color(0xFFFFF1DC)),
  ('bolt', Icons.bolt, Color(0xFFCC9327), Color(0xFFFFF3D6)),
  ('star', Icons.star, Color(0xFFCC9327), Color(0xFFFFF3D6)),
  ('shield', Icons.shield, Color(0xFF58CC02), Color(0xFFEAF9DC)),
  ('bug', Icons.bug_report, Color(0xFFFF4B4B), Color(0xFFFFEAEA)),
];

/// Показывается один раз сразу после первого входа через Google (пока
/// avatar == null на бэкенде) — просит придумать имя и выбрать аватарку.
/// Можно пропустить: тогда профиль просто останется без имени до
/// следующего раза, когда пользователь зайдёт сюда сам.
class ProfileSetupScreen extends StatefulWidget {
  final int userId;
  final String? suggestedName;

  const ProfileSetupScreen({super.key, required this.userId, this.suggestedName});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _nameController;
  String _selectedAvatar = _avatars.first.$1;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.suggestedName ?? '');
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
      await updateProfile(widget.userId, name, _selectedAvatar);
      if (mounted) Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text('Пропустить', style: TextStyle(fontFamily: 'Fredoka', color: const Color(0xFF9AAAAA))),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Как тебя зовут?',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 22, color: const Color(0xFF1B2430)),
              ),
              const SizedBox(height: 6),
              Text(
                'Имя и аватарку увидят другие в рейтинге и ленте',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: const Color(0xFF5C6B73)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                maxLength: 24,
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, color: const Color(0xFF1B2430)),
                decoration: InputDecoration(
                  hintText: 'Никнейм',
                  errorText: _error,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFDCE8E7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFDCE8E7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF00C9B7), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Выбери аватарку',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1B2430)),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [for (final avatar in _avatars) _avatarOption(avatar)],
              ),
              const SizedBox(height: 28),
              PrimaryButton(text: _saving ? 'Сохраняем…' : 'Продолжить', enabled: !_saving, onPressed: _save),
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
          border: Border.all(color: selected ? fg : Colors.transparent, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 26, color: fg),
      ),
    );
  }
}
