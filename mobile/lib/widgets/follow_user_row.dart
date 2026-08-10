import 'package:flutter/material.dart';
import 'package:mobile/services/avatars.dart';

/// Строка одного пользователя в списках подписок/подписчиков/поиска —
/// аватар, ник, опциональная подпись и кнопка подписки.
class FollowUserRow extends StatelessWidget {
  final String username;
  final String? avatar;
  final bool isFollowing;
  final bool isPending;
  final String? subtitle;
  final VoidCallback onToggleFollow;
  final VoidCallback? onTap;
  final bool isSelf;
  final bool isOnline;

  const FollowUserRow({
    super.key,
    required this.username,
    required this.isFollowing,
    required this.isPending,
    required this.onToggleFollow,
    this.avatar,
    this.subtitle,
    this.onTap,
    this.isSelf = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: _content());
  }

  Widget _content() {
    final (_, icon, fg, bg) = avatarByCode(avatar);

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: fg, size: 20),
              ),
              if (isOnline)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF58CC02),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: const Color(0xFF1B2430),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10.5,
                      color: const Color(0xFF9AAAAA),
                    ),
                  ),
              ],
            ),
          ),
          if (isSelf)
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'Это вы',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: const Color(0xFF5C6B73),
                ),
              ),
            )
          else
            SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: isPending ? null : onToggleFollow,
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
