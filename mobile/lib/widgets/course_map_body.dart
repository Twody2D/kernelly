import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/lesson_screen.dart';
import 'package:mobile/screens/review_screen.dart';
import 'package:mobile/widgets/course_path_nodes.dart';
import 'package:mobile/widgets/daily_goal_card.dart';
import 'package:mobile/widgets/gradient_banner.dart';
import 'package:mobile/widgets/review_card.dart';

/// Карта одного курса целиком — единая непрерывная дорожка уроков сразу по
/// всем разделам: пройденные и текущий раздел со своим реальным статусом,
/// а уроки ещё не открытых разделов видны, но помечены заблокированными.
/// Начало нового раздела помечается подписью сбоку от узла, без разрыва
/// самой дорожки (см. CoursePathNodes). Общая для вкладки «Путь» (текущий
/// курс) и экрана разделов курса в «Курсах».
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
  List<Map<String, dynamic>> combinedLessons = [];
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

      // Уроки нужны сразу для всех разделов, не только текущего — путь
      // показывает их все одной дорожкой. Для ещё не открытых разделов
      // бэкенд считает первый урок «current» сам по себе (без учёта того,
      // что раздел целиком заблокирован), поэтому такие статусы
      // принудительно подменяем на «locked» ниже.
      final lessonsLists = await Future.wait(
        sectionsList.map((s) => fetchLessonsProgress(s['id'], currentUserId)),
      );
      if (!mounted) return;

      // Одна плоская дорожка на все разделы — начало раздела помечается
      // 'sectionLabel' на первом его уроке (см. CoursePathNodes), сам путь
      // при этом не прерывается.
      final combined = <Map<String, dynamic>>[];
      for (var i = 0; i < sectionsList.length; i++) {
        final section = sectionsList[i];
        final locked = section['status'] == 'locked';
        final sectionLessons = lessonsLists[i];
        for (var j = 0; j < sectionLessons.length; j++) {
          final lesson = sectionLessons[j];
          combined.add({
            ...lesson,
            'status': locked ? 'locked' : lesson['status'],
            '_sectionTitle': section['title'],
            'sectionOrder': j == 0 ? section['order'] : null,
            'sectionName': j == 0 ? section['title'] : null,
            'sectionLocked': locked,
          });
        }
      }

      setState(() {
        courseTitle = sectionsData['course_title'] as String?;
        sections = sectionsList;
        combinedLessons = combined;
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

  Future<void> _openLesson(Map<String, dynamic> lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lessonId: lesson['id'],
          sectionTitle: lesson['_sectionTitle'] as String,
        ),
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
        CoursePathNodes(lessons: combinedLessons, onTapLesson: _openLesson),
        const SizedBox(height: 12),
      ],
    );
  }
}
