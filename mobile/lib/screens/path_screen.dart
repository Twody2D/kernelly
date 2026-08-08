import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/lesson_screen.dart';
import 'package:mobile/screens/review_screen.dart';
import 'package:mobile/widgets/gradient_banner.dart';
import 'package:mobile/widgets/review_card.dart';
import 'package:mobile/widgets/section_path_nodes.dart';

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
  bool hasError = false;
  int reviewDue = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(PathScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionId != widget.sectionId) load();
  }

  void _retry() {
    setState(() {
      loading = true;
      hasError = false;
    });
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        fetchLessonsProgress(widget.sectionId, currentUserId),
        fetchReviewDue(currentUserId),
      ]);
      if (!mounted) return;
      setState(() {
        lessons = results[0] as List<Map<String, dynamic>>;
        reviewDue = results[1] as int;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки пути: $e');
      if (!mounted) return;
      setState(() {
        hasError = true;
        loading = false;
      });
    }
  }

  Future<void> _openReview() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
    load();
  }

  Future<void> _openLesson(Map<String, dynamic> lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(lessonId: lesson['id'], sectionTitle: widget.sectionTitle),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F9F9),
          elevation: 0,
          automaticallyImplyLeading: widget.showBackButton,
          iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Не удалось загрузить раздел',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, fontSize: 15, color: const Color(0xFF5C6B73)),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _retry,
                  child: Text('Повторить', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: const Color(0xFF00A896))),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final doneCount = lessons.where((l) => l['status'] == 'done').length;

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
          if (reviewDue > 0) ...[
            const SizedBox(height: 14),
            ReviewCard(due: reviewDue, onTap: _openReview),
          ],
          const SizedBox(height: 20),
          SectionPathNodes(lessons: lessons, onTapLesson: _openLesson),
        ],
      ),
    );
  }
}
