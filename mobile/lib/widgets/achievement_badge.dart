import 'package:flutter/material.dart';

/// Медаль достижения — кубок (чаша на ножке с ручками и подставкой),
/// залитый плоским цветом, с мягким бликом и тенью. Не круг и не монета.
class AchievementBadge extends StatelessWidget {
  final String icon;
  final String style;
  final bool unlocked;
  final double size;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.style,
    required this.unlocked,
    this.size = 56,
  });

  static const _colors = {
    'gold': (fill: Color(0xFFFFC72E), shadow: Color(0xFFB8791A)),
    'green': (fill: Color(0xFF6FCB2E), shadow: Color(0xFF2E7D0E)),
    'teal': (fill: Color(0xFF1FC2AE), shadow: Color(0xFF07584E)),
  };

  static const _locked = (fill: Color(0xFFCED9D9), shadow: Color(0xFFA0ACAC));

  @override
  Widget build(BuildContext context) {
    final palette = unlocked ? (_colors[style] ?? _colors['teal']!) : _locked;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _TrophyPainter(palette: palette),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.34),
            child: unlocked
                ? (icon.length > 2
                      ? Text(
                          icon,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w700,
                            fontSize: size * 0.15,
                            color: Colors.white,
                          ),
                        )
                      : Text(icon, style: TextStyle(fontSize: size * 0.22)))
                : Icon(
                    Icons.lock_rounded,
                    size: size * 0.2,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
          ),
        ],
      ),
    );
  }
}

typedef _Palette = ({Color fill, Color shadow});

class _TrophyPainter extends CustomPainter {
  final _Palette palette;

  _TrophyPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final fill = Paint()..color = palette.fill;

    // мягкая тень под кубком
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.93),
        width: w * 0.5,
        height: h * 0.055,
      ),
      Paint()
        ..color = palette.shadow.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // геометрия чаши
    const bowlTop = 0.08;
    const bowlRimHalfW = 0.25;
    const bowlBottomY = 0.46;
    const bowlBottomHalfW = 0.115;
    final rimHalfW = bowlRimHalfW * w;
    final bottomHalfW = bowlBottomHalfW * w;
    final topY = bowlTop * h;
    final bottomY = bowlBottomY * h;

    // ручки — по бокам чаши, рисуются первыми, чаша перекрывает их стыки
    final handlePaint = Paint()
      ..color = palette.fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round;
    final handleY = topY + (bottomY - topY) * 0.4;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - rimHalfW * 0.92, handleY),
        width: w * 0.26,
        height: h * 0.24,
      ),
      -1.15,
      2.5,
      false,
      handlePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + rimHalfW * 0.92, handleY),
        width: w * 0.26,
        height: h * 0.24,
      ),
      1.98,
      2.5,
      false,
      handlePaint,
    );

    // верхний ободок чаши (скруглённая полоса)
    final rimRect = Rect.fromLTWH(cx - rimHalfW, topY, rimHalfW * 2, h * 0.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, Radius.circular(h * 0.025)),
      fill,
    );

    // тело чаши — сужается книзу мягкой кривой, как бокал/кубок
    final bowlBodyTopY = topY + h * 0.03;
    final bowl = Path()
      ..moveTo(cx - rimHalfW, bowlBodyTopY)
      ..lineTo(cx + rimHalfW, bowlBodyTopY)
      ..quadraticBezierTo(
        cx + rimHalfW * 0.98,
        bottomY - h * 0.05,
        cx + bottomHalfW,
        bottomY,
      )
      ..lineTo(cx - bottomHalfW, bottomY)
      ..quadraticBezierTo(
        cx - rimHalfW * 0.98,
        bottomY - h * 0.05,
        cx - rimHalfW,
        bowlBodyTopY,
      )
      ..close();
    canvas.drawPath(bowl, fill);

    // ножка
    final neckW = bottomHalfW * 0.62;
    final neckTopY = bottomY;
    final neckBottomY = h * 0.62;
    canvas.drawRect(
      Rect.fromLTRB(cx - neckW, neckTopY, cx + neckW, neckBottomY),
      fill,
    );

    // подставка — две трапеции
    final footTopW = neckW * 2.6;
    final footTopRect = Rect.fromCenter(
      center: Offset(cx, neckBottomY + h * 0.03),
      width: footTopW,
      height: h * 0.06,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(footTopRect, Radius.circular(h * 0.015)),
      fill,
    );

    final footBottomW = footTopW * 1.45;
    final footBottomRect = Rect.fromCenter(
      center: Offset(cx, neckBottomY + h * 0.095),
      width: footBottomW,
      height: h * 0.055,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(footBottomRect, Radius.circular(h * 0.02)),
      fill,
    );

    // мягкий блик слева на чаше — вместо металлического блеска
    final highlight = Path()
      ..moveTo(cx - rimHalfW * 0.7, bowlBodyTopY + h * 0.02)
      ..quadraticBezierTo(
        cx - rimHalfW * 0.85,
        bottomY * 0.6,
        cx - bottomHalfW * 0.9,
        bottomY - h * 0.02,
      )
      ..lineTo(cx - bottomHalfW * 0.55, bottomY - h * 0.02)
      ..quadraticBezierTo(
        cx - rimHalfW * 0.55,
        bottomY * 0.6,
        cx - rimHalfW * 0.4,
        bowlBodyTopY + h * 0.02,
      )
      ..close();
    canvas.drawPath(
      highlight,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
