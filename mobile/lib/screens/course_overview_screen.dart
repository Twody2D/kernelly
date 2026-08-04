import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/path_screen.dart';
import 'package:mobile/widgets/gradient_banner.dart';

class CourseOverviewScreen extends StatefulWidget {
  const CourseOverviewScreen({super.key});

  @override
  State<CourseOverviewScreen> createState() => _CourseOverviewScreenState();
}

class _CourseOverviewScreenState extends State<CourseOverviewScreen> {
  List<Map<String, dynamic>> courses = [];
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await fetchCoursesOverview();
      final userData = await fetchUser(1);
      setState(() {
        courses = data;
        user = userData;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки курсов: $e');
      setState(() => loading = false);
    }
  }

  Map<String, dynamic>? get _continueCourse {
    for (final c in courses) {
    if (c['locked'] == true) continue;
    if (c['total'] > 0 && c['completed'] < c['total']) return c;
  }
  for (final c in courses) {
    if (c['locked'] != true && c['total'] > 0) return c;
  }
  return null;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final unlocked = courses.where((c) => c['locked'] != true).toList();
    final locked = courses.where((c) => c['locked'] == true).toList();
    final cont = _continueCourse;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                          color: const Color(0xFF58CC02),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF58CC02).withOpacity(0.2), spreadRadius: 3, blurRadius: 0),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Kernelly',
                          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1B2430))),
                    ],
                  ),
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text('${user!['streak']}',
                              style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFFFF9500))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (cont != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GradientBanner(
                  eyebrow: '\$ мои курсы / ${courses.length}',
                  title: 'Продолжить: ${cont['title']}',
                  badge: '${((cont['completed'] / cont['total']) * 100).round()}%',
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('КУРС',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF9AAAAA), letterSpacing: 0.4)),
                  Text('ПРОГРЕСС',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF9AAAAA), letterSpacing: 0.4)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: Column(
                children: [
                  for (final c in unlocked)
                    Padding(padding: const EdgeInsets.only(bottom: 10), child: _courseCard(c)),
                  if (locked.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(height: 1, thickness: 1, color: Color(0xFFDCE8E7))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('заблокировано',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF9AAAAA))),
                          ),
                          const Expanded(child: Divider(height: 1, thickness: 1, color: Color(0xFFDCE8E7))),
                        ],
                      ),
                    ),
                    for (final c in locked)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: _lockedCard(c)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(Map<String, dynamic> course) {
    final completed = course['completed'] as int;
    final total = course['total'] as int;
    final isDone = total > 0 && completed == total;
    final ratio = total > 0 ? completed / total : 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final sections = await fetchCourseSections(course['id']);
        if (sections.isEmpty) return;
        final first = sections.first;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PathScreen(sectionId: first['id'], sectionTitle: first['title'])),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                  colors: isDone
                      ? [const Color(0xFF6EDB1F), const Color(0xFF58CC02)]
                      : [const Color(0xFF29DFCB), const Color(0xFF00C9B7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: isDone ? const Color(0xFF3F9200) : const Color(0xFF00A896), offset: const Offset(0, 3)),
                ],
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Text('✓', style: TextStyle(fontSize: 19, color: Colors.white))
                  : Text('>_', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course['title'],
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14.5, color: const Color(0xFF1B2430)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: isDone ? const Color(0xFFEAF9DC) : const Color(0xFFE7EEEE),
                            valueColor: AlwaysStoppedAnimation(isDone ? const Color(0xFF58CC02) : const Color(0xFF00C9B7)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$completed/$total',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDone ? const Color(0xFF3F9200) : const Color(0xFF5C6B73))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedCard(Map<String, dynamic> course) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EEEE), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEEE),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0xFFD3DEDE), offset: Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lock, size: 20, color: Color(0xFFC2CDCD)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course['title'],
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14.5, color: const Color(0xFF8D9C9C)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(course['requirement'] ?? '',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF9AAAAA))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}