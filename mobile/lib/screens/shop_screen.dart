import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/theme/app_theme.dart';

// Должны совпадать с MAX_STREAK_FREEZES/STREAK_FREEZE_PRICE_CORES в backend/app/main.py —
// используются только для подписи и отключения кнопки, сама проверка на сервере.
const _maxStreakFreezes = 3;
const _streakFreezePriceCores = 40;

/// Магазин — открывается тапом по ядрам на вкладке «Путь». Товары — плитки в
/// сетке (сейчас только заряд заморозки streak), а не строчки как в
/// Настройках, чтобы это ощущалось отдельным разделом «трат», а не ещё одной
/// страницей параметров. Со временем сюда добавятся другие товары за ядра —
/// каждый как своя плитка в той же сетке.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool shield = false;
  int cores = 0;
  int streakFreezes = 0;
  bool loading = true;
  bool purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => shield = prefs.getBool(PrefKeys.streakShield) ?? false);
    }
    try {
      final stats = await fetchUserStats(currentUserId);
      if (!mounted) return;
      setState(() {
        shield = stats['streak_shield_enabled'] as bool? ?? shield;
        cores = stats['cores'] as int? ?? 0;
        streakFreezes = stats['streak_freezes'] as int? ?? 0;
        loading = false;
      });
    } catch (e) {
      debugPrint('Не удалось загрузить магазин: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _onShieldChanged(bool value) async {
    setState(() => shield = value);
    (await SharedPreferences.getInstance()).setBool(PrefKeys.streakShield, value);
    try {
      await updateStreakShield(currentUserId, value);
    } catch (e) {
      debugPrint('Не удалось синхронизировать защиту streak: $e');
    }
  }

  Future<void> _purchaseFreeze() async {
    if (streakFreezes >= _maxStreakFreezes || purchasing) return;
    setState(() => purchasing = true);
    try {
      final result = await purchaseStreakFreeze(currentUserId);
      if (!mounted) return;
      setState(() {
        cores = result['cores'] as int;
        streakFreezes = result['streak_freezes'] as int;
        purchasing = false;
      });
    } on InsufficientCoresException {
      if (!mounted) return;
      setState(() => purchasing = false);
      _showSnackBar('Не хватает ядер — нужно $_streakFreezePriceCores');
    } on StreakFreezesMaxedException {
      if (!mounted) return;
      setState(() => purchasing = false);
      _showSnackBar('Уже максимум зарядов ($_maxStreakFreezes)');
    } catch (e) {
      if (!mounted) return;
      setState(() => purchasing = false);
      _showSnackBar('Не удалось купить, попробуй ещё раз');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          'Магазин',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.accent.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        '$cores',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: colors.accentDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ядер',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: colors.accentDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                  children: [
                    _ShopTile(
                      emoji: '🧊',
                      title: 'Заморозка streak',
                      owned: '$streakFreezes из $_maxStreakFreezes',
                      priceLabel: streakFreezes >= _maxStreakFreezes
                          ? 'максимум'
                          : '$_streakFreezePriceCores 📦',
                      disabled: streakFreezes >= _maxStreakFreezes ||
                          cores < _streakFreezePriceCores,
                      loading: purchasing,
                      onTap: _purchaseFreeze,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Автоиспользование заморозки',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'тратить заряды автоматически, если пропустишь день',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: shield,
                        onChanged: _onShieldChanged,
                        activeTrackColor: colors.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String owned;
  final String priceLabel;
  final bool disabled;
  final bool loading;
  final VoidCallback onTap;

  const _ShopTile({
    required this.emoji,
    required this.title,
    required this.owned,
    required this.priceLabel,
    required this.disabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: disabled || loading ? null : onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                color: colors.accentBg,
                child: Text(emoji, style: const TextStyle(fontSize: 46)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    owned,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: disabled ? colors.lockedBg : colors.accent,
                        borderRadius: BorderRadius.circular(10),
                        border: disabled ? Border.all(color: colors.border, width: 1.5) : null,
                      ),
                      child: loading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: disabled ? colors.textSecondary : Colors.white,
                              ),
                            )
                          : Text(
                              priceLabel,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                                color: disabled ? colors.textSecondary : Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
