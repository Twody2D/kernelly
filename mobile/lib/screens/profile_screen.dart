import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/services/avatars.dart';
import 'package:mobile/screens/settings_screen.dart';
import 'package:mobile/screens/register_prompt_screen.dart';
import 'package:mobile/screens/friend_search_screen.dart';
import 'package:mobile/screens/follow_list_screen.dart';
import 'package:mobile/screens/achievement_detail_screen.dart';
import 'package:mobile/screens/achievements_catalog_screen.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/achievement_badge.dart';
import 'package:mobile/widgets/weekly_activity_chart.dart';
import 'package:mobile/theme/app_theme.dart';

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
    final colors = context.colors;
    if (loading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (stats == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: _appBar(context),
        body: Center(
          child: Text(
            'Не удалось загрузить профиль',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (stats!['auth_provider'] == 'guest') {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: _appBar(context),
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
      backgroundColor: colors.background,
      appBar: _appBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _banner(),
          const SizedBox(height: 14),
          _socialRow(),
          const SizedBox(height: 20),
          _activityCard(),
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
          _achievementsSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.background,
      elevation: 0,
      title: Text(
        'Профиль',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: colors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          padding: const EdgeInsets.only(left: 8, right: 20, top: 8, bottom: 8),
          constraints: const BoxConstraints(),
          icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
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

  Widget _socialRow() {
    final followers = stats!['followers_count'] ?? 0;
    final following = stats!['following_count'] ?? 0;

    return Column(
      children: [
        Row(
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
              child: _socialCount(
                'Подписки',
                following,
                FollowListMode.following,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _addFriendsButton()),
            const SizedBox(width: 10),
            _qrButton(),
          ],
        ),
      ],
    );
  }

  Widget _socialCount(String label, int count, FollowListMode mode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FollowListScreen(mode: mode)),
      ).then((_) => load()),
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

  Widget _addFriendsButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FriendSearchScreen()),
      ).then((_) => load()),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFAEE5DE), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF00A896),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'ДОБАВИТЬ ДРУЗЕЙ',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFF00A896),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrButton() {
    return GestureDetector(
      onTap: _showQrSheet,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFAEE5DE), width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.qr_code_rounded,
          color: Color(0xFF00A896),
          size: 22,
        ),
      ),
    );
  }

  void _showQrSheet() {
    final username = stats!['username'] as String? ?? 'Гость';
    final avatar = avatarByCode(stats!['avatar'] as String?);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QrSheet(username: username, avatar: avatar),
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
    final series = [
      ChartSeries(label: 'Вы', days: days, color: const Color(0xFF00C9B7)),
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
            'Активность за неделю',
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
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AchievementsCatalogScreen(
                    items: items,
                    unlockedCount: unlockedCount,
                    total: total,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$unlockedCount / $total',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: const Color(0xFF00A896),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Color(0xFF00A896),
                  ),
                ],
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

/// Модалка с QR-кодом профиля — по нему друг может добавить пользователя,
/// отсканировав камерой (сканер пока не реализован, только генерация).
class _QrSheet extends StatelessWidget {
  final String username;
  final (String, IconData, Color, Color) avatar;

  const _QrSheet({required this.username, required this.avatar});

  String get _profileLink => 'kernelly://u/$username';

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _profileLink));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Ссылка скопирована',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          backgroundColor: const Color(0xFF1B2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _shareLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _profileLink));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Ссылка скопирована — вставь её в сообщение другу',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          backgroundColor: const Color(0xFF1B2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final (_, icon, fg, bg) = avatar;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(
                    username,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: const Color(0xFF1B2430),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9AAAAA),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: const Color(0xFF9AAAAA),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7EEEE), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: _profileLink,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1B2430),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1B2430),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: fg, size: 26),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _qrAction(
                    icon: Icons.ios_share_rounded,
                    label: 'Отправить ссылку',
                    onTap: () => _shareLink(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _qrAction(
                    icon: Icons.link_rounded,
                    label: 'Скопировать ссылку',
                    onTap: () => _copyLink(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00A896), size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: const Color(0xFF00A896),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

