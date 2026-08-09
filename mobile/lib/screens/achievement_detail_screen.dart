import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/widgets/achievement_badge.dart';

const _months = [
  'янв.',
  'февр.',
  'марта',
  'апр.',
  'мая',
  'июня',
  'июля',
  'авг.',
  'сент.',
  'окт.',
  'нояб.',
  'дек.',
];

/// Полноэкранное "окошко" достижения — открывается по тапу на медаль как в
/// профиле, так и в чужом профиле. Показывает дату разблокировки (или
/// заглушку для запертых) и позволяет скопировать хвастливую фразу.
class AchievementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const AchievementDetailScreen({super.key, required this.item});

  bool get _unlocked => item['unlocked'] == true;

  String get _title => item['title'] as String? ?? '';

  String get _description => item['description'] as String? ?? '';

  String? get _formattedDate {
    final iso = item['unlocked_at'] as String?;
    if (iso == null) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  void _share(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: 'Я получил достижение «$_title» в Kernelly! 🎉'),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Скопировано',
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
    final date = _formattedDate;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF5C6B73),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Color(0xFF5C6B73),
                    ),
                    onPressed: () => _share(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_unlocked) const _ConfettiFlourish(),
                              AchievementBadge(
                                icon: item['icon'] as String,
                                style: item['style'] as String,
                                unlocked: _unlocked,
                                size: 150,
                                seed: item['code'] as String?,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _unlocked
                                ? const Color(0xFFEAF9DC)
                                : const Color(0xFFE7EEEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _unlocked
                                ? date?.toUpperCase() ?? ''
                                : 'ЕЩЁ НЕ ОТКРЫТО',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.4,
                              color: _unlocked
                                  ? const Color(0xFF58CC02)
                                  : const Color(0xFFC2CDCD),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            color: const Color(0xFF1B2430),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            height: 1.4,
                            color: const Color(0xFF5C6B73),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Лёгкая статичная "конфетти"-россыпь позади медали — просто набор
/// цветных точек/полосок без физики, только для открытых достижений.
class _ConfettiFlourish extends StatelessWidget {
  const _ConfettiFlourish();

  static const _colors = [
    Color(0xFF00C9B7),
    Color(0xFFFFD98A),
    Color(0xFFFF9500),
    Color(0xFF58CC02),
    Color(0xFF00A896),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(220, 220),
      painter: _ConfettiPainter(_colors),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<Color> colors;

  _ConfettiPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(7);
    final paint = Paint();

    for (int i = 0; i < 14; i++) {
      final angle = (2 * pi / 14) * i + random.nextDouble() * 0.3;
      final radius = 88 + random.nextDouble() * 22;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      final color = colors[i % colors.length];
      paint.color = color.withValues(alpha: 0.85);

      if (i.isEven) {
        canvas.drawCircle(point, 4 + random.nextDouble() * 2, paint);
      } else {
        final rect = Rect.fromCenter(
          center: point,
          width: 7,
          height: 7,
        );
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle);
        canvas.translate(-point.dx, -point.dy);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
