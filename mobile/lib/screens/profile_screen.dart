import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/settings_screen.dart';
import 'package:mobile/screens/register_prompt_screen.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/achievement_badge.dart';

const _months = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? stats;
  Map<String, dynamic>? activity;
  Map<String, dynamic>? achievements;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        fetchUserStats(currentUserId),
        fetchUserActivity(currentUserId),
        fetchUserAchievements(currentUserId),
      ]);
      setState(() {
        stats = results[0];
        activity = results[1];
        achievements = results[2];
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
      setState(() => loading = false);
    }
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _memberSince(String? isoDate) {
    if (isoDate == null) return '';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return '';
    return 'в Kernelly с ${_months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F9F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (stats == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F9F9),
        appBar: _appBar(),
        body: Center(
          child: Text(
            'Не удалось загрузить профиль',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Color(0xFF5C6B73),
            ),
          ),
        ),
      );
    }

    if (stats!['auth_provider'] == 'guest') {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F9F9),
        appBar: _appBar(),
        body: Center(
          child: RegisterPromptContent(
            title: 'Сохрани свой прогресс',
            subtitle:
                'Сейчас прогресс привязан только к этому устройству. Зарегистрируйся, чтобы не потерять его.',
            onSignedIn: load,
          ),
        ),
      );
    }

    final accuracy = stats!['accuracy'];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: _appBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _banner(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statCard('ВСЕГО XP', _formatNumber(stats!['xp'])),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard('УРОКОВ', '${stats!['lessons_completed']}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  'ТОЧНОСТЬ',
                  accuracy == null ? '—' : '$accuracy%',
                  valueColor: accuracy == null
                      ? const Color(0xFFC2CDCD)
                      : const Color(0xFF58CC02),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _activityCard(),
          const SizedBox(height: 14),
          _achievementsSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF6F9F9),
      elevation: 0,
      title: Text(
        'Профиль',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: const Color(0xFF1B2430),
        ),
      ),
      actions: [
        IconButton(
          padding: const EdgeInsets.only(left: 8, right: 20, top: 8, bottom: 8),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF5C6B73)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                isGuest:
                    stats?['auth_provider'] == null ||
                    stats?['auth_provider'] == 'guest',
                email: stats?['email'] as String?,
                username: stats?['username'] as String?,
                avatar: stats?['avatar'] as String?,
                onProfileChanged: load,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner() {
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
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -14,
            child: Transform.rotate(
              angle: -8 * 3.1415926535 / 180,
              child: const Text(
                '</>',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: Color(0x1FFFFFFF),
                  height: 1.2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0x38FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.bottomCenter,
                  child: const Mascot(size: 52),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$ whoami',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: const Color(0xD9FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stats!['username'] ?? 'Гость',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Widget _activityCard() {
    final days = List<Map<String, dynamic>>.from(activity?['days'] ?? []);
    final totalXp = activity?['total_xp'] ?? 0;
    final maxXp = days.isEmpty
        ? 0
        : days.map((d) => d['xp'] as int).reduce((a, b) => a > b ? a : b);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Активность за неделю',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF1B2430),
                ),
              ),
              Text(
                '$totalXp XP',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: const Color(0xFF9AAAAA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 66,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  Expanded(
                    child: _activityBar(
                      days[i],
                      maxXp,
                      isToday: i == days.length - 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityBar(
    Map<String, dynamic> day,
    int maxXp, {
    required bool isToday,
  }) {
    final xp = day['xp'] as int;
    final parsed = DateTime.tryParse(day['date']);
    final label = parsed == null ? '' : _weekdays[parsed.weekday - 1];

    final ratio = maxXp == 0 ? 0.0 : xp / maxXp;
    final height = xp == 0 ? 8.0 : 8 + ratio * 38;

    Color color;
    if (xp == 0) {
      color = const Color(0xFFE7EEEE);
    } else if (ratio >= 0.75) {
      color = const Color(0xFF00C9B7);
    } else if (ratio >= 0.4) {
      color = const Color(0xFF8FE4DA);
    } else {
      color = const Color(0xFFCFEFEB);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9.5,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: isToday ? const Color(0xFF00A896) : const Color(0xFF9AAAAA),
          ),
        ),
      ],
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
      onTap: () => _showAchievementDetails(item),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => AchievementBadge(
              icon: item['icon'] as String,
              style: item['style'] as String,
              unlocked: unlocked,
              size: constraints.maxWidth,
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

  void _showAchievementDetails(Map<String, dynamic> item) {
    final unlocked = item['unlocked'] == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AchievementBadge(
              icon: item['icon'] as String,
              style: item['style'] as String,
              unlocked: unlocked,
              size: 84,
            ),
            const SizedBox(height: 16),
            Text(
              item['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 19,
                color: const Color(0xFF1B2430),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['description'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                height: 1.4,
                color: const Color(0xFF5C6B73),
              ),
            ),
            if (!unlocked) ...[
              const SizedBox(height: 10),
              Text(
                'Ещё не открыто',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.5,
                  color: const Color(0xFF9AAAAA),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
