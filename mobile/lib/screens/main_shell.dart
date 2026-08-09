import 'package:flutter/material.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/course_map_tab.dart';
import 'package:mobile/screens/leaderboard_tab.dart';
import 'package:mobile/screens/feed_tab.dart';
import 'package:mobile/theme/app_theme.dart';

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

  // Каждая вкладка и так грузит себя при первом построении (initState) — здесь
  // нужно освежать данные только при ВОЗВРАТЕ на вкладку (например, после
  // прохождения урока или подписки в чужом профиле). Без debounce быстрое
  // перелистывание туда-обратно между вкладками задваивало сетевые запросы
  // впустую — на каждый повторный тап без всякой новой активности между ними.
  static const _reloadDebounce = Duration(seconds: 15);
  // Все 4 вкладки уже грузят себя сами в этот момент через initState
  // (IndexedStack строит их все сразу) — считаем это первой загрузкой,
  // иначе самый первый тап по любой вкладке тут же задваивал её запрос.
  final _lastReload = <int, DateTime>{
    0: DateTime.now(),
    1: DateTime.now(),
    2: DateTime.now(),
    3: DateTime.now(),
  };

  void _reloadTab(int index) {
    final last = _lastReload[index];
    final now = DateTime.now();
    if (last != null && now.difference(last) < _reloadDebounce) return;
    _lastReload[index] = now;

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
    final colors = context.colors;
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.card,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          _reloadTab(index);
        },
        selectedItemColor: colors.accentDark,
        unselectedItemColor: colors.textSecondary,
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
