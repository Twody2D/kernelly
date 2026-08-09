import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/user_profile_screen.dart';

/// Вкладка «Топ»: рейтинг игроков по XP за текущую неделю лиги — сбрасывается
/// каждый понедельник в 00:00 МСК, топ-3 прошлой недели получают сундук с
/// ядрами (см. бейдж в профиле, ShopScreen — для наград за заморозки).
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => LeaderboardTabState();
}

class LeaderboardTabState extends State<LeaderboardTab> {
  List<Map<String, dynamic>> entries = [];
  Map<String, dynamic>? me;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await fetchLeaderboard(currentUserId);
      if (!mounted) return;
      setState(() {
        entries = List<Map<String, dynamic>>.from(data['entries'] ?? []);
        me = data['me'] as Map<String, dynamic>?;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки топа: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          'Топ игроков',
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
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: RefreshIndicator(
                    onRefresh: load,
                    child: entries.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              const SizedBox(height: 80),
                              Text(
                                'На этой неделе пока никто не набрал XP.\nБудь первым!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  height: 1.4,
                                  color: const Color(0xFF5C6B73),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) =>
                                _row(entries[index]),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _openProfile(Map<String, dynamic> entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: entry['user_id'] as int,
          username: entry['username'] as String? ?? 'Игрок',
          initialIsFollowing: entry['is_following'] == true,
        ),
      ),
    );
    load();
  }

  Widget _row(Map<String, dynamic> entry) {
    final rank = entry['rank'] as int;
    final isMe = entry['user_id'] == currentUserId;

    Color rankBg;
    Color rankColor;
    if (rank == 1) {
      rankBg = const Color(0xFFFFD98A);
      rankColor = const Color(0xFF7A5A00);
    } else if (rank == 2) {
      rankBg = const Color(0xFFE7EEEE);
      rankColor = const Color(0xFF5C6B73);
    } else if (rank == 3) {
      rankBg = const Color(0xFFF3D4B5);
      rankColor = const Color(0xFF8A5A22);
    } else {
      rankBg = const Color(0xFFF6F9F9);
      rankColor = const Color(0xFF9AAAAA);
    }

    return GestureDetector(
      onTap: isMe ? null : () => _openProfile(entry),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: const Color(0xFF00C9B7), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? '${entry['username']} (ты)' : entry['username'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                color: const Color(0xFF1B2430),
              ),
            ),
          ),
          if ((entry['streak'] as int) > 0) ...[
            const Text('🔥', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            Text(
              '${entry['streak']}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: const Color(0xFFFF9500),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            '${entry['xp_week']} XP',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: const Color(0xFF00A896),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
