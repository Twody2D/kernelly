import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/course_intro_screen.dart';
import 'package:mobile/screens/shop_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/course_map_body.dart';

/// Вкладка «Путь»: шапка приложения (лого, streak), цель дня и карта текущего
/// курса — сама находит, с какого курса пользователю продолжать. Раньше это
/// было размазано между вкладками «Путь» и «Курсы», которую убрали, пока в
/// приложении всего один курс.
class CourseMapTab extends StatefulWidget {
  const CourseMapTab({super.key});

  @override
  State<CourseMapTab> createState() => CourseMapTabState();
}

class CourseMapTabState extends State<CourseMapTab> {
  final GlobalKey<CourseMapBodyState> _mapKey = GlobalKey();

  int? courseId;
  String courseTitle = '';
  Map<String, dynamic>? user;
  int cores = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final earlyPrefs = await SharedPreferences.getInstance();
      final preferredCourseId = earlyPrefs.getInt(PrefKeys.selectedCourseId);
      final current = await fetchCurrentSection(
        currentUserId,
        preferredCourseId: preferredCourseId,
      );
      if (!mounted) return;

      final newCourseId = current == null ? null : current['course_id'] as int;
      final sameCourse = courseId != null && courseId == newCourseId;

      if (newCourseId != null && !sameCourse) {
        final seenIntro = await hasSeenCourseIntro(newCourseId);
        if (!seenIntro && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseIntroScreen(
                courseId: newCourseId,
                courseTitle: current!['course_title'],
              ),
            ),
          );
        }
      }
      if (!mounted) return;

      final results = await Future.wait([
        fetchUser(currentUserId),
        fetchUserStats(currentUserId),
      ]);
      if (!mounted) return;
      final stats = results[1];

      setState(() {
        courseId = newCourseId;
        courseTitle = newCourseId == null
            ? ''
            : current!['course_title'] as String;
        user = results[0];
        cores = stats['cores'] as int? ?? 0;
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

  Future<void> _openShop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
    load();
  }

  Future<void> _replayIntro() async {
    if (courseId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CourseIntroScreen(courseId: courseId!, courseTitle: courseTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (loading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.success.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kernelly',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (user != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openShop,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📦', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  '$cores',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: colors.accentDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                '${user!['streak']}',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: colors.streak,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: courseId == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Пока нечего проходить',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            height: 1.4,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : CourseMapBody(
                      key: _mapKey,
                      courseId: courseId!,
                      onTapBanner: _replayIntro,
                      onProgressChanged: load,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
