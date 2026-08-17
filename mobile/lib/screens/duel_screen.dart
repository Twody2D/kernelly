import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/option_card.dart';
import 'package:mobile/widgets/primary_button.dart';

/// Спринт из фиксированного набора упражнений (см. /duels/{id}/exercises) —
/// структура прохождения скопирована с ReviewScreen, но дополнительно
/// считает время секундомером и в конце шлёт итог на submit_duel_result,
/// который сам определяет победителя, если соперник уже сдал свой результат.
class DuelScreen extends StatefulWidget {
  final int duelId;
  final String opponentName;

  const DuelScreen({
    super.key,
    required this.duelId,
    required this.opponentName,
  });

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> exercises = [];
  bool loading = true;
  int currentIndex = 0;
  String? selectedAnswer;
  bool? isCorrect;
  String? correctAnswer;
  int correctCount = 0;
  bool checking = false;
  bool finished = false;
  Map<String, dynamic>? duelResult;
  final _stopwatch = Stopwatch();
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
    final data = await fetchDuelExercises(currentUserId, widget.duelId);
    if (!mounted) return;
    setState(() {
      exercises = data;
      loading = false;
    });
    _stopwatch.start();
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
      correctAnswer = result['correct_answer'] as String?;
      if (correct) correctCount++;
      checking = false;
    });
  }

  Future<void> _next() async {
    if (currentIndex + 1 >= exercises.length) {
      _stopwatch.stop();
      final result = await submitDuelResult(
        currentUserId,
        widget.duelId,
        correctCount,
        _stopwatch.elapsedMilliseconds,
      );
      if (!mounted) return;
      setState(() {
        finished = true;
        duelResult = result;
      });
      return;
    }
    _terminalController.clear();
    setState(() {
      currentIndex++;
      selectedAnswer = null;
      isCorrect = null;
      correctAnswer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (finished) {
      return _finishedView();
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
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF4B4B)),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '\$ дуэль · ${widget.opponentName}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFFFF4B4B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exercise['question'] as String,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 21,
                color: const Color(0xFF1B2430),
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
                            : const Color(0xFFFFEAEA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      width: double.infinity,
                      child: Text(
                        isCorrect! ? 'Правильно!' : 'Неверно',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w600,
                          color: isCorrect!
                              ? const Color(0xFF2E6E00)
                              : const Color(0xFFB33A3A),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -10,
                      top: -20,
                      bottom: -20,
                      child: SizedBox(
                        width: 100,
                        child: Lottie.asset(
                          key: ValueKey(currentIndex),
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
              PrimaryButton(text: 'Дальше', onPressed: _next),
          ],
        ),
      ),
    );
  }

  Widget _finishedView() {
    final result = duelResult!;
    final opponentFinished = result['opponent_finished'] == true;
    final isMeWinner = result['is_me_winner'];
    final coresAwarded = result['cores_awarded'] as int?;
    final timeSec = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    String title;
    Color color;
    if (!opponentFinished) {
      title = 'Результат отправлен';
      color = const Color(0xFF00A896);
    } else if (isMeWinner == true) {
      title = 'Победа! 🏆';
      color = const Color(0xFF58CC02);
    } else if (isMeWinner == false) {
      title = 'Соперник оказался быстрее';
      color = const Color(0xFFB33A3A);
    } else {
      title = 'Ничья';
      color = const Color(0xFF5C6B73);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$correctCount из ${exercises.length} верно · $timeSec с',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    color: const Color(0xFF5C6B73),
                  ),
                ),
                if (!opponentFinished) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ждём, пока ${widget.opponentName} сыграет свой спринт',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: const Color(0xFF5C6B73),
                    ),
                  ),
                ],
                if (opponentFinished && coresAwarded != null && isMeWinner == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    '📦 +$coresAwarded ядер',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF3F9200),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Готово',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
