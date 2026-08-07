import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/screens/profile_setup_screen.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/primary_button.dart';

/// Содержимое заглушки «зарегистрируйся, чтобы разблокировать» — маскот,
/// заголовок/подзаголовок и кнопка входа через Google. Без Scaffold — годится
/// и для полноэкранной навигации, и для встраивания прямо в экран профиля.
///
/// [onSignedIn] вызывается после успешного входа — экран сам не перезагружает
/// данные и не уходит назад, это решает вызывающий код.
///
/// Появление анимировано по стадиям (маскот → заголовок → подзаголовок →
/// кнопка), в духе экрана завершения урока/раздела.
class RegisterPromptContent extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSignedIn;

  const RegisterPromptContent({super.key, required this.title, required this.subtitle, this.onSignedIn});

  @override
  State<RegisterPromptContent> createState() => _RegisterPromptContentState();
}

const _benefits = [
  (Icons.local_fire_department, Color(0xFFFF9500), Color(0xFFFFF1DC), 'Прогресс и стрик сохранятся при смене устройства'),
  (Icons.lock_open_rounded, Color(0xFF00A896), Color(0xFFE0F7F4), 'Откроются все курсы'),
  (Icons.emoji_events_outlined, Color(0xFFCC9327), Color(0xFFFFF3D6), 'Достижения останутся с тобой навсегда'),
];

class _RegisterPromptContentState extends State<RegisterPromptContent> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;

  late final Animation<double> _mascotScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _benefitsFade;
  late final Animation<Offset> _benefitsSlide;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

    _mascotScale = CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack));

    const titleInterval = Interval(0.22, 0.62, curve: Curves.easeOut);
    _titleFade = CurvedAnimation(parent: _introController, curve: titleInterval);
    _titleSlide = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _introController, curve: titleInterval));

    const subtitleInterval = Interval(0.32, 0.72, curve: Curves.easeOut);
    _subtitleFade = CurvedAnimation(parent: _introController, curve: subtitleInterval);
    _subtitleSlide = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _introController, curve: subtitleInterval));

    const benefitsInterval = Interval(0.42, 0.85, curve: Curves.easeOut);
    _benefitsFade = CurvedAnimation(parent: _introController, curve: benefitsInterval);
    _benefitsSlide = Tween(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _introController, curve: benefitsInterval));

    _buttonFade = CurvedAnimation(parent: _introController, curve: const Interval(0.55, 1.0, curve: Curves.easeOut));
    _buttonScale = CurvedAnimation(parent: _introController, curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack));

    _introController.forward();

    // лёгкое «дыхание» кнопки — приглашает нажать, пока пользователь смотрит на экран
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _signingIn = false;

  Future<void> _handleSignIn() async {
    setState(() => _signingIn = true);
    try {
      final result = await signInWithGoogle();
      if (result.user['avatar'] == null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(userId: result.user['id'] as int, suggestedName: result.suggestedName),
          ),
        );
      }
      widget.onSignedIn?.call();
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        _showError('Не удалось войти через Google');
      }
    } catch (e) {
      if (mounted) _showError('Не удалось войти через Google');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(scale: _mascotScale, child: const AnimatedMascot(size: 190)),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _titleFade,
            child: SlideTransition(
              position: _titleSlide,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 22, color: const Color(0xFF1B2430)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FadeTransition(
            opacity: _subtitleFade,
            child: SlideTransition(
              position: _subtitleSlide,
              child: Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4, color: const Color(0xFF5C6B73)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _benefitsFade,
            child: SlideTransition(
              position: _benefitsSlide,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _benefits.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: Color(0xFFEFF4F4)),
                      _benefitRow(_benefits[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _buttonFade,
            child: ScaleTransition(
              scale: _buttonScale,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = 1.0 + Curves.easeInOut.transform(_pulseController.value) * 0.03;
                  return Transform.scale(scale: pulse, child: child);
                },
                child: PrimaryButton(
                  text: _signingIn ? 'Входим…' : 'Войти через Google',
                  enabled: !_signingIn,
                  onPressed: _handleSignIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow((IconData, Color, Color, String) benefit) {
    final (icon, color, bg, text) = benefit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: const Color(0xFF1B2430)),
            ),
          ),
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
        child: Center(
          child: RegisterPromptContent(
            title: title,
            subtitle: subtitle,
            onSignedIn: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
