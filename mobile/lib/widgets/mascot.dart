import 'package:flutter/material.dart';

enum MascotEmotion { happy, surprised, sleepy, angry }

class Mascot extends StatelessWidget {
  final MascotEmotion emotion;
  final double size;

  const Mascot({super.key, this.emotion = MascotEmotion.happy, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 170 / 150,
      child: CustomPaint(painter: _MascotPainter(emotion)),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotEmotion emotion;
  _MascotPainter(this.emotion);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 150;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final bool isAngry = emotion == MascotEmotion.angry;
    final Color bodyColor = isAngry ? const Color(0xFFFF4B4B) : const Color(0xFF00C9B7);
    final Color darkColor = isAngry ? const Color(0xFF7A1F1F) : const Color(0xFF0E2A28);
    final Color antennaColor = isAngry ? const Color(0xFFD63838) : const Color(0xFF007A6E);
    final Color dotColor = isAngry
        ? const Color(0xFFFF4B4B)
        : (emotion == MascotEmotion.sleepy ? const Color(0xFFB6C2C2) : const Color(0xFFFF9500));

    // shadow
    canvas.drawOval(
      Rect.fromCenter(center: p(75, 140), width: 48 * s, height: 12 * s),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    // antenna
    canvas.drawLine(
      p(75, 30),
      p(75, 16),
      Paint()
        ..color = antennaColor
        ..strokeWidth = 4 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(p(75, 14), 6 * s, Paint()..color = dotColor);

    // body
    canvas.drawCircle(p(75, 82), 50 * s, Paint()..color = bodyColor);

    // glossy highlight
    canvas.drawOval(
      Rect.fromCenter(center: p(59, 58), width: 32 * s, height: 20 * s),
      Paint()..color = Colors.white.withOpacity(0.25),
    );

    final facePaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * s
      ..strokeCap = StrokeCap.round;

    switch (emotion) {
      case MascotEmotion.happy:
        _drawSmileEye(canvas, p, s, 52, 76, 68, facePaint);
        _drawSmileEye(canvas, p, s, 82, 76, 98, facePaint);
        _drawMouth(canvas, p, s, 63, 100, 75, 107, 87, 100, facePaint);
        break;
      case MascotEmotion.surprised:
        final impulsePaint = Paint()
          ..color = const Color(0xFF8A9797)
          ..strokeWidth = 3 * s
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p(15, 60), p(27, 65), impulsePaint);
        canvas.drawLine(p(15, 82), p(28, 82), impulsePaint);
        canvas.drawLine(p(135, 60), p(123, 65), impulsePaint);
        canvas.drawLine(p(135, 82), p(122, 82), impulsePaint);

        canvas.drawCircle(p(59, 80), 8 * s, Paint()..color = darkColor);
        canvas.drawCircle(p(91, 80), 8 * s, Paint()..color = darkColor);
        canvas.drawCircle(p(56.5, 76.5), 2 * s, Paint()..color = Colors.white);
        canvas.drawCircle(p(88.5, 76.5), 2 * s, Paint()..color = Colors.white);
        canvas.drawOval(Rect.fromCenter(center: p(75, 101), width: 16 * s, height: 20 * s), Paint()..color = darkColor);

        final excl = Paint()..color = const Color(0xFFFF9500);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(p(112, 26).dx, p(112, 26).dy, 5 * s, 15 * s), Radius.circular(2.5 * s)),
          excl,
        );
        canvas.drawCircle(p(114.5, 47), 3 * s, excl);
        break;
      case MascotEmotion.sleepy:
        _drawSmileEye(canvas, p, s, 50, 80, 68, facePaint, flat: true);
        _drawSmileEye(canvas, p, s, 82, 80, 100, facePaint, flat: true);
        break;
      case MascotEmotion.angry:
        canvas.drawLine(p(52, 74), p(68, 80), facePaint);
        canvas.drawLine(p(98, 74), p(82, 80), facePaint);
        canvas.drawCircle(p(61, 88), 5 * s, Paint()..color = darkColor);
        canvas.drawCircle(p(89, 88), 5 * s, Paint()..color = darkColor);
        _drawMouth(canvas, p, s, 63, 104, 75, 98, 87, 104, facePaint);
        break;
    }
  }

  void _drawSmileEye(
    Canvas canvas,
    Offset Function(double, double) p,
    double s,
    double x1,
    double y1,
    double x2,
    Paint paint, {
    bool flat = false,
  }) {
    final path = Path();
    path.moveTo(p(x1, y1).dx, p(x1, y1).dy);
    if (flat) {
      path.quadraticBezierTo(p((x1 + x2) / 2, y1 + 6).dx, p((x1 + x2) / 2, y1 + 6).dy, p(x2, y1).dx, p(x2, y1).dy);
    } else {
      path.quadraticBezierTo(
        p(x1, y1 + 10).dx,
        p(x1, y1 + 10).dy,
        p((x1 + x2) / 2, y1 + 10).dx,
        p((x1 + x2) / 2, y1 + 10).dy,
      );
      path.quadraticBezierTo(p(x2, y1 + 10).dx, p(x2, y1 + 10).dy, p(x2, y1).dx, p(x2, y1).dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawMouth(
    Canvas canvas,
    Offset Function(double, double) p,
    double s,
    double x1,
    double y1,
    double cx,
    double cy,
    double x2,
    double y2,
    Paint paint,
  ) {
    final path = Path();
    path.moveTo(p(x1, y1).dx, p(x1, y1).dy);
    path.quadraticBezierTo(p(cx, cy).dx, p(cx, cy).dy, p(x2, y2).dx, p(x2, y2).dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => oldDelegate.emotion != emotion;
}
