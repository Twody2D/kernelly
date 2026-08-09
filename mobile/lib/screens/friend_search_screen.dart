import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/follow_user_row.dart';

/// Поиск людей по нику и подписка на них — подписка одностороняя, как в
/// Instagram: подписался — видишь в ленте, согласие не требуется. Когда
/// поле поиска пустое, вместо результатов показываем ссылку на свой профиль,
/// импорт контактов (заглушка) и «вы можете их знать».
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

  String? _myUsername;
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    try {
      final results = await Future.wait([
        fetchUser(currentUserId),
        fetchSuggestions(currentUserId),
      ]);
      if (!mounted) return;
      setState(() {
        _myUsername =
            (results[0] as Map<String, dynamic>)['username'] as String?;
        _suggestions = results[1] as List<Map<String, dynamic>>;
        _loadingSuggestions = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки данных для поиска друзей: $e');
      if (!mounted) return;
      setState(() => _loadingSuggestions = false);
    }
  }

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

  Future<void> _toggleFollow(
    Map<String, dynamic> user, {
    required bool fromSuggestions,
  }) async {
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
        if (fromSuggestions && !isFollowing) {
          _suggestions.removeWhere((u) => u['id'] == id);
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

  void _copyProfileLink() {
    final handle = _myUsername ?? 'гость';
    Clipboard.setData(ClipboardData(text: 'Найди меня в Kernelly: @$handle'));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
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

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
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
    final query = _controller.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text(
          'Найти друзей',
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
                    onChanged: (value) {
                      setState(() {});
                      _onChanged(value);
                    },
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
                  child: query.length < 2
                      ? _defaultContent()
                      : _searchResults(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchResults() {
    if (searching) return const Center(child: CircularProgressIndicator());
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Center(
          child: Text(
            'Никого не нашли',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: const Color(0xFF5C6B73),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _userRow(results[index], fromSuggestions: false),
    );
  }

  Widget _defaultContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        GestureDetector(
          onTap: _copyProfileLink,
          child: _actionRow(
            icon: Icons.link_rounded,
            title: 'Ссылка на профиль',
            subtitle: 'скопировать и отправить другу',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _soon('Импорт контактов появится позже'),
          child: _actionRow(
            icon: Icons.contacts_rounded,
            title: 'Из контактов телефона',
            subtitle: 'скоро',
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ВЫ МОЖЕТЕ ИХ ЗНАТЬ',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10.5,
              color: const Color(0xFF00A896),
            ),
          ),
        ),
        if (_loadingSuggestions)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_suggestions.isEmpty)
          Text(
            'Пока нечего предложить — подпишись на кого-нибудь через поиск',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
              color: const Color(0xFF9AAAAA),
            ),
          )
        else
          for (int i = 0; i < _suggestions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _userRow(_suggestions[i], fromSuggestions: true),
          ],
      ],
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7F4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF00A896), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: const Color(0xFF1B2430),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10.5,
                    color: const Color(0xFF9AAAAA),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFFC2CDCD),
          ),
        ],
      ),
    );
  }

  Widget _userRow(Map<String, dynamic> user, {required bool fromSuggestions}) {
    final mutual = user['mutual'] as int?;
    return FollowUserRow(
      username: user['username'] as String? ?? 'Игрок',
      isFollowing: user['is_following'] == true,
      isPending: _pending.contains(user['id']),
      onToggleFollow: () =>
          _toggleFollow(user, fromSuggestions: fromSuggestions),
      subtitle: mutual == null ? null : '$mutual общих подписок',
    );
  }
}
