import 'package:flutter/material.dart';

const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

/// Одна линия графика: XP по дням недели ({date, xp}) и её цвет.
class ChartSeries {
  final String label;
  final List<Map<String, dynamic>> days;
  final Color color;

  const ChartSeries({
    required this.label,
    required this.days,
    required this.color,
  });

  int get totalXp => days.fold(0, (sum, d) => sum + (d['xp'] as int));
}

/// Линейный график активности за неделю — одна серия (свой профиль) или
/// несколько (сравнение с другом), с осью Y и подписями дней снизу.
class WeeklyActivityChart extends StatelessWidget {
  final List<ChartSeries> series;

  const WeeklyActivityChart({super.key, required this.series});

  int get _maxXp {
    int max = 0;
    for (final s in series) {
      for (final d in s.days) {
        final xp = d['xp'] as int;
        if (xp > max) max = xp;
      }
    }
    return max;
  }

  /// Округляет верхнюю границу оси Y до «красивого» числа, кратного трём
  /// делениям (0, 1/3, 2/3, макс.) — чтобы подписи выглядели ровно.
  int _niceChartMax(int value) {
    const stepOptions = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000];
    for (final step in stepOptions) {
      if (step * 3 >= value) return step * 3;
    }
    return ((value / 3000).ceil()) * 3000;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: CustomPaint(
        size: Size.infinite,
        painter: _WeeklyChartPainter(series: series, maxValue: _niceChartMax(_maxXp)),
      ),
    );
  }
}

/// Легенда под графиком — цветная точка, имя серии и сумма XP за неделю.
class WeeklyChartLegend extends StatelessWidget {
  final List<ChartSeries> series;

  const WeeklyChartLegend({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < series.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: series[i].color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                series[i].label,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: const Color(0xFF1B2430),
                ),
              ),
              const Spacer(),
              Text(
                '${series[i].totalXp} очков',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: const Color(0xFF9AAAAA),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final int maxValue;

  _WeeklyChartPainter({required this.series, required this.maxValue});

  static const _leftAxisWidth = 30.0;
  static const _bottomLabelsHeight = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _leftAxisWidth;
    final chartHeight = size.height - _bottomLabelsHeight;

    final gridPaint = Paint()
      ..color = const Color(0xFFE7EEEE)
      ..strokeWidth = 1;
    final axisTextStyle = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 9.5,
      color: const Color(0xFF9AAAAA),
    );

    for (int i = 0; i < 4; i++) {
      final value = (maxValue * i / 3).round();
      final y = chartHeight - chartHeight * i / 3;
      canvas.drawLine(
        Offset(_leftAxisWidth, y),
        Offset(size.width, y),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: '$value', style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_leftAxisWidth - 6 - tp.width, y - tp.height / 2));
    }

    if (series.isEmpty || series.first.days.isEmpty) return;

    final dayCount = series.first.days.length;
    final stepX = dayCount > 1 ? chartWidth / (dayCount - 1) : 0.0;

    for (final s in series) {
      final points = <Offset>[];
      for (int i = 0; i < s.days.length; i++) {
        final xp = s.days[i]['xp'] as int;
        final x = _leftAxisWidth + stepX * i;
        final ratio = maxValue == 0 ? 0.0 : (xp / maxValue).clamp(0.0, 1.0);
        final y = chartHeight - chartHeight * ratio;
        points.add(Offset(x, y));
      }

      final linePaint = Paint()
        ..color = s.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);

      for (int i = 0; i < points.length; i++) {
        final isToday = i == points.length - 1;
        final radius = isToday ? 6.0 : 5.0;
        canvas.drawCircle(points[i], radius, Paint()..color = s.color);
        canvas.drawCircle(
          points[i],
          radius,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }

    for (int i = 0; i < dayCount; i++) {
      final isToday = i == dayCount - 1;
      final parsed = DateTime.tryParse(series.first.days[i]['date']);
      final label = parsed == null ? '' : _weekdays[parsed.weekday - 1];
      final x = _leftAxisWidth + stepX * i;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9.5,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: isToday ? const Color(0xFF00A896) : const Color(0xFF9AAAAA),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.maxValue != maxValue;
}
