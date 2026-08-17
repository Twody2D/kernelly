import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/duel_screen.dart';

/// Список дуэлей: приглашения (ждут моего ответа), активные (уже принял,
/// но кто-то ещё не сдал результат) и завершённые. Открывается по тапу на
/// уведомление о дуэли (см. notifications_screen.dart) — своего отдельного
/// пункта меню нет, дуэли начинаются с чужого профиля.
class DuelsScreen extends StatefulWidget {
  const DuelsScreen({super.key});

  @override
  State<DuelsScreen> createState() => _DuelsScreenState();
}

class _DuelsScreenState extends State<DuelsScreen> {
  List<Map<String, dynamic>> duels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await fetchDuels(currentUserId);
      if (!mounted) return;
      setState(() {
        duels = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки дуэлей: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _decline(Map<String, dynamic> duel) async {
    try {
      await declineDuel(currentUserId, duel['id'] as int);
      _load();
    } catch (e) {
      debugPrint('Ошибка отклонения дуэли: $e');
    }
  }

  Future<void> _play(Map<String, dynamic> duel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DuelScreen(
          duelId: duel['id'] as int,
          opponentName: duel['opponent']['username'] as String? ?? 'Игрок',
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final invites = duels
        .where((d) => d['status'] == 'pending' && d['role'] == 'opponent')
        .toList();
    final active = duels
        .where(
          (d) =>
              d['status'] == 'active' ||
              (d['status'] == 'pending' && d['role'] == 'challenger'),
        )
        .toList();
    final completed = duels.where((d) => d['status'] == 'completed').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          'Дуэли',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: const Color(0xFF1B2430),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : duels.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Пока нет дуэлей — вызови друга со страницы его профиля',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        height: 1.4,
                        color: const Color(0xFF5C6B73),
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          if (invites.isNotEmpty) ...[
                            _sectionTitle('Приглашения'),
                            for (final d in invites) _inviteRow(d),
                            const SizedBox(height: 20),
                          ],
                          if (active.isNotEmpty) ...[
                            _sectionTitle('Активные'),
                            for (final d in active) _activeRow(d),
                            const SizedBox(height: 20),
                          ],
                          if (completed.isNotEmpty) ...[
                            _sectionTitle('Завершённые'),
                            for (final d in completed) _completedRow(d),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1B2430),
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
        ),
        child: child,
      );

  Widget _opponentLine(Map<String, dynamic> duel) {
    final opponent = duel['opponent'] as Map<String, dynamic>;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEAEA),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bolt, size: 17, color: Color(0xFFB33A3A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            opponent['username'] as String? ?? 'Игрок',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF1B2430),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _inviteRow(Map<String, dynamic> duel) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _opponentLine(duel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _decline(duel),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC2CDCD)),
                    foregroundColor: const Color(0xFF5C6B73),
                  ),
                  child: const Text('Отклонить'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _play(duel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B4B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Играть'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeRow(Map<String, dynamic> duel) {
    final myFinished = duel['my_finished'] == true;
    return _card(
      child: Row(
        children: [
          Expanded(child: _opponentLine(duel)),
          const SizedBox(width: 10),
          if (myFinished)
            Text(
              'Ждём соперника',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: const Color(0xFF5C6B73),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _play(duel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Играть'),
            ),
        ],
      ),
    );
  }

  Widget _completedRow(Map<String, dynamic> duel) {
    final isMeWinner = duel['is_me_winner'];
    final cores = duel['cores_awarded'] as int?;
    final String resultText;
    final Color resultColor;
    if (isMeWinner == true) {
      resultText = cores != null ? 'Победа · +$cores ядер' : 'Победа';
      resultColor = const Color(0xFF3F9200);
    } else if (isMeWinner == false) {
      resultText = 'Поражение';
      resultColor = const Color(0xFFB33A3A);
    } else {
      resultText = 'Ничья';
      resultColor = const Color(0xFF5C6B73);
    }
    return _card(
      child: Row(
        children: [
          Expanded(child: _opponentLine(duel)),
          const SizedBox(width: 10),
          Text(
            resultText,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: resultColor,
            ),
          ),
        ],
      ),
    );
  }
}
