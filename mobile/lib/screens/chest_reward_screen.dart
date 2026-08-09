import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/widgets/confetti_overlay.dart';
import 'package:mobile/widgets/primary_button.dart';

const _chestReasonTitles = {
  'lesson_gold': 'УРОК НА ЗОЛОТО',
  'course_complete': 'КУРС ПРОЙДЕН',
  'daily_login': 'ЕЖЕДНЕВНЫЙ ВХОД',
  'achievement': 'ДОСТИЖЕНИЕ',
  'league': 'МЕСТО В ТОПЕ',
};

/// Показывает сундуки с уже известной суммой (золото за урок, курс, вход) —
/// одни за другим, полноэкранно: за один урок сундуков может выпасть сразу
/// несколько (золото + курс пройден разом).
Future<void> showChestRewards(
  BuildContext context,
  List<Map<String, dynamic>> chests,
) async {
  for (final chest in chests) {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChestRewardScreen(
          reason: chest['reason'] as String,
          amount: chest['amount'] as int,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Сундук за достижение — сумма неизвестна заранее, а начисляется только
/// когда пользователь сам тапнет по сундуку (см. onOpen ниже). Возвращает
/// полученное количество ядер, либо null, если экран закрыли не открывая.
Future<int?> showClaimableChestReward(
  BuildContext context, {
  required String reason,
  required Future<int> Function() onOpen,
}) {
  return Navigator.push<int>(
    context,
    MaterialPageRoute(
      builder: (_) => ChestRewardScreen(reason: reason, onOpen: onOpen),
      fullscreenDialog: true,
    ),
  );
}

enum _ChestState { closed, claiming, opening, revealed }

class ChestRewardScreen extends StatefulWidget {
  final String reason;

  /// Сумма уже известна (сундуки за урок/курс/вход — сервер начислил их
  /// заранее, тут только визуальный момент открытия).
  final int? amount;

  /// Сумма определяется только сейчас — вызывается по тапу на сундук, и
  /// именно тогда ядра реально начисляются на сервере (сундук за достижение).
  final Future<int> Function()? onOpen;

  const ChestRewardScreen({super.key, required this.reason, this.amount, this.onOpen})
      : assert(amount != null || onOpen != null, 'Нужен либо amount, либо onOpen');

  @override
  State<ChestRewardScreen> createState() => _ChestRewardScreenState();
}

class _ChestRewardScreenState extends State<ChestRewardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _openController;
  late final Animation<double> _popScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  _ChestState _state = _ChestState.closed;
  int? _amount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _popScale = TweenSequence([
      TweenSequenceItem(
        weight: 40,
        tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
      ),
      TweenSequenceItem(
        weight: 60,
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
      ),
    ]).animate(_openController);
    const revealInterval = Interval(0.3, 1.0, curve: Curves.easeOut);
    _fade = CurvedAnimation(parent: _openController, curve: revealInterval);
    _slide = Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_state != _ChestState.closed) return;

    if (widget.onOpen != null) {
      setState(() {
        _state = _ChestState.claiming;
        _error = null;
      });
      try {
        _amount = await widget.onOpen!();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _state = _ChestState.closed;
          _error = 'Не удалось открыть, попробуй ещё раз';
        });
        return;
      }
    } else {
      _amount = widget.amount;
    }

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _state = _ChestState.opening);
    await _openController.forward();
    if (!mounted) return;
    setState(() => _state = _ChestState.revealed);
  }

  Widget _chestVisual() {
    if (_state == _ChestState.claiming) {
      return const SizedBox(
        width: 96,
        height: 96,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }
    return Text(
      _state == _ChestState.revealed ? '🎁' : '📦',
      style: const TextStyle(fontSize: 96),
    );
  }

  Widget _closedHint() {
    if (_state != _ChestState.closed) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          'Нажми, чтобы открыть',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: const Color(0xFF5C6B73),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: const Color(0xFFFF4B4B),
            ),
          ),
        ],
      ],
    );
  }

  Widget _revealedContent() {
    if (_state != _ChestState.revealed) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 8),
        FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                Text(
                  '+$_amount ядер',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 26,
                    color: const Color(0xFF1B2430),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Потрать их в магазине на заморозку streak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    height: 1.5,
                    color: const Color(0xFF5C6B73),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        FadeTransition(
          opacity: _fade,
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Круто!',
              onPressed: () => Navigator.pop(context, _amount),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _chestReasonTitles[widget.reason] ?? 'СУНДУК';
    final revealed = _state == _ChestState.revealed;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: Stack(
        children: [
          if (revealed) const Positioned.fill(child: ConfettiOverlay()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 1.2,
                        color: const Color(0xFF00A896),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _handleTap,
                      child: AnimatedBuilder(
                        animation: _openController,
                        builder: (context, child) => Transform.scale(
                          scale: _state == _ChestState.closed ? 1.0 : _popScale.value,
                          child: child,
                        ),
                        child: _chestVisual(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _closedHint(),
                    _revealedContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
