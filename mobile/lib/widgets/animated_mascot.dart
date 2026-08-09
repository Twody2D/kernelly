import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/widgets/mascot.dart';

/// Тумблер «Анимации Kernel» во время урока: включён — обычный [AnimatedMascot],
/// выключен — статичный [Mascot] с теми же параметрами.
Widget lessonMascot({
  required bool animated,
  MascotEmotion emotion = MascotEmotion.happy,
  double size = 140,
}) {
  return animated
      ? AnimatedMascot(emotion: emotion, size: size)
      : Mascot(emotion: emotion, size: size);
}

class AnimatedMascot extends StatefulWidget {
  final MascotEmotion emotion;
  final double size;

  const AnimatedMascot({super.key, this.emotion = MascotEmotion.happy, this.size = 140});

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _ringController;
  late AnimationController _swayController;
  late AnimationController _bounceController;
  Timer? _bounceTimer;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
      ..repeat(reverse: true);
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _swayController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600))
      ..repeat(reverse: true);

    // время от времени маскот "подпрыгивает" — оживляет долгий idle-простой,
    // например пока пользователь читает текст на экране
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _bounceTimer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (mounted) _bounceController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _ringController.dispose();
    _swayController.dispose();
    _bounceController.dispose();
    _bounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowSize = widget.size * 1.55;
    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: glowSize,
            height: glowSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF00C9B7).withOpacity(0.22), const Color(0xFF00C9B7).withOpacity(0)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              final curved = Curves.easeInOut.transform(_ringController.value);
              final opacity = 0.15 + curved * 0.65;
              final scale = 1.0 + curved * 0.04;
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: CustomPaint(size: Size(glowSize * 0.72, glowSize * 0.72), painter: _DashedCirclePainter()),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_floatController, _swayController, _bounceController]),
            builder: (context, child) {
              final dy = Curves.easeInOut.transform(_floatController.value) * -8;
              final angle = (Curves.easeInOut.transform(_swayController.value) - 0.5) * 0.08;
              final bounce = sin(Curves.easeOut.transform(_bounceController.value) * pi) * 0.12;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scaleX: 1 - bounce * 0.6,
                    scaleY: 1 + bounce,
                    child: child,
                  ),
                ),
              );
            },
            child: Mascot(emotion: widget.emotion, size: widget.size),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C9B7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    const dashWidth = 5.0;
    const dashGap = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) => false;
}
