import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/lesson_screen.dart';

class CourseOverviewScreen extends StatefulWidget {
  const CourseOverviewScreen({super.key});

  @override
  State<CourseOverviewScreen> createState() => _CourseOverviewScreenState();
}

class _CourseOverviewScreenState extends State<CourseOverviewScreen> {
  List<Map<String, dynamic>> courses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    final data = await fetchCourses();
    setState(() {
      courses = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFF58CC02), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Kernelly', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1B2430))),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('\$ мои курсы',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00A896))),
                const SizedBox(height: 16),
                for (final course in courses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LessonScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE1EAEA), width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C9B7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('>_',
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['title'],
                                      style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF1B2430))),
                                  if (course['description'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(course['description'],
                                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6B73))),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF5C6B73)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}