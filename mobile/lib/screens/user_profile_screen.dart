import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/avatars.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/follow_list_screen.dart';
import 'package:mobile/screens/achievement_detail_screen.dart';
import 'package:mobile/widgets/achievement_badge.dart';
import 'package:mobile/widgets/weekly_activity_chart.dart';

const _months = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

/// Профиль другого пользователя — читается публично: краткая статистика,
/// сравнение недельной активности с собой и достижения. Без настроек.
class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String username;
  final bool initialIsFollowing;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.initialIsFollowing,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? stats;
  Map<String, dynamic>? activity;
  Map<String, dynamic>? myActivity;
  Map<String, dynamic>? achievements;
  bool loading = true;
  late bool isFollowing = widget.initialIsFollowing;
  bool followPending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        fetchUserStats(widget.userId),
        fetchUserActivity(widget.userId),
        fetchUserActivity(currentUserId),
        fetchUserAchievements(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        stats = results[0];
        activity = results[1];
        myActivity = results[2];
        achievements = results[3];
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки профиля пользователя: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => followPending = true);
    try {
      if (isFollowing) {
        await unfollowUser(currentUserId, widget.userId);
      } else {
        await followUser(currentUserId, widget.userId);
      }
      if (!mounted) return;
      setState(() {
        isFollowing = !isFollowing;
        followPending = false;
      });
    } catch (e) {
      debugPrint('Ошибка подписки: $e');
      if (!mounted) return;
      setState(() => followPending = false);
    }
  }

  String _memberSince(String? isoDate) {
    if (isoDate == null) return '';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return '';
    return 'в Kernelly с ${_months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          widget.username,
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
          : stats == null
              ? Center(
                  child: Text(
                    'Не удалось загрузить профиль',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: const Color(0xFF5C6B73),
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
                          _banner(),
                          const SizedBox(height: 14),
                          _socialRow(),
                          const SizedBox(height: 10),
                          _followButton(),
                          const SizedBox(height: 20),
                          _comparisonCard(),
                          const SizedBox(height: 20),
                          Text(
                            'Обзор',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF1B2430),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  'ВСЕГО XP',
                                  '${stats!['xp']}',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statCard(
                                  'STREAK',
                                  '🔥 ${stats!['streak']}',
                                  valueColor: const Color(0xFFFF9500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _achievementsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _banner() {
    final avatar = avatarByCode(stats!['avatar'] as String?);
    final (_, icon, fg, bg) = avatar;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C9B7), Color(0xFF00A896)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4000A896),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: fg, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats!['username'] ?? 'Игрок',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 19,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _memberSince(stats!['created_at']),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      color: const Color(0xE6FFFFFF),
                      fontSize: 10.5,
                    ),
                  ),
                  if (stats!['current_course_title'] != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'сейчас проходит: ${stats!['current_course_title']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _followButton() {
    return GestureDetector(
      onTap: followPending ? null : _toggleFollow,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white : const Color(0xFFE0F7F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFollowing
                ? const Color(0xFFC2CDCD)
                : const Color(0xFFAEE5DE),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          isFollowing ? 'ВЫ ПОДПИСАНЫ' : 'ПОДПИСАТЬСЯ',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isFollowing
                ? const Color(0xFF5C6B73)
                : const Color(0xFF00A896),
          ),
        ),
      ),
    );
  }

  Widget _socialRow() {
    final followers = stats!['followers_count'] ?? 0;
    final following = stats!['following_count'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _socialCount(
            'Подписчики',
            followers,
            FollowListMode.followers,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _socialCount('Подписки', following, FollowListMode.following),
        ),
      ],
    );
  }

  Widget _socialCount(String label, int count, FollowListMode mode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FollowListScreen(
            mode: mode,
            userId: widget.userId,
            ownerUsername: widget.username,
          ),
        ),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: const Color(0xFF1B2430),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9.5,
                color: const Color(0xFF9AAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonCard() {
    final myDays = List<Map<String, dynamic>>.from(myActivity?['days'] ?? []);
    final theirDays = List<Map<String, dynamic>>.from(activity?['days'] ?? []);
    final series = [
      ChartSeries(label: 'Вы', days: myDays, color: const Color(0xFF00C9B7)),
      ChartSeries(
        label: stats!['username'] ?? 'Игрок',
        days: theirDays,
        color: const Color(0xFF7C6FEE),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сравнение за неделю',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 14),
          WeeklyActivityChart(series: series),
          const SizedBox(height: 14),
          WeeklyChartLegend(series: series),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value, {
    Color valueColor = const Color(0xFF1B2430),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8E7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: const Color(0xFF9AAAAA),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementsSection() {
    final items = List<Map<String, dynamic>>.from(achievements?['items'] ?? []);
    final unlockedCount = achievements?['unlocked'] ?? 0;
    final total = achievements?['total'] ?? 0;

    final sorted = [...items]
      ..sort((a, b) {
        if (a['unlocked'] == b['unlocked']) return 0;
        return a['unlocked'] == true ? -1 : 1;
      });
    final visible = sorted.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Достижения',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF1B2430),
              ),
            ),
            Text(
              '$unlockedCount / $total',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                color: const Color(0xFF00A896),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (int row = 0; row < (visible.length / 4).ceil(); row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int col = 0; col < 4; col++) ...[
                if (col > 0) const SizedBox(width: 10),
                Expanded(
                  child: row * 4 + col < visible.length
                      ? _achievementBadge(visible[row * 4 + col])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _achievementBadge(Map<String, dynamic> item) {
    final unlocked = item['unlocked'] == true;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AchievementDetailScreen(item: item),
        ),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => AchievementBadge(
              icon: item['icon'] as String,
              style: item['style'] as String,
              unlocked: unlocked,
              size: constraints.maxWidth,
              seed: item['code'] as String?,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['title'],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8.5,
              color: unlocked
                  ? const Color(0xFF5C6B73)
                  : const Color(0xFF9AAAAA),
            ),
          ),
        ],
      ),
    );
  }
}
