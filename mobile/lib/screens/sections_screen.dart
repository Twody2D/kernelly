import 'package:flutter/material.dart';
import 'package:mobile/screens/course_intro_screen.dart';
import 'package:mobile/widgets/course_map_body.dart';

class SectionsScreen extends StatelessWidget {
  final int courseId;
  final String courseTitle;

  const SectionsScreen({super.key, required this.courseId, required this.courseTitle});

  @override
  Widget build(BuildContext context) {
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
                builder: (_) => CourseIntroScreen(courseId: courseId, courseTitle: courseTitle, isReplay: true),
              ),
            ),
          ),
        ],
      ),
      body: CourseMapBody(courseId: courseId),
    );
  }
}
