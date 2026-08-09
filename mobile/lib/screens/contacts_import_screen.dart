import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/screens/user_profile_screen.dart';
import 'package:mobile/widgets/follow_user_row.dart';

enum _ImportState { checking, denied, loading, loaded, error }

/// Нормализует номер до последних 10 цифр — так же, как бэкенд, чтобы
/// сопоставление номеров из книги контактов с ответом /contacts-match
/// совпадало независимо от префикса кода страны.
String? _phoneSuffix(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) return null;
  return digits.substring(digits.length - 10);
}

/// Импорт контактов телефона: находит среди них тех, кто уже в Kernelly (по
/// привязанному номеру телефона), и предлагает пригласить остальных.
class ContactsImportScreen extends StatefulWidget {
  const ContactsImportScreen({super.key});

  @override
  State<ContactsImportScreen> createState() => _ContactsImportScreenState();
}

class _ContactsImportScreenState extends State<ContactsImportScreen> {
  _ImportState _state = _ImportState.checking;
  List<Map<String, dynamic>> _matched = [];
  List<String> _unmatchedNames = [];
  final Set<int> _pending = {};
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    fetchUser(currentUserId)
        .then((user) {
          if (mounted) setState(() => _myUsername = user['username'] as String?);
        })
        .catchError((e) {
          debugPrint('Ошибка загрузки профиля: $e');
        });

    var status = await Permission.contacts.status;
    if (status.isDenied) {
      status = await Permission.contacts.request();
    }
    if (!mounted) return;

    if (!status.isGranted) {
      setState(() => _state = _ImportState.denied);
      return;
    }

    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _state = _ImportState.loading);
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      final allPhones = <String>[];
      final contactSuffixes = <String, Set<String>>{};
      for (final contact in contacts) {
        final name = contact.displayName.trim();
        if (name.isEmpty || contact.phones.isEmpty) continue;
        final suffixes = <String>{};
        for (final phone in contact.phones) {
          allPhones.add(phone.number);
          final suffix = _phoneSuffix(phone.number);
          if (suffix != null) suffixes.add(suffix);
        }
        if (suffixes.isNotEmpty) {
          contactSuffixes.putIfAbsent(name, () => {}).addAll(suffixes);
        }
      }

      final matched = allPhones.isEmpty
          ? <Map<String, dynamic>>[]
          : await matchContacts(currentUserId, allPhones);

      final matchedSuffixes = matched
          .map((u) => u['phone'] as String?)
          .whereType<String>()
          .map(_phoneSuffix)
          .whereType<String>()
          .toSet();

      final unmatched = contactSuffixes.entries
          .where((e) => e.value.intersection(matchedSuffixes).isEmpty)
          .map((e) => e.key)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _matched = matched;
        _unmatchedNames = unmatched;
        _state = _ImportState.loaded;
      });
    } catch (e) {
      debugPrint('Ошибка импорта контактов: $e');
      if (!mounted) return;
      setState(() => _state = _ImportState.error);
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

  void _invite(String name) {
    Clipboard.setData(ClipboardData(text: 'Найди меня в Kernelly: @${_myHandle()}'));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Ссылка скопирована, отправь её $name',
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

  String _myHandle() => _myUsername ?? 'гость';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
        title: Text(
          'Контакты',
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
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_state) {
      case _ImportState.checking:
      case _ImportState.loading:
        return const Center(child: CircularProgressIndicator());
      case _ImportState.denied:
        return _permissionDenied();
      case _ImportState.error:
        return _errorState();
      case _ImportState.loaded:
        return _results();
    }
  }

  Widget _permissionDenied() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.contacts_rounded,
            size: 48,
            color: Color(0xFFC2CDCD),
          ),
          const SizedBox(height: 16),
          Text(
            'Нужен доступ к контактам',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: const Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Разреши доступ к контактам в настройках телефона, чтобы найти друзей, которые уже играют в Kernelly',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF5C6B73),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: openAppSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9B7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Открыть настройки',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Не удалось загрузить контакты',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadContacts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9B7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Повторить',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results() {
    if (_matched.isEmpty && _unmatchedNames.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Center(
          child: Text(
            'Среди контактов с номерами телефонов никого не нашли',
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        if (_matched.isNotEmpty) ...[
          _sectionLabel('УЖЕ В KERNELLY'),
          for (int i = 0; i < _matched.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _matchedRow(_matched[i]),
          ],
        ],
        if (_matched.isNotEmpty && _unmatchedNames.isNotEmpty)
          const SizedBox(height: 20),
        if (_unmatchedNames.isNotEmpty) ...[
          _sectionLabel('ПРИГЛАСИТЬ'),
          for (int i = 0; i < _unmatchedNames.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _inviteRow(_unmatchedNames[i]),
          ],
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10.5,
          color: const Color(0xFF00A896),
        ),
      ),
    );
  }

  Widget _matchedRow(Map<String, dynamic> user) {
    final username = user['username'] as String? ?? 'Игрок';
    final isFollowing = user['is_following'] == true;
    return FollowUserRow(
      username: username,
      avatar: user['avatar'] as String?,
      isFollowing: isFollowing,
      isPending: _pending.contains(user['id']),
      onToggleFollow: () => _toggleFollow(user),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: user['id'] as int,
            username: username,
            initialIsFollowing: isFollowing,
          ),
        ),
      ),
    );
  }

  Widget _inviteRow(String name) {
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
              color: Color(0xFFE7EEEE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF9AAAAA),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
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
              onPressed: () => _invite(name),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00A896),
                side: const BorderSide(color: Color(0xFF00C9B7)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Пригласить',
                style: TextStyle(
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
