import 'package:flutter/material.dart';
import 'package:mobile/widgets/lesson_node.dart';
import 'package:mobile/widgets/path_trace_painter.dart';

/// Змейка узлов-уроков одного раздела с пунктирной дорожкой между ними —
/// общая для отдельного экрана раздела и карты всего курса.
class SectionPathNodes extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  final ValueChanged<Map<String, dynamic>> onTapLesson;

  const SectionPathNodes({super.key, required this.lessons, required this.onTapLesson});

  LessonNodeStatus _statusFor(String status) {
    switch (status) {
      case 'done':
        return LessonNodeStatus.done;
      case 'current':
        return LessonNodeStatus.current;
      default:
        return LessonNodeStatus.locked;
    }
  }

  @override
  Widget build(BuildContext context) {
    const nodeSpacingY = 130.0;
    const amplitude = 70.0;
    final anchors = [0.0, -1.0, 1.0];

    final pathHeight = lessons.isEmpty ? 0.0 : 44.0 + (lessons.length - 1) * nodeSpacingY + 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final dynamicPoints = List.generate(lessons.length, (i) {
          final dx = centerX + anchors[i % 3] * amplitude;
          final dy = 44.0 + i * nodeSpacingY;
          return Offset(dx, dy);
        });

        return SizedBox(
          height: pathHeight,
          child: Stack(
            children: [
              CustomPaint(size: Size.infinite, painter: PathTracePainter(dynamicPoints)),
              for (int i = 0; i < lessons.length; i++)
                Positioned(
                  left: dynamicPoints[i].dx - 34,
                  top: dynamicPoints[i].dy - 34,
                  child: LessonNode(
                    label: lessons[i]['title'],
                    status: _statusFor(lessons[i]['status']),
                    onTap: lessons[i]['status'] == 'locked' ? null : () => onTapLesson(lessons[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
