import 'package:flutter/material.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/course_map_tab.dart';
import 'package:mobile/screens/leaderboard_tab.dart';
import 'package:mobile/screens/feed_tab.dart';

/// Курсы отдельной вкладкой убраны — пока в приложении один курс, карта на
/// вкладке «Путь» и есть весь каталог.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final _pathKey = GlobalKey<CourseMapTabState>();
  final _leaderboardKey = GlobalKey<LeaderboardTabState>();
  final _feedKey = GlobalKey<FeedTabState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _tabs = [
    CourseMapTab(key: _pathKey),
    LeaderboardTab(key: _leaderboardKey),
    FeedTab(key: _feedKey),
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
        _leaderboardKey.currentState?.load();
        break;
      case 2:
        _feedKey.currentState?.load();
        break;
      case 3:
        _profileKey.currentState?.load();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          _reloadTab(index);
        },
        selectedItemColor: const Color(0xFF00A896),
        unselectedItemColor: const Color(0xFF5C6B73),
        selectedLabelStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Путь'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Топ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Новости',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
