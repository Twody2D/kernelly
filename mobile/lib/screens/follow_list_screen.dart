import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/user_profile_screen.dart';
import 'package:mobile/widgets/follow_user_row.dart';

enum FollowListMode { followers, following }

/// Список подписчиков или подписок текущего пользователя, с возможностью
/// подписаться/отписаться прямо отсюда.
class FollowListScreen extends StatefulWidget {
  final FollowListMode mode;

  const FollowListScreen({super.key, required this.mode});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  final Set<int> _pending = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.mode == FollowListMode.followers
          ? await fetchFollowers(currentUserId)
          : await fetchFollowing(currentUserId);
      if (!mounted) return;
      setState(() {
        users = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки списка: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final id = user['id'] as int;
    // в /following поле называется is_friend (взаимность), а не is_following —
    // в этом списке мы и так подписаны на всех, кроме случая /followers
    final isFollowing = widget.mode == FollowListMode.following
        ? true
        : user['is_following'] == true;
    setState(() => _pending.add(id));
    try {
      if (isFollowing) {
        await unfollowUser(currentUserId, id);
      } else {
        await followUser(currentUserId, id);
      }
      if (!mounted) return;
      setState(() {
        if (widget.mode == FollowListMode.following) {
          users.removeWhere((u) => u['id'] == id);
        } else {
          user['is_following'] = !isFollowing;
        }
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
    final title = widget.mode == FollowListMode.followers
        ? 'Подписчики'
        : 'Подписки';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          title,
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
                  child: users.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Center(
                            child: Text(
                              widget.mode == FollowListMode.followers
                                  ? 'Пока никто не подписан на тебя'
                                  : 'Ты пока ни на кого не подписан',
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
                          itemCount: users.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isFollowing =
                                widget.mode == FollowListMode.following
                                ? true
                                : user['is_following'] == true;
                            return FollowUserRow(
                              username: user['username'] as String? ?? 'Игрок',
                              avatar: user['avatar'] as String?,
                              isFollowing: isFollowing,
                              isPending: _pending.contains(user['id']),
                              onToggleFollow: () => _toggleFollow(user),
                              subtitle: user['is_friend'] == true
                                  ? 'друзья'
                                  : null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    userId: user['id'] as int,
                                    username:
                                        user['username'] as String? ?? 'Игрок',
                                    initialIsFollowing: isFollowing,
                                  ),
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
