import 'dart:math' as math;
import 'package:flutter/material.dart';

class SoftStar extends StatelessWidget {
  final double size;
  final Color color;

  const SoftStar({super.key, this.size = 22, this.color = const Color(0xFFFFD98A)});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _SoftStarPainter(color));
  }
}

class _SoftStarPainter extends CustomPainter {
  final Color color;
  _SoftStarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    const points = 5;
    final outerR = size.width / 2;
    final innerR = outerR * 0.42;
    final center = Offset(size.width / 2, size.height / 2);

    final vertices = <Offset>[];
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * 36 - 90) * math.pi / 180;
      vertices.add(Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)));
    }

    path.moveTo((vertices[0].dx + vertices.last.dx) / 2, (vertices[0].dy + vertices.last.dy) / 2);
    for (int i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];
      final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SoftStarPainter oldDelegate) => oldDelegate.color != color;
}
