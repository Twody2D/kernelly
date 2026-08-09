import 'package:flutter/material.dart';
import 'package:mobile/widgets/lesson_node.dart';
import 'package:mobile/widgets/path_trace_painter.dart';

/// Единая непрерывная змейка уроков сразу по всем разделам курса — раньше
/// каждый раздел рисовал свою отдельную SectionPathNodes, из-за чего дорожка
/// зрительно обрывалась и начиналась заново на границе разделов. Теперь один
/// сплошной путь через все уроки, а начало нового раздела просто помечается
/// компактной подписью слева от узла — без разрыва самой дорожки.
class CoursePathNodes extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  final ValueChanged<Map<String, dynamic>> onTapLesson;

  const CoursePathNodes({
    super.key,
    required this.lessons,
    required this.onTapLesson,
  });

  static const _gutterWidth = 150.0;
  // Раньше при 130 кривая успевала заметно уйти в сторону ровно там, где
  // под узлом стоит подпись урока — часть пунктира пряталась под текстом.
  // Больше расстояние даёт дорожке пробежать вертикально мимо подписи,
  // прежде чем заметно свернуть к следующему анкору.
  static const _nodeSpacingY = 176.0;
  static const _amplitude = 38.0;
  // лево → центр → право → центр — в отличие от «центр/лево/право» тут
  // между соседними узлами всегда один и тот же шаг по горизонтали, без
  // скачка через двойную амплитуду. Такой двойной скачок как раз и уходил
  // по крутой диагонали прямо через подпись следующего урока.
  static const _anchors = [-1.0, 0.0, 1.0, 0.0];

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
    final pathHeight = lessons.isEmpty
        ? 0.0
        : 44.0 + (lessons.length - 1) * _nodeSpacingY + 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pathWidth = constraints.maxWidth - _gutterWidth;
        final centerX = _gutterWidth + pathWidth / 2;
        final points = List.generate(lessons.length, (i) {
          final dx = centerX + _anchors[i % _anchors.length] * _amplitude;
          final dy = 44.0 + i * _nodeSpacingY;
          return Offset(dx, dy);
        });

        return SizedBox(
          height: pathHeight,
          child: Stack(
            children: [
              CustomPaint(size: Size.infinite, painter: PathTracePainter(points)),
              for (int i = 0; i < lessons.length; i++) ...[
                Positioned(
                  left: points[i].dx - 34,
                  top: points[i].dy - 34,
                  child: LessonNode(
                    label: lessons[i]['title'],
                    status: _statusFor(lessons[i]['status']),
                    mastery: lessons[i]['mastery'] ?? 0,
                    onTap: lessons[i]['status'] == 'locked'
                        ? null
                        : () => onTapLesson(lessons[i]),
                  ),
                ),
                if (lessons[i]['sectionName'] != null)
                  Positioned(
                    left: 4,
                    top: points[i].dy - 30,
                    width: _gutterWidth - 12,
                    child: _SectionTag(
                      order: lessons[i]['sectionOrder'] as int,
                      name: lessons[i]['sectionName'] as String,
                      locked: lessons[i]['sectionLocked'] == true,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionTag extends StatelessWidget {
  final int order;
  final String name;
  final bool locked;

  const _SectionTag({
    required this.order,
    required this.name,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked ? const Color(0xFF9AAAAA) : const Color(0xFF00A896);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(Icons.lock, size: 11, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                'РАЗДЕЛ $order',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Без ограничения строк — раньше длинные названия обрезались
          // многоточием прямо посреди слова.
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
