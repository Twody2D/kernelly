import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/course_overview_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/path_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 1;

  final List<Widget> _tabs = const [
    PathScreen(sectionId: 1, sectionTitle: 'Работа с файлами'),
    CourseOverviewScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        selectedItemColor: const Color(0xFF00A896),
        unselectedItemColor: const Color(0xFF5C6B73),
        selectedLabelStyle: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.jetBrainsMono(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Путь'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Курсы'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: Center(
        child: Text('$label — скоро', style: GoogleFonts.fredoka(fontSize: 16, color: const Color(0xFF5C6B73))),
      ),
    );
  }
}