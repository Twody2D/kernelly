import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/lesson_node.dart';
import 'package:mobile/widgets/path_trace_painter.dart';
import 'package:mobile/screens/lesson_screen.dart';
import 'package:mobile/widgets/gradient_banner.dart';

class PathScreen extends StatefulWidget {
  final int sectionId;
  final String sectionTitle;

  /// Во вкладке «Путь» возвращаться некуда, поэтому стрелку можно скрыть
  final bool showBackButton;

  const PathScreen({
    super.key,
    required this.sectionId,
    required this.sectionTitle,
    this.showBackButton = true,
  });

  @override
  State<PathScreen> createState() => PathScreenState();
}

class PathScreenState extends State<PathScreen> {
  List<Map<String, dynamic>> lessons = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await fetchLessonsProgress(widget.sectionId);
    setState(() {
      lessons = data;
      loading = false;
    });
  }

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
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final doneCount = lessons.where((l) => l['status'] == 'done').length;

    const nodeSpacingY = 130.0;
    const amplitude = 70.0;
    final anchors = [0.0, -1.0, 1.0];

    final pathHeight = lessons.isEmpty ? 300.0 : 44.0 + (lessons.length - 1) * nodeSpacingY + 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          GradientBanner(eyebrow: '\$ раздел', title: widget.sectionTitle, badge: '$doneCount / ${lessons.length}'),
          const SizedBox(height: 20),
          LayoutBuilder(
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
                          onTap: lessons[i]['status'] == 'locked'
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LessonScreen(lessonId: lessons[i]['id'], sectionTitle: widget.sectionTitle),
                                    ),
                                  );
                                  load();
                                },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
