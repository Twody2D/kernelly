import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/course_intro_screen.dart';
import 'package:mobile/screens/path_screen.dart';
import 'package:mobile/widgets/chapter_card.dart';
import 'package:mobile/widgets/gradient_banner.dart';

class SectionsScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const SectionsScreen({super.key, required this.courseId, required this.courseTitle});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  List<Map<String, dynamic>> sections = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await fetchSectionsProgress(widget.courseId, currentUserId);
      if (!mounted) return;
      setState(() {
        sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки разделов: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _openSection(Map<String, dynamic> section) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PathScreen(sectionId: section['id'], sectionTitle: section['title']),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = sections.where((s) => s['status'] == 'done').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
        actions: [
          IconButton(
            tooltip: 'Пересмотреть заставку курса',
            icon: const Icon(Icons.replay_rounded, color: Color(0xFF5C6B73)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseIntroScreen(courseId: widget.courseId, courseTitle: widget.courseTitle, isReplay: true),
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                GradientBanner(
                  eyebrow: '\$ курс',
                  title: widget.courseTitle,
                  badge: '$doneCount / ${sections.length}',
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    'РАЗДЕЛЫ',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9AAAAA),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                for (final section in sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ChapterCard(section: section, onTap: () => _openSection(section)),
                  ),
                if (sections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'В этом курсе пока нет разделов',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF5C6B73),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

}
