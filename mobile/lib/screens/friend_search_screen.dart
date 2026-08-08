import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';

/// Поиск людей по нику и подписка на них — подписка одностороняя, как в
/// Instagram: подписался — видишь в ленте, согласие не требуется.
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> results = [];
  bool searching = false;
  final Set<int> _pending = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    setState(() => searching = true);
    try {
      final data = await searchUsers(currentUserId, query.trim());
      if (!mounted) return;
      setState(() {
        results = data;
        searching = false;
      });
    } catch (e) {
      debugPrint('Ошибка поиска пользователей: $e');
      if (!mounted) return;
      setState(() => searching = false);
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final id = user['id'] as int;
    setState(() => _pending.add(id));
    try {
      final isFollowing = user['is_following'] == true;
      if (isFollowing) {
        await unfollowUser(currentUserId, id);
      } else {
        await followUser(currentUserId, id);
      }
      if (!mounted) return;
      setState(() {
        user['is_following'] = !isFollowing;
        _pending.remove(id);
      });
    } catch (e) {
      debugPrint('Ошибка подписки: $e');
      if (!mounted) return;
      setState(() => _pending.remove(id));
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
          'Найти игроков',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: const Color(0xFF1B2430),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onChanged,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: const Color(0xFF1B2430),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Никнейм игрока',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        color: const Color(0xFF9AAAAA),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF5C6B73),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: searching
                      ? const Center(child: CircularProgressIndicator())
                      : results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Center(
                            child: Text(
                              _controller.text.trim().length < 2
                                  ? 'Введи хотя бы 2 буквы никнейма'
                                  : 'Никого не нашли',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: const Color(0xFF5C6B73),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) => _row(results[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> user) {
    final isFollowing = user['is_following'] == true;
    final isPending = _pending.contains(user['id']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7F4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF00A896),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user['username'] as String? ?? 'Игрок',
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
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: isPending ? null : () => _toggleFollow(user),
              style: OutlinedButton.styleFrom(
                foregroundColor: isFollowing
                    ? const Color(0xFF5C6B73)
                    : const Color(0xFF00A896),
                side: BorderSide(
                  color: isFollowing
                      ? const Color(0xFFC2CDCD)
                      : const Color(0xFF00C9B7),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isFollowing ? 'Отписаться' : 'Подписаться',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
