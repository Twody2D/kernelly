import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/post_detail_screen.dart';

/// Уведомления о лайках и комментариях под своими постами — открывается по
/// колокольчику в ленте. Лайки одного поста агрегируются в одну строку с
/// растущим счётчиком, комментарии — отдельная строка на каждый.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await fetchNotifications(currentUserId);
      if (!mounted) return;
      setState(() {
        notifications = data;
        loading = false;
      });
      if (data.any((n) => n['read'] != true)) {
        await markNotificationsRead(currentUserId);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки уведомлений: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return '${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}';
  }

  String _textFor(Map<String, dynamic> n) {
    final actor = (n['actor'] as Map<String, dynamic>)['username'] as String? ?? 'Игрок';
    if (n['type'] == 'comment') {
      return '$actor оставил(а) комментарий под вашим постом';
    }
    final count = n['count'] as int? ?? 1;
    if (count <= 1) {
      return '$actor поставил(а) лайк под вашим постом';
    }
    return '$count пользователей поставили лайк под вашим постом';
  }

  Future<void> _openPost(Map<String, dynamic> n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(postId: n['post_id'] as int),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          'Уведомления',
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
                  child: notifications.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          children: [
                            const SizedBox(height: 80),
                            Text(
                              'Пока нет уведомлений.',
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
                          itemCount: notifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            final isComment = n['type'] == 'comment';
                            final unread = n['read'] != true;
                            final time = _relativeTime(
                              DateTime.parse('${n['updated_at']}Z'),
                            );
                            return GestureDetector(
                              onTap: () => _openPost(n),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: unread
                                      ? Border.all(
                                          color: const Color(0xFF00C9B7),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: isComment
                                            ? const Color(0xFFE0F7F4)
                                            : const Color(0xFFFFEAEA),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        isComment
                                            ? Icons.chat_bubble_rounded
                                            : Icons.favorite_rounded,
                                        size: 17,
                                        color: isComment
                                            ? const Color(0xFF00A896)
                                            : const Color(0xFFFF4B4B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _textFor(n),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13.5,
                                              height: 1.3,
                                              color: const Color(0xFF1B2430),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            time,
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
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
    );
  }
}
