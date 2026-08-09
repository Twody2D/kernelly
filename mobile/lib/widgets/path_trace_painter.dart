import 'package:flutter/material.dart';

class PathTracePainter extends CustomPainter {
  final List<Offset> points;

  PathTracePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFFC9DBDA)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, _smoothPath(points), paint);
  }

  /// Квадратичные кривые через середины отрезков вместо прямых линий между
  /// точками — у зигзага с анкорами «центр/лево/право» каждый третий сегмент
  /// прыгает сразу с одного крайнего анкора на другой, и прямой линией это
  /// читалось как резкий разрыв дорожки. Квадратичная кривая с точкой-анкором
  /// как control point лежит внутри треугольника соседних точек (свойство
  /// выпуклой оболочки) — в отличие от Катмулла-Рома она никогда не
  /// «перелетает» за сам анкор, поэтому не заезжает в зону подписи раздела
  /// слева от дорожки.
  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }
    for (var i = 1; i < pts.length - 1; i++) {
      final anchor = pts[i];
      final mid = Offset(
        (anchor.dx + pts[i + 1].dx) / 2,
        (anchor.dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(anchor.dx, anchor.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 2.0;
    const dashGap = 10.0;
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
  bool shouldRepaint(covariant PathTracePainter oldDelegate) => oldDelegate.points != points;
}
