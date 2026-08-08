import 'package:flutter/material.dart';

enum LessonNodeStatus { done, current, locked }

class LessonNode extends StatelessWidget {
  final String label;
  final LessonNodeStatus status;
  final VoidCallback? onTap;

  /// 0 = нет мастерства, 1/2/3 = бронза/серебро/золото за число прохождений
  final int mastery;

  const LessonNode({super.key, required this.label, required this.status, this.onTap, this.mastery = 0});

  /// Пройденный урок красится по уровню мастерства (бронза/серебро/золото),
  /// а не зелёным «готово» — так уровень виден сразу на карте, без лишней
  /// медальки в углу.
  static const _masteryGradients = {
    1: (top: Color(0xFFE8B27C), bottom: Color(0xFFC97A3B), shadow: Color(0xFF8B5228)),
    2: (top: Color(0xFFDCE4E8), bottom: Color(0xFF9FB0BA), shadow: Color(0xFF67767E)),
    3: (top: Color(0xFFFFE49A), bottom: Color(0xFFE8B93A), shadow: Color(0xFFA87A12)),
  };
  static const _doneDefault = (top: Color(0xFF6EDB1F), bottom: Color(0xFF58CC02), shadow: Color(0xFF3F9200));

  @override
  Widget build(BuildContext context) {
    final bool isDone = status == LessonNodeStatus.done;
    final bool isCurrent = status == LessonNodeStatus.current;
    final doneStyle = isDone ? (_masteryGradients[mastery] ?? _doneDefault) : null;

    final Color fillTop = isDone
        ? doneStyle!.top
        : isCurrent
        ? const Color(0xFF29DFCB)
        : const Color(0xFFE7EEEE);
    final Color fillBottom = isDone
        ? doneStyle!.bottom
        : isCurrent
        ? const Color(0xFF00C9B7)
        : const Color(0xFFE7EEEE);
    final Color shadow = isDone
        ? doneStyle!.shadow
        : isCurrent
        ? const Color(0xFF00A896)
        : const Color(0xFFD3DEDE);
    final Color pinColor = (isDone || isCurrent) ? Colors.white.withOpacity(0.55) : const Color(0xFFD3DEDE);

    return SizedBox(
      width: 90,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [fillTop, fillBottom],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isDone ? '✓' : (isCurrent ? '>_' : '🔒'),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: isCurrent || isDone ? Colors.white : const Color(0xFFC2CDCD),
                    ),
                  ),
                ),
                Positioned(bottom: -10, left: 16, child: _pin(pinColor)),
                Positioned(bottom: -10, right: 16, child: _pin(pinColor)),
                if (isCurrent) Positioned(top: -7, left: -7, right: -7, bottom: -7, child: _PulsingRing()),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9F9).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5C6B73),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pin(Color color) => Container(
    width: 4,
    height: 10,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
  );
}

class _PulsingRing extends StatefulWidget {
  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final value = curved.value;
        final opacity = 0.3 + (value * 0.7);
        final scale = 1.0 + (value * 0.06);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(painter: _DashedRingPainter()),
          ),
        );
      },
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C9B7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final radius = Radius.circular(26);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));

    const dashWidth = 5.0;
    const dashGap = 4.0;
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
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => false;
}
