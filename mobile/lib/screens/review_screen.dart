import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/option_card.dart';
import 'package:mobile/widgets/primary_button.dart';
import 'package:mobile/screens/achievement_unlock_screen.dart';

/// Сессия повторения: набор упражнений из /review/session, собранных
/// алгоритмом Лейтнера по просроченным навыкам. В отличие от урока — без
/// истории, без блокировки разделов, только повторение того, что уже учили.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> exercises = [];
  bool loading = true;
  int currentIndex = 0;
  String? selectedAnswer;
  bool? isCorrect;
  bool isClose = false;
  String? correctAnswer;
  int attemptCount = 0;
  int correctCount = 0;
  bool checking = false;
  bool finished = false;
  int? xpEarned;
  List<Map<String, dynamic>> newAchievements = [];
  final _terminalController = TextEditingController();
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _load();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await fetchReviewSession(currentUserId);
    if (!mounted) return;
    setState(() {
      exercises = data;
      loading = false;
    });
  }

  void _chooseOption(String option) {
    setState(() => selectedAnswer = option);
  }

  void _checkAnswer() async {
    if (checking || isCorrect != null) return;
    setState(() => checking = true);

    final exercise = exercises[currentIndex];
    final result = await submitAnswer(
      exercise['id'],
      currentUserId,
      selectedAnswer!.trim(),
    );
    if (!mounted) return;

    final correct = result['correct'] == true;
    setState(() {
      isCorrect = correct;
      isClose = result['close'] == true;
      correctAnswer = result['correct_answer'] as String?;
      attemptCount++;
      if (correct) correctCount++;
      checking = false;
      newAchievements.addAll(
        List<Map<String, dynamic>>.from(result['new_achievements'] ?? []),
      );
    });
  }

  void _next() async {
    if (currentIndex + 1 >= exercises.length) {
      final xpResult = await awardXp(currentUserId, correctCount);
      if (!mounted) return;
      newAchievements.addAll(
        List<Map<String, dynamic>>.from(xpResult['new_achievements'] ?? []),
      );
      setState(() {
        finished = true;
        xpEarned = xpResult['xp'] as int;
      });
      return;
    }
    _terminalController.clear();
    setState(() {
      currentIndex++;
      selectedAnswer = null;
      isCorrect = null;
      isClose = false;
      correctAnswer = null;
    });
  }

  List<InlineSpan> _parseInlineCode(
    String text, {
    required TextStyle baseStyle,
  }) {
    final spans = <InlineSpan>[];
    final parts = text.split('`');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isCode = i.isOdd;
      spans.add(
        TextSpan(
          text: parts[i],
          style: isCode
              ? baseStyle.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w600,
                  fontSize: baseStyle.fontSize! - 2,
                  color: const Color(0xFF00A896),
                  backgroundColor: const Color(0xFFE0F7F4),
                )
              : baseStyle,
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (exercises.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F9F9),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF5C6B73)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedMascot(size: 96),
                const SizedBox(height: 16),
                Text(
                  'Пока нечего повторять — возвращайся позже',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: const Color(0xFF5C6B73),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (finished) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F9F9),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AnimatedMascot(size: 120),
                  const SizedBox(height: 20),
                  Text(
                    'Повторение пройдено',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: const Color(0xFF1B2430),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correctCount из ${exercises.length} верно · +${xpEarned == null ? 0 : correctCount * 10} XP',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      color: const Color(0xFF5C6B73),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Готово',
                      onPressed: () async {
                        if (newAchievements.isNotEmpty) {
                          final queued = newAchievements;
                          newAchievements = [];
                          await showAchievementUnlocks(context, queued);
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final exercise = exercises[currentIndex];
    final isTerminal = exercise['type'] == 'terminal';
    final options = isTerminal
        ? const <String>[]
        : List<String>.from(exercise['content']['options']);
    final progress =
        (currentIndex + (isCorrect != null ? 1 : 0)) / exercises.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF5C6B73)),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: const Color(0xFFE7EEEE),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9500)),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '\$ повторение',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFFFF9500),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: _parseInlineCode(
                  exercise['question'] as String,
                  baseStyle: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    color: const Color(0xFF1B2430),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isTerminal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2430),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      '\$',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF00C9B7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _terminalController,
                        enabled: isCorrect == null,
                        onChanged: _chooseOption,
                        autocorrect: false,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        cursorColor: const Color(0xFF00C9B7),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final option in options)
                OptionCard(
                  text: option,
                  onTap: () => _chooseOption(option),
                  locked: isCorrect != null,
                  state: isCorrect != null
                      ? (option == correctAnswer
                            ? OptionState.correct
                            : option == selectedAnswer
                            ? OptionState.incorrect
                            : OptionState.none)
                      : (option == selectedAnswer
                            ? OptionState.selected
                            : OptionState.none),
                ),
            const Spacer(),
            if (isCorrect != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                        left: 74,
                        right: 14,
                        top: 14,
                        bottom: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect!
                            ? const Color(0xFFEAF9DC)
                            : (isClose
                                  ? const Color(0xFFFFF3D6)
                                  : const Color(0xFFFFEAEA)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCorrect!
                                ? 'Правильно! +10 XP'
                                : (isClose
                                      ? 'Почти! Проверь регистр и пробелы'
                                      : 'Неверно'),
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w600,
                              color: isCorrect!
                                  ? const Color(0xFF2E6E00)
                                  : (isClose
                                        ? const Color(0xFF9A6B00)
                                        : const Color(0xFFB33A3A)),
                            ),
                          ),
                          if (!isCorrect! && correctAnswer != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Правильный ответ: $correctAnswer',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isClose
                                    ? const Color(0xFF9A6B00)
                                    : const Color(0xFFB33A3A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      left: -10,
                      top: -20,
                      bottom: -20,
                      child: SizedBox(
                        width: 100,
                        child: Lottie.asset(
                          key: ValueKey(attemptCount),
                          isCorrect!
                              ? 'assets/animations/success.json'
                              : 'assets/animations/error.json',
                          controller: _lottieController,
                          fit: BoxFit.contain,
                          onLoaded: (composition) {
                            _lottieController.duration = isCorrect!
                                ? composition.duration ~/ 2
                                : composition.duration;
                            _lottieController.forward(from: 0);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isCorrect == null)
              PrimaryButton(
                text: 'Проверить',
                enabled:
                    !checking &&
                    selectedAnswer != null &&
                    selectedAnswer!.trim().isNotEmpty,
                onPressed: _checkAnswer,
              )
            else
              PrimaryButton(text: 'Продолжить', onPressed: _next),
          ],
        ),
      ),
    );
  }
}
