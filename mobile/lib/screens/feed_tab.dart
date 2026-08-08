import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/friend_search_screen.dart';
import 'package:mobile/widgets/achievement_badge.dart';

/// Вкладка «Новости»: лента активности друзей — достижения, серии и посты
/// от тех, на кого подписан пользователь, плюс его собственные.
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => FeedTabState();
}

class FeedTabState extends State<FeedTab> {
  final _postController = TextEditingController();
  List<Map<String, dynamic>> events = [];
  bool loading = true;
  bool posting = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await fetchFeed(currentUserId);
      if (!mounted) return;
      setState(() {
        events = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки ленты: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _submitPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty || posting) return;
    setState(() => posting = true);
    try {
      await createPost(currentUserId, text);
      _postController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await load();
    } catch (e) {
      debugPrint('Ошибка публикации: $e');
    } finally {
      if (mounted) setState(() => posting = false);
    }
  }

  Future<void> _openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendSearchScreen()),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          'Новости',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: const Color(0xFF1B2430),
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(
              left: 8,
              right: 20,
              top: 8,
              bottom: 8,
            ),
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF5C6B73),
            ),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _composer(),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: load,
                          child: events.isEmpty
                              ? ListView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ),
                                  children: [
                                    const SizedBox(height: 60),
                                    Text(
                                      'Пока тихо. Подпишись на друзей — и увидишь их успехи здесь.',
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
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    20,
                                  ),
                                  itemCount: events.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _eventCard(events[index]),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              controller: _postController,
              maxLength: 200,
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
                hintText: 'Поделись новостью...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: const Color(0xFF9AAAAA),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _submitPost(),
            ),
          ),
          IconButton(
            onPressed: posting ? null : _submitPost,
            icon: posting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Color(0xFF00A896)),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final user = event['user'] as Map<String, dynamic>;
    final username = user['username'] as String? ?? 'Игрок';
    // бэкенд отдаёт naive UTC-время без суффикса — достраиваем 'Z', иначе Dart
    // примет его за локальное и сдвинет разницу на локальный часовой пояс
    final timeLabel = _relativeTime(DateTime.parse('${event['created_at']}Z'));

    if (event['type'] == 'achievement') {
      final achievement = event['achievement'] as Map<String, dynamic>;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            AchievementBadge(
              icon: achievement['icon'] as String,
              style: achievement['style'] as String,
              unlocked: true,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13.5,
                        color: const Color(0xFF1B2430),
                      ),
                      children: [
                        TextSpan(
                          text: username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' получил(а) достижение '),
                        TextSpan(
                          text: achievement['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
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
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7F4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF00A896),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                username,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: const Color(0xFF1B2430),
                ),
              ),
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          Text(
            event['text'] as String,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
              color: const Color(0xFF1B2430),
            ),
          ),
        ],
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
}
