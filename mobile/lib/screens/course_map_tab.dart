import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/course_map_body.dart';

/// Вкладка «Путь»: карта текущего курса — сама находит, с какого курса
/// пользователю продолжать, и показывает его карту.
class CourseMapTab extends StatefulWidget {
  const CourseMapTab({super.key});

  @override
  State<CourseMapTab> createState() => CourseMapTabState();
}

class CourseMapTabState extends State<CourseMapTab> {
  final GlobalKey<CourseMapBodyState> _mapKey = GlobalKey();

  int? courseId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final current = await fetchCurrentSection(currentUserId);
      if (!mounted) return;

      final newCourseId = current == null ? null : current['course_id'] as int;
      final sameCourse = courseId != null && courseId == newCourseId;

      setState(() {
        courseId = newCourseId;
        loading = false;
      });

      // курс тот же — карта не пересоздаётся, обновляем прогресс на месте
      if (sameCourse) _mapKey.currentState?.load();
    } catch (e) {
      debugPrint('Ошибка загрузки текущего курса: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (courseId == null) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(backgroundColor: const Color(0xFFF6F9F9), elevation: 0),
      body: CourseMapBody(key: _mapKey, courseId: courseId!),
    );
  }
}
