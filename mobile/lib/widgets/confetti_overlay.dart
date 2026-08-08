import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Лёгкий самодельный конфетти-эффект без внешних зависимостей: прямоугольные
/// частицы падают сверху и вращаются, разгон/цвета зафиксированы один раз
/// при инициализации, чтобы не пересчитывать их каждый кадр.
class ConfettiOverlay extends StatefulWidget {
  final int particleCount;

  const ConfettiOverlay({super.key, this.particleCount = 60});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  static const _colors = [
    Color(0xFF00C9B7),
    Color(0xFFFFD98A),
    Color(0xFFFF9500),
    Color(0xFF58CC02),
    Color(0xFFFF4B4B),
    Color(0xFF8FA0AB),
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _pieces = List.generate(widget.particleCount, (i) {
      return _ConfettiPiece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        fallSpeed: 0.7 + random.nextDouble() * 0.6,
        drift: (random.nextDouble() - 0.5) * 0.4,
        rotationSpeed: (random.nextDouble() - 0.5) * 8,
        size: 6 + random.nextDouble() * 6,
        color: _colors[random.nextInt(_colors.length)],
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_pieces, _controller.value),
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double delay;
  final double fallSpeed;
  final double drift;
  final double rotationSpeed;
  final double size;
  final Color color;

  _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.fallSpeed,
    required this.drift,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double t;

  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final local = ((t - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final fallY = local * piece.fallSpeed * size.height * 1.15;
      final dx = piece.x * size.width + piece.drift * size.width * local;
      final dy = -size.height * 0.1 + fallY;
      if (dy > size.height) continue;

      final opacity = local > 0.75 ? (1 - local) / 0.25 : 1.0;
      final paint = Paint()
        ..color = piece.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(local * piece.rotationSpeed * math.pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.42,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
