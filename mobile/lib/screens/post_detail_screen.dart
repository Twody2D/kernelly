import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';

/// Отдельная новость из ленты с комментариями — открывается по тапу на
/// карточку поста. Лайк и добавление комментария работают прямо здесь и
/// сразу отражаются в счётчиках карточки.
class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  Map<String, dynamic>? post;
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
        fetchPost(widget.postId, currentUserId),
        fetchPostComments(widget.postId, currentUserId),
      ]);
      if (!mounted) return;
      setState(() {
        post = results[0] as Map<String, dynamic>;
        comments = results[1] as List<Map<String, dynamic>>;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки поста: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _toggleLike() async {
    if (liking || post == null) return;
    setState(() => liking = true);
    try {
      final result = await togglePostLike(widget.postId, currentUserId);
      if (!mounted) return;
      setState(() {
        post!['liked_by_me'] = result['liked'];
        post!['like_count'] = result['like_count'];
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
      await addPostComment(widget.postId, currentUserId, text);
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
          : post == null
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
                                _postCard(),
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

  Widget _postCard() {
    final user = post!['user'] as Map<String, dynamic>;
    final username = user['username'] as String? ?? 'Игрок';
    final timeLabel = _relativeTime(DateTime.parse('${post!['created_at']}Z'));
    final likedByMe = post!['liked_by_me'] == true;

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
            post!['text'] as String,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
              color: const Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: likedByMe ? const Color(0xFFFF4B4B) : const Color(0xFF9AAAAA),
                ),
                const SizedBox(width: 5),
                Text(
                  '${post!['like_count']}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: likedByMe ? const Color(0xFFFF4B4B) : const Color(0xFF9AAAAA),
                  ),
                ),
              ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                username,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF1B2430),
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
