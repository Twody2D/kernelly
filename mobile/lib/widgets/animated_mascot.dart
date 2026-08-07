import 'package:flutter/material.dart';
import 'package:mobile/widgets/mascot.dart';

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

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
      ..repeat(reverse: true);
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _ringController.dispose();
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
            animation: _floatController,
            builder: (context, child) {
              final dy = Curves.easeInOut.transform(_floatController.value) * -8;
              return Transform.translate(offset: Offset(0, dy), child: child);
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
