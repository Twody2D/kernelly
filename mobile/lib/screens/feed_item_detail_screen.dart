import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/avatars.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/user_profile_screen.dart';
import 'package:mobile/widgets/achievement_badge.dart';

/// Отдельный элемент ленты с комментариями — пост или разблокировка
/// достижения, открывается по тапу на карточку в ленте. Лайк и добавление
/// комментария работают прямо здесь и сразу отражаются в счётчиках карточки.
class FeedItemDetailScreen extends StatefulWidget {
  final String targetType;
  final int targetId;

  const FeedItemDetailScreen({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  State<FeedItemDetailScreen> createState() => _FeedItemDetailScreenState();
}

class _FeedItemDetailScreenState extends State<FeedItemDetailScreen> {
  final _commentController = TextEditingController();
  Map<String, dynamic>? item;
  List<Map<String, dynamic>> comments = [];
  bool loading = true;
  bool liking = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        fetchFeedItem(widget.targetType, widget.targetId, currentUserId),
        fetchFeedComments(widget.targetType, widget.targetId, currentUserId),
      ]);
      if (!mounted) return;
      setState(() {
        item = results[0] as Map<String, dynamic>;
        comments = results[1] as List<Map<String, dynamic>>;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки новости: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _toggleLike() async {
    if (liking || item == null) return;
    setState(() => liking = true);
    try {
      final result = await toggleFeedLike(
        widget.targetType,
        widget.targetId,
        currentUserId,
      );
      if (!mounted) return;
      setState(() {
        item!['liked_by_me'] = result['liked'];
        item!['like_count'] = result['like_count'];
        liking = false;
      });
    } catch (e) {
      debugPrint('Ошибка лайка: $e');
      if (mounted) setState(() => liking = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await addFeedComment(
        widget.targetType,
        widget.targetId,
        currentUserId,
        text,
      );
      _commentController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await _load();
    } catch (e) {
      debugPrint('Ошибка комментария: $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _openProfile(Map<String, dynamic> user) {
    final id = user['id'] as int;
    if (id == currentUserId) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: id,
          username: user['username'] as String? ?? 'Игрок',
          initialIsFollowing: user['is_following'] == true,
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return '${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          'Новость',
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
          : item == null
              ? Center(
                  child: Text(
                    'Не удалось загрузить новость',
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
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              children: [
                                _itemCard(),
                                const SizedBox(height: 16),
                                Text(
                                  comments.isEmpty
                                      ? 'Комментариев пока нет'
                                      : 'Комментарии (${comments.length})',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF9AAAAA),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (final comment in comments) ...[
                                  _commentRow(comment),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            ),
                          ),
                          _composer(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _avatar(Map<String, dynamic> user, {double size = 36}) {
    final (_, icon, fg, bg) = avatarByCode(user['avatar'] as String?);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: size * 0.55),
    );
  }

  Widget _itemCard() {
    final user = item!['user'] as Map<String, dynamic>;
    final username = user['username'] as String? ?? 'Игрок';
    final timeLabel = _relativeTime(DateTime.parse('${item!['created_at']}Z'));
    final likedByMe = item!['liked_by_me'] == true;
    final isAchievement = item!['type'] == 'achievement';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _openProfile(user),
                child: _avatar(user),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openProfile(user),
                  child: Text(
                    username,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: const Color(0xFF1B2430),
                    ),
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10.5,
                  color: const Color(0xFF9AAAAA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAchievement) ...[
            Builder(
              builder: (context) {
                final achievement = item!['achievement'] as Map<String, dynamic>;
                return Row(
                  children: [
                    AchievementBadge(
                      icon: achievement['icon'] as String,
                      style: achievement['style'] as String,
                      unlocked: true,
                      size: 48,
                      seed: achievement['code'] as String?,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            color: const Color(0xFF1B2430),
                          ),
                          children: [
                            const TextSpan(text: 'Получил(а) достижение '),
                            TextSpan(
                              text: achievement['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else
            Text(
              item!['text'] as String,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                height: 1.4,
                color: const Color(0xFF1B2430),
              ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleLike,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 22,
                    color: likedByMe ? const Color(0xFFFF4B4B) : const Color(0xFF9AAAAA),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item!['like_count']}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: likedByMe ? const Color(0xFFFF4B4B) : const Color(0xFF9AAAAA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentRow(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>;
    final username = user['username'] as String? ?? 'Игрок';
    final timeLabel = _relativeTime(DateTime.parse('${comment['created_at']}Z'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openProfile(user),
            child: _avatar(user, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(user),
                      child: Text(
                        username,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: const Color(0xFF1B2430),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: const Color(0xFF9AAAAA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['text'] as String,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    height: 1.35,
                    color: const Color(0xFF1B2430),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9F9),
        border: Border(top: BorderSide(color: const Color(0xFFE7EEEE))),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLength: 300,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: const Color(0xFF1B2430),
                ),
                decoration: InputDecoration(
                  hintText: 'Написать комментарий...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: const Color(0xFF9AAAAA),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            IconButton(
              onPressed: sending ? null : _submitComment,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Color(0xFF00A896)),
            ),
          ],
        ),
      ),
    );
  }
}
