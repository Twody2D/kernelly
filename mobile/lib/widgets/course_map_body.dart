import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/lesson_screen.dart';
import 'package:mobile/screens/review_screen.dart';
import 'package:mobile/widgets/chapter_card.dart';
import 'package:mobile/widgets/daily_goal_card.dart';
import 'package:mobile/widgets/gradient_banner.dart';
import 'package:mobile/widgets/review_card.dart';
import 'package:mobile/widgets/section_path_nodes.dart';

/// Карта одного курса целиком — пройденные и заблокированные главы
/// компактными карточками, а глава в работе — развёрнутой дорожкой уроков.
/// Общая для вкладки «Путь» (текущий курс) и экрана разделов курса в «Курсах».
class CourseMapBody extends StatefulWidget {
  final int courseId;
  final int? dailyCompleted;
  final int? dailyGoal;
  final VoidCallback? onTapBanner;

  const CourseMapBody({
    super.key,
    required this.courseId,
    this.dailyCompleted,
    this.dailyGoal,
    this.onTapBanner,
  });

  @override
  State<CourseMapBody> createState() => CourseMapBodyState();
}

class CourseMapBodyState extends State<CourseMapBody> {
  String? courseTitle;
  List<Map<String, dynamic>> sections = [];
  List<Map<String, dynamic>> currentSectionLessons = [];
  int reviewDue = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        fetchSectionsProgress(widget.courseId, currentUserId),
        fetchReviewDue(currentUserId),
      ]);
      if (!mounted) return;

      final sectionsData = results[0] as Map<String, dynamic>;
      final sectionsList = List<Map<String, dynamic>>.from(
        sectionsData['sections'] ?? [],
      );

      Map<String, dynamic>? current;
      for (final section in sectionsList) {
        if (section['status'] == 'current') {
          current = section;
          break;
        }
      }
      final lessons = current == null
          ? <Map<String, dynamic>>[]
          : await fetchLessonsProgress(current['id'], currentUserId);
      if (!mounted) return;

      setState(() {
        courseTitle = sectionsData['course_title'] as String?;
        sections = sectionsList;
        currentSectionLessons = lessons;
        reviewDue = results[1] as int;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки карты курса: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _openReview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewScreen()),
    );
    load();
  }

  Future<void> _openLesson(
    Map<String, dynamic> lesson,
    String sectionTitle,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LessonScreen(lessonId: lesson['id'], sectionTitle: sectionTitle),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalLessons = sections.fold<int>(
      0,
      (sum, s) => sum + (s['total'] as int),
    );
    final doneLessons = sections.fold<int>(
      0,
      (sum, s) => sum + (s['completed'] as int),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        GradientBanner(
          eyebrow: '\$ курс',
          title: courseTitle ?? '',
          badge: '$doneLessons / $totalLessons',
          onTap: widget.onTapBanner,
        ),
        if (widget.dailyGoal != null) ...[
          const SizedBox(height: 14),
          DailyGoalCard(
            completed: widget.dailyCompleted ?? 0,
            goal: widget.dailyGoal!,
          ),
        ],
        if (reviewDue > 0) ...[
          const SizedBox(height: 14),
          ReviewCard(due: reviewDue, onTap: _openReview),
        ],
        const SizedBox(height: 20),
        for (final section in sections) _sectionBlock(section),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _sectionBlock(Map<String, dynamic> section) {
    final isCurrent = section['status'] == 'current';

    if (!isCurrent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ChapterCard(section: section),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Раздел ${section['order']} · ${section['title']}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00A896),
                letterSpacing: 0.4,
              ),
            ),
          ),
          SectionPathNodes(
            lessons: currentSectionLessons,
            onTapLesson: (lesson) => _openLesson(lesson, section['title']),
          ),
        ],
      ),
    );
  }
}
