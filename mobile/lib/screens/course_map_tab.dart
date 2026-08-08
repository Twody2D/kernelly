import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/lesson_screen.dart';
import 'package:mobile/screens/review_screen.dart';
import 'package:mobile/widgets/chapter_card.dart';
import 'package:mobile/widgets/gradient_banner.dart';
import 'package:mobile/widgets/review_card.dart';
import 'package:mobile/widgets/section_path_nodes.dart';

/// Вкладка «Путь»: карта всего курса целиком — пройденные и заблокированные
/// главы компактными карточками, а глава в работе — развёрнутой дорожкой
/// уроков. Так сразу видно, сколько пройдено и сколько ещё идти.
class CourseMapTab extends StatefulWidget {
  const CourseMapTab({super.key});

  @override
  State<CourseMapTab> createState() => CourseMapTabState();
}

class CourseMapTabState extends State<CourseMapTab> {
  String? courseTitle;
  int? courseId;
  List<Map<String, dynamic>> sections = [];
  List<Map<String, dynamic>> currentSectionLessons = [];
  int reviewDue = 0;
  bool loading = true;
  bool hasCourse = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final current = await fetchCurrentSection(currentUserId);
      if (!mounted) return;

      if (current == null) {
        setState(() {
          hasCourse = false;
          loading = false;
        });
        return;
      }

      final results = await Future.wait([
        fetchSectionsProgress(current['course_id'], currentUserId),
        fetchLessonsProgress(current['section_id'], currentUserId),
        fetchReviewDue(currentUserId),
      ]);
      if (!mounted) return;

      final sectionsData = results[0] as Map<String, dynamic>;
      setState(() {
        hasCourse = true;
        courseId = current['course_id'];
        courseTitle = sectionsData['course_title'] as String?;
        sections = List<Map<String, dynamic>>.from(sectionsData['sections'] ?? []);
        currentSectionLessons = results[1] as List<Map<String, dynamic>>;
        reviewDue = results[2] as int;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки карты курса: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _openReview() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
    load();
  }

  Future<void> _openLesson(Map<String, dynamic> lesson, String sectionTitle) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonScreen(lessonId: lesson['id'], sectionTitle: sectionTitle)),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasCourse) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Пока нечего проходить —\nвыберите курс на вкладке «Курсы»',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF5C6B73),
              ),
            ),
          ),
        ),
      );
    }

    final totalLessons = sections.fold<int>(0, (sum, s) => sum + (s['total'] as int));
    final doneLessons = sections.fold<int>(0, (sum, s) => sum + (s['completed'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(backgroundColor: const Color(0xFFF6F9F9), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          GradientBanner(eyebrow: '\$ курс', title: courseTitle ?? '', badge: '$doneLessons / $totalLessons'),
          if (reviewDue > 0) ...[
            const SizedBox(height: 14),
            ReviewCard(due: reviewDue, onTap: _openReview),
          ],
          const SizedBox(height: 20),
          for (final section in sections) _sectionBlock(section),
          const SizedBox(height: 12),
        ],
      ),
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
