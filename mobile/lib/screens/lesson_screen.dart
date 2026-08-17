import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/notifications_service.dart';
import 'package:mobile/services/user_prefs.dart';
import 'package:mobile/widgets/animated_mascot.dart';
import 'package:mobile/widgets/mascot.dart';
import 'package:mobile/widgets/option_card.dart';
import 'package:mobile/widgets/primary_button.dart';
import 'package:mobile/screens/section_complete_screen.dart';
import 'package:mobile/screens/achievement_unlock_screen.dart';
import 'package:mobile/screens/chest_reward_screen.dart';
import 'package:mobile/theme/app_theme.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;
  final String sectionTitle;

  const LessonScreen({
    super.key,
    required this.lessonId,
    required this.sectionTitle,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> exercises = [];
  Map<String, dynamic>? lesson;
  bool showingStory = false;

  /// Показываем отдельным экраном перед серебряным/золотым прохождением —
  /// чтобы не писать "Золотой уровень: ..." прямо в тексте задания.
  bool showingTierIntro = false;
  int attemptTier = 1;
  int currentIndex = 0;
  String? selectedAnswer;
  bool? isCorrect;
  final _terminalController = TextEditingController();

  /// Ответ неверный, но совпадает без учёта регистра/пробелов — скорее всего
  /// опечатка, а не незнание команды. Показываем отдельным жёлтым состоянием.
  bool isClose = false;

  /// Приходит вместе с результатом проверки — показываем при ошибке
  String? correctAnswer;
  int attemptCount = 0;
  Map<String, dynamic>? user;
  int correctCount = 0;
  bool checking = false;
  bool finishing = false;
  DateTime? startTime;

  /// Повторное прохождение: XP за него уже начислялся, второй раз не даём
  bool isRepeat = false;

  /// Ответ на завершение урока: прогресс раздела, курса и что дальше
  Map<String, dynamic>? completion;

  /// Достижения, разблокированные за время этого урока — показываем очередью
  /// поздравлений перед выходом с экрана завершения раздела
  List<Map<String, dynamic>> newAchievements = [];

  /// Сундуки (золото за урок, завершение курса), выпавшие за этот урок —
  /// показываются перед достижениями по той же очереди
  List<Map<String, dynamic>> newChests = [];

  /// Квесты дня на момент завершения урока — заменили собой прежнюю
  /// «дневную цель N уроков» на экране результата.
  List<Map<String, dynamic>> quests = [];
  bool personalBest = false;

  /// Тумблер «Анимации Kernel» — читается один раз при загрузке урока
  bool mascotAnimations = true;

  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    loadLesson();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> loadLesson() async {
    final results = await Future.wait([
      fetchLesson(widget.lessonId, currentUserId),
      fetchLessonExercises(widget.lessonId, currentUserId),
      fetchUser(currentUserId),
    ]);
    final lessonData = results[0] as Map<String, dynamic>;
    final data = results[1] as List<Map<String, dynamic>>;
    final userData = results[2] as Map<String, dynamic>;
    final tier = ((lessonData['mastery'] as int? ?? 0) + 1).clamp(1, 3);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lesson = lessonData;
      showingStory = (lessonData['story'] as String?)?.isNotEmpty == true;
      attemptTier = tier;
      showingTierIntro = tier > 1;
      exercises = data;
      user = userData;
      startTime = DateTime.now();
      mascotAnimations = prefs.getBool(PrefKeys.mascotAnimations) ?? true;
    });
  }

  void _chooseOption(String option) {
    setState(() {
      selectedAnswer = option;
    });
  }

  void _checkAnswer() async {
    if (checking || isCorrect != null) return;
    setState(() => checking = true);

    final currentExercise = exercises[currentIndex];
    final result = await submitAnswer(
      currentExercise['id'],
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
      user?['streak'] = result['streak'];
      if (correct) correctCount++;
      checking = false;
      newAchievements.addAll(
        List<Map<String, dynamic>>.from(result['new_achievements'] ?? []),
      );
    });
    await _playAnswerFeedback(correct);
  }

  /// Тумблер «Звуки» — в проекте нет ни аудио-пакета, ни ассетов, поэтому
  /// как обратная связь используются системный звук клика (верно) и
  /// вибро-отклик (неверно), а не полноценные sfx.
  Future<void> _playAnswerFeedback(bool correct) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(PrefKeys.sound) ?? true)) return;
    if (correct) {
      SystemSound.play(SystemSoundType.click);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _nextExercise() {
    if (currentIndex + 1 >= exercises.length) {
      _finishLesson();
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

  /// Шаг LEARN не проверяется — просто засчитывается как пройденный, чтобы
  /// не портить XP/точность (нечего было отвечать неправильно).
  void _acknowledgeTheory() {
    correctCount++;
    _nextExercise();
  }

  /// Прошлое прохождение подняло мастерство урока — сложность следующего
  /// подбирается сервером заново, поэтому упражнения нужно перезапросить,
  /// а не просто перемотать локальный список на начало.
  Future<void> _repeatLesson() async {
    _terminalController.clear();
    setState(() {
      currentIndex = 0;
      selectedAnswer = null;
      isCorrect = null;
      isClose = false;
      correctAnswer = null;
      correctCount = 0;
      completion = null;
      isRepeat = true;
      exercises = [];
    });
    await loadLesson();
  }

  Future<void> _finishLesson() async {
    if (finishing || completion != null) return;
    setState(() => finishing = true);

    try {
      if (!isRepeat) {
        final xpResult = await awardXp(currentUserId, correctCount);
        if (mounted) setState(() => user?['xp'] = xpResult['xp']);
        newAchievements.addAll(
          List<Map<String, dynamic>>.from(xpResult['new_achievements'] ?? []),
        );
      }
      // «Идеально» — все упражнения решены верно с первой попытки, без
      // единой ошибки (retry внутри прохождения не предусмотрен, поэтому
      // correctCount == exercises.length и значит именно это).
      final perfect = correctCount == exercises.length;
      final data = await completeLesson(widget.lessonId, currentUserId, perfect: perfect);
      newAchievements.addAll(
        List<Map<String, dynamic>>.from(data['new_achievements'] ?? []),
      );
      newChests.addAll(
        List<Map<String, dynamic>>.from(data['chests'] ?? []),
      );
      final questsData = await fetchDailyQuests(currentUserId);
      if (!mounted) return;
      unawaited(NotificationsService.instance.cancelTodayReminders());
      newChests.addAll(
        List<Map<String, dynamic>>.from(questsData['newly_completed'] ?? [])
            .map((q) => {'reason': 'quest', 'amount': q['amount']}),
      );
      setState(() {
        completion = data;
        quests = List<Map<String, dynamic>>.from(questsData['quests'] ?? []);
        personalBest = questsData['personal_best'] == true;
        finishing = false;
      });
    } catch (e) {
      debugPrint('Ошибка завершения урока: $e');
      if (!mounted) return;
      setState(() => finishing = false);
      Navigator.pop(context);
    }
  }

  PreferredSizeWidget _buildAppBar({double? progress}) {
    final colors = context.colors;
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close, color: colors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      title: progress != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: colors.lockedBg,
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            )
          : null,
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${user!['streak']}'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _theoryScreen(Map<String, dynamic> exercise) {
    final colors = context.colors;
    final progress = currentIndex / exercises.length;
    final example = exercise['content']?['example'] as String?;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(progress: progress),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    lessonMascot(animated: mascotAnimations, size: 96),
                    const SizedBox(height: 12),
                    Text(
                      '\$ ${widget.sectionTitle}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: colors.accentDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 14,
                            color: colors.accentDark,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'ЧТО НУЖНО ЗНАТЬ',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                              color: colors.accentDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: _parseInlineCode(
                          exercise['question'] as String,
                          baseStyle: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            height: 1.4,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (example != null && example.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.terminalBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final line in example.split('\n'))
                              _terminalLine(line),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: PrimaryButton(
                text: 'Понятно',
                onPressed: _acknowledgeTheory,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Разбивает текст по `бэктикам` и подсвечивает код как моноширинный чип —
  /// без этого команды вроде `pwd` тонули бы в обычном тексте.
  List<InlineSpan> _parseInlineCode(
    String text, {
    required TextStyle baseStyle,
  }) {
    final colors = context.colors;
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
                  color: colors.accentDark,
                  backgroundColor: colors.accentBg,
                )
              : baseStyle,
        ),
      );
    }
    return spans;
  }

  /// Простая подсветка строк терминального примера: `$ команда` — приглашение
  /// бирюзовое, сама команда белая; всё остальное — приглушённый вывод.
  Widget _terminalLine(String line) {
    const promptColor = Color(0xFF00C9B7);
    const commandColor = Colors.white;
    const outputColor = Color(0xFF8FE4DA);

    if (line.startsWith('\$ ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13.5,
              height: 1.6,
            ),
            children: [
              const TextSpan(
                text: '\$ ',
                style: TextStyle(
                  color: promptColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: line.substring(2),
                style: const TextStyle(
                  color: commandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        line,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13.5,
          height: 1.6,
          color: outputColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (showingStory) {
      return _StoryIntro(
        sectionTitle: widget.sectionTitle,
        lessonTitle: lesson?['title'] as String? ?? '',
        story: lesson?['story'] as String? ?? '',
        animated: mascotAnimations,
        onContinue: () => setState(() => showingStory = false),
      );
    }

    if (showingTierIntro) {
      return _TierIntro(
        tier: attemptTier,
        animated: mascotAnimations,
        onContinue: () => setState(() => showingTierIntro = false),
      );
    }

    if (completion != null) {
      return SectionCompleteScreen(
        completion: completion!,
        quests: quests,
        personalBest: personalBest,
        xpEarned: isRepeat ? 0 : correctCount * 10,
        accuracyPercent: exercises.isEmpty
            ? 0
            : ((correctCount / exercises.length) * 100).round(),
        elapsed: startTime == null
            ? Duration.zero
            : DateTime.now().difference(startTime!),
        streak: user?['streak'] ?? 0,
        onContinue: () async {
          if (newChests.isNotEmpty) {
            final queuedChests = newChests;
            newChests = [];
            await showChestRewards(context, queuedChests);
          }
          if (!context.mounted) return;
          if (newAchievements.isNotEmpty) {
            final queued = newAchievements;
            newAchievements = [];
            await showAchievementUnlocks(context, queued);
          }
          if (!context.mounted) return;
          Navigator.pop(context);
        },
        onRepeat: _repeatLesson,
      );
    }

    if (finishing) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentExercise = exercises[currentIndex];

    if (currentExercise['type'] == 'theory') {
      return _theoryScreen(currentExercise);
    }

    final colors = context.colors;
    final question = currentExercise['question'];
    final isTerminal = currentExercise['type'] == 'terminal';
    final options = isTerminal
        ? const <String>[]
        : List<String>.from(currentExercise['content']['options']);
    final progress =
        (currentIndex + (isCorrect != null ? 1 : 0)) / exercises.length;

    return Scaffold(
      appBar: _buildAppBar(progress: progress),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '\$ ${widget.sectionTitle}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: colors.accentDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: _parseInlineCode(
                  question as String,
                  baseStyle: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isTerminal)
              _TerminalInput(
                controller: _terminalController,
                enabled: isCorrect == null,
                onChanged: _chooseOption,
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
                                ? 'Правильно! ${isRepeat ? '' : '+10 XP'}'
                                      .trim()
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
                            if (isCorrect!) {
                              _lottieController.duration =
                                  composition.duration ~/ 2;
                            } else {
                              _lottieController.duration = composition.duration;
                            }
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
              PrimaryButton(text: 'Продолжить', onPressed: _nextExercise),
          ],
        ),
      ),
    );
  }
}

/// Ввод команды текстом вместо выбора варианта — используется упражнениями
/// типа `terminal`, где нужно вспомнить/набрать команду самому.
class _TerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _TerminalInput({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
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
    );
  }
}

/// Короткий брифинг перед миссией — контекст, зачем вообще нужен этот урок,
/// в духе "STORY"-шага из структуры миссии. Показывается каждый раз при
/// открытии урока, включая повтор — это брифинг, а не одноразовое интро.
class _StoryIntro extends StatefulWidget {
  final String sectionTitle;
  final String lessonTitle;
  final String story;
  final bool animated;
  final VoidCallback onContinue;

  const _StoryIntro({
    required this.sectionTitle,
    required this.lessonTitle,
    required this.story,
    required this.animated,
    required this.onContinue,
  });

  @override
  State<_StoryIntro> createState() => _StoryIntroState();
}

class _StoryIntroState extends State<_StoryIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _mascotScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _mascotScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    const textInterval = Interval(0.3, 0.8, curve: Curves.easeOut);
    _fade = CurvedAnimation(parent: _controller, curve: textInterval);
    _slide = Tween(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: textInterval));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _mascotScale,
                  child: lessonMascot(animated: widget.animated, size: 140),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      children: [
                        Text(
                          '\$ ${widget.sectionTitle}',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: colors.accentDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.lessonTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            height: 1.2,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.story,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            height: 1.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Начать миссию',
                      onPressed: widget.onContinue,
                    ),
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

/// Заставка перед серебряным/золотым прохождением — объясняет, что изменится
/// (без подсказок, сложнее вопросы), не засоряя этим текст самих заданий.
/// Стадийное появление медали с "поп"-эффектом + пульсирующее кольцо вокруг
/// неё, чтобы момент ощущался как награда, а не служебный экран.
class _TierIntro extends StatefulWidget {
  final int tier;
  final bool animated;
  final VoidCallback onContinue;

  const _TierIntro({
    required this.tier,
    required this.animated,
    required this.onContinue,
  });

  @override
  State<_TierIntro> createState() => _TierIntroState();
}

class _TierIntroState extends State<_TierIntro> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _badgeScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _pulse;
  late final AnimationController _sparkle;

  static const _tiers = {
    2: (
      label: 'Серебряный уровень',
      color: Color(0xFF8FA0AB),
      bg: Color(0xFFEDF1F3),
      emotion: MascotEmotion.happy,
      description:
          'Ты уже проходил этот урок. Теперь — без подсказок и с вопросами похитрее. Проверим, что действительно запомнилось.',
    ),
    3: (
      label: 'Золотой уровень',
      color: Color(0xFFE0A82E),
      bg: Color(0xFFFFF3D6),
      emotion: MascotEmotion.excited,
      description:
          'Финальная проверка. Минимум подсказок, максимум внимания — заодно вспомним то, что учили раньше.',
    ),
  };

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _badgeScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    const textInterval = Interval(0.35, 0.85, curve: Curves.easeOut);
    _fade = CurvedAnimation(parent: _entrance, curve: textInterval);
    _slide = Tween(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: textInterval));
    _entrance.forward();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _tiers[widget.tier] ?? _tiers[2]!;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _sparkle,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _sparkle.value * 6.28318,
                            child: child,
                          );
                        },
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              left: 100,
                              child: Text(
                                '✨',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: style.color,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 30,
                              right: 8,
                              child: Text(
                                '✨',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: style.color,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 40,
                              left: 4,
                              child: Text(
                                '✨',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: style.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ScaleTransition(
                        scale: _badgeScale,
                        child: lessonMascot(
                          animated: widget.animated,
                          size: 150,
                          emotion: style.emotion,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 14,
                        child: ScaleTransition(
                          scale: _badgeScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (context, child) {
                                  final v = Curves.easeInOut.transform(
                                    _pulse.value,
                                  );
                                  return Transform.scale(
                                    scale: 1.0 + v * 0.14,
                                    child: Opacity(
                                      opacity: 0.35 + v * 0.35,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: style.color,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: style.bg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: style.color.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 26,
                                  color: style.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      children: [
                        Text(
                          style.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          style.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            height: 1.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Начать',
                      onPressed: widget.onContinue,
                    ),
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
