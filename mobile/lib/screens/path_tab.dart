import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/path_screen.dart';

/// Вкладка «Путь»: сама находит раздел, с которого пользователю продолжать,
/// и показывает его дорожку уроков.
class PathTab extends StatefulWidget {
  const PathTab({super.key});

  @override
  State<PathTab> createState() => PathTabState();
}

class PathTabState extends State<PathTab> {
  Map<String, dynamic>? current;
  bool loading = true;

  // меняется при каждой загрузке, чтобы пересоздать PathScreen со свежим прогрессом
  int _reloadTick = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await fetchCurrentSection(1);
      if (!mounted) return;
      setState(() {
        current = data;
        _reloadTick++;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки текущего раздела: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (current == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Пока нечего проходить —\nвыберите курс на вкладке «Курсы»',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF5C6B73),
              ),
            ),
          ),
        ),
      );
    }

    return PathScreen(
      key: ValueKey('${current!['section_id']}-$_reloadTick'),
      sectionId: current!['section_id'],
      sectionTitle: current!['section_title'],
      showBackButton: false,
    );
  }
}
