import 'package:flutter/material.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/course_map_tab.dart';

/// Курсы отдельной вкладкой убраны — пока в приложении один курс, карта на
/// вкладке «Путь» и есть весь каталог. Топ игроков и лента активности друзей
/// добавятся сюда следующими вкладками, когда будет готов бэкенд под них.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final _pathKey = GlobalKey<CourseMapTabState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _tabs = [
    CourseMapTab(key: _pathKey),
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
        _profileKey.currentState?.load();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          _reloadTab(index);
        },
        selectedItemColor: const Color(0xFF00A896),
        unselectedItemColor: const Color(0xFF5C6B73),
        selectedLabelStyle: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Путь'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
