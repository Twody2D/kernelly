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

  final _pathKey = GlobalKey<PathScreenState>();
  final _coursesKey = GlobalKey<CourseOverviewScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _tabs = [
    PathScreen(key: _pathKey, sectionId: 1, sectionTitle: 'Работа с файлами'),
    CourseOverviewScreen(key: _coursesKey),
    ProfileScreen(key: _profileKey),
  ];

  // IndexedStack сохраняет состояние вкладок, поэтому initState при переключении
  // больше не срабатывает — обновляем данные вручную
  void _reloadTab(int index) {
    switch (index) {
      case 0:
        _pathKey.currentState?.load();
        break;
      case 1:
        _coursesKey.currentState?.load();
        break;
      case 2:
        _profileKey.currentState?.load();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          _reloadTab(index);
        },
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
