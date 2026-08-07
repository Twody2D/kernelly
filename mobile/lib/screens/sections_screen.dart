import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/path_screen.dart';
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
      final data = await fetchSectionsProgress(widget.courseId);
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
                    child: _sectionCard(section),
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

  Widget _sectionCard(Map<String, dynamic> section) {
    final status = section['status'] as String;
    final completed = section['completed'] as int;
    final total = section['total'] as int;
    final ratio = total > 0 ? completed / total : 0.0;

    final isDone = status == 'done';
    final isLocked = status == 'locked';

    final List<Color> iconGradient = isDone
        ? [const Color(0xFF6EDB1F), const Color(0xFF58CC02)]
        : [const Color(0xFF29DFCB), const Color(0xFF00C9B7)];
    final Color iconShadow = isDone ? const Color(0xFF3F9200) : const Color(0xFF00A896);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isLocked ? null : () => _openSection(section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF0F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked ? const Color(0xFFE7EEEE) : const Color(0xFFDCE8E7),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isLocked
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomRight,
                        colors: iconGradient,
                      ),
                color: isLocked ? const Color(0xFFE7EEEE) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isLocked ? const Color(0xFFD3DEDE) : iconShadow,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: isLocked
                  ? const Icon(Icons.lock, size: 20, color: Color(0xFFC2CDCD))
                  : isDone
                      ? const Icon(Icons.check, size: 21, color: Colors.white)
                      : const Text(
                          '>_',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Раздел ${section['order']} · ${section['title']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: isLocked ? const Color(0xFF8D9C9C) : const Color(0xFF1B2430),
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (isLocked)
                    const Text(
                      'пройдите предыдущий раздел',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        color: Color(0xFF9AAAAA),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 8,
                              backgroundColor: isDone ? const Color(0xFFEAF9DC) : const Color(0xFFE7EEEE),
                              valueColor: AlwaysStoppedAnimation(
                                isDone ? const Color(0xFF58CC02) : const Color(0xFF00C9B7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completed/$total',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDone ? const Color(0xFF3F9200) : const Color(0xFF5C6B73),
                          ),
                        ),
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
}
