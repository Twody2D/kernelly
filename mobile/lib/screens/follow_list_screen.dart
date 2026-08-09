import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/user_profile_screen.dart';
import 'package:mobile/widgets/follow_user_row.dart';

enum FollowListMode { followers, following }

/// Список подписчиков или подписок любого пользователя (свои по умолчанию),
/// с возможностью подписаться/отписаться прямо отсюда — от лица того, кто
/// сейчас смотрит, а не владельца списка.
class FollowListScreen extends StatefulWidget {
  final FollowListMode mode;
  final int userId;
  final String? ownerUsername;

  FollowListScreen({
    super.key,
    required this.mode,
    int? userId,
    this.ownerUsername,
  }) : userId = userId ?? currentUserId;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  final Set<int> _pending = {};

  bool get _isOwnList => widget.userId == currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.mode == FollowListMode.followers
          ? await fetchFollowers(widget.userId, viewerId: currentUserId)
          : await fetchFollowing(widget.userId, viewerId: currentUserId);
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
    final isFollowing = user['is_following'] == true;
    setState(() => _pending.add(id));
    try {
      if (isFollowing) {
        await unfollowUser(currentUserId, id);
      } else {
        await followUser(currentUserId, id);
      }
      if (!mounted) return;
      setState(() {
        // из своего списка подписок при отписке строку убираем — она больше
        // не относится к «на кого я подписан»; в остальных случаях (чужой
        // список или отписка от подписчика) просто меняем состояние кнопки
        if (_isOwnList && widget.mode == FollowListMode.following && isFollowing) {
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
    final baseTitle = widget.mode == FollowListMode.followers
        ? 'Подписчики'
        : 'Подписки';
    final title = widget.ownerUsername == null
        ? baseTitle
        : '$baseTitle ${widget.ownerUsername}';

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
                              _isOwnList
                                  ? (widget.mode == FollowListMode.followers
                                      ? 'Пока никто не подписан на тебя'
                                      : 'Ты пока ни на кого не подписан')
                                  : (widget.mode == FollowListMode.followers
                                      ? 'У ${widget.ownerUsername ?? 'него'} пока нет подписчиков'
                                      : '${widget.ownerUsername ?? 'Он'} пока ни на кого не подписан'),
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
                            final isSelf = user['id'] == currentUserId;
                            final isFollowing = user['is_following'] == true;
                            return FollowUserRow(
                              username: user['username'] as String? ?? 'Игрок',
                              avatar: user['avatar'] as String?,
                              isFollowing: isFollowing,
                              isPending: _pending.contains(user['id']),
                              isSelf: isSelf,
                              onToggleFollow: () => _toggleFollow(user),
                              subtitle: isSelf
                                  ? null
                                  : (user['is_friend'] == true
                                      ? 'друзья'
                                      : null),
                              onTap: isSelf
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserProfileScreen(
                                          userId: user['id'] as int,
                                          username:
                                              user['username'] as String? ??
                                              'Игрок',
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
