import 'package:flutter/material.dart';

/// Строка одного пользователя в списках подписок/подписчиков/поиска —
/// аватар-заглушка, ник, опциональная подпись и кнопка подписки.
class FollowUserRow extends StatelessWidget {
  final String username;
  final bool isFollowing;
  final bool isPending;
  final String? subtitle;
  final VoidCallback onToggleFollow;

  const FollowUserRow({
    super.key,
    required this.username,
    required this.isFollowing,
    required this.isPending,
    required this.onToggleFollow,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
