import 'package:flutter/material.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/primary_button.dart';

void _showRegisterComingSoon(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Регистрация скоро',
        style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: const Color(0xFF1B2430)),
      ),
      content: Text(
        'Вход через аккаунт появится в одном из следующих обновлений — тогда прогресс можно будет сохранить и открыть все курсы.',
        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: const Color(0xFF5C6B73)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Понятно', style: TextStyle(fontFamily: 'Fredoka', color: const Color(0xFF00A896))),
        ),
      ],
    ),
  );
}

/// Содержимое заглушки «зарегистрируйся, чтобы разблокировать» — маскот,
/// заголовок/подзаголовок и кнопка регистрации (пока ведёт на заглушку «скоро»,
/// самой регистрации ещё нет). Без Scaffold — годится и для полноэкранной
/// навигации, и для встраивания прямо в экран профиля.
class RegisterPromptContent extends StatelessWidget {
  final String title;
  final String subtitle;

  const RegisterPromptContent({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(color: const Color(0xFFEAF9DC), shape: BoxShape.circle),
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.antiAlias,
            child: const Padding(padding: EdgeInsets.only(bottom: 10), child: Mascot(size: 110)),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 21, color: const Color(0xFF1B2430)),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4, color: const Color(0xFF5C6B73)),
          ),
          const SizedBox(height: 28),
          PrimaryButton(text: 'Зарегистрироваться', onPressed: () => _showRegisterComingSoon(context)),
        ],
      ),
    );
  }
}

/// Полноэкранная версия [RegisterPromptContent] — для навигации из карточки
/// заблокированного курса и подобных мест.
class RegisterPromptScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const RegisterPromptScreen({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(backgroundColor: const Color(0xFFF6F9F9), elevation: 0),
      body: SafeArea(
        child: Center(child: RegisterPromptContent(title: title, subtitle: subtitle)),
      ),
    );
  }
}
