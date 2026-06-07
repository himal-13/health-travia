import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trivia_game/providers/quiz_provider.dart';
import 'package:trivia_game/providers/progress_provider.dart';
import 'package:trivia_game/providers/app_state_provider.dart';
import 'package:trivia_game/providers/study_provider.dart';
import 'package:trivia_game/services/audio_service.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final progress = context.watch<ProgressProvider>();
    final appState = context.watch<AppStateProvider>();
    final study = context.watch<StudyProvider>();
    final audio = context.read<AudioService>();

    if (quiz.isQuizFinished) {
      return _buildResultsView(context, quiz, progress, audio);
    }

    if (quiz.isQuizActive) {
      return _buildGameplayView(context, quiz, progress, appState, audio);
    }

    return _buildLevelSelectorView(
      context,
      quiz,
      progress,
      study,
      appState,
      audio,
    );
  }

  // ==================== LEVEL SELECTOR VIEW ====================
  Widget _buildLevelSelectorView(
    BuildContext context,
    QuizProvider quiz,
    ProgressProvider progress,
    StudyProvider study,
    AppStateProvider appState,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Use courses imported in study provider
    final courses = study.courses;
    if (courses.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determine current selected course for level selector
    // If not set, default to first course
    final selectedCourseName = study.selectedCourse ?? courses.first.name;
    final activeCourse = courses.firstWhere(
      (c) => c.name.toLowerCase() == selectedCourseName.toLowerCase(),
      orElse: () => courses.first,
    );

    final levels = [
      _LevelData(1, 'Very Easy', Colors.green, Icons.sentiment_very_satisfied),
      _LevelData(2, 'Easy', Colors.teal, Icons.sentiment_satisfied),
      _LevelData(3, 'Medium', Colors.orange, Icons.sentiment_neutral),
      _LevelData(4, 'Hard', Colors.red, Icons.sentiment_dissatisfied),
      _LevelData(
        5,
        'Expert',
        Colors.deepPurple,
        Icons.sentiment_very_dissatisfied,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Quizzes'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course Toggle Tabs
            Row(
              children: courses.map((course) {
                final isSelected = course.name == activeCourse.name;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        audio.playClick();
                        study.filterCourse(course.name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant,
                        foregroundColor: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        elevation: isSelected ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        course.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Timer Toggle Config
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Timer Mode (30s per question)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Wrong answer on timeout.',
                  style: TextStyle(fontSize: 11),
                ),
                value: appState.timerMode,
                onChanged: (val) {
                  audio.playClick();
                  appState.toggleTimer(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Select Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Levels list
            Expanded(
              child: ListView.builder(
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final lvl = levels[index];
                  // Level 1 is always unlocked. Level N is unlocked if level N-1 is in progress.completedLevels
                  final isUnlocked =
                      index == 0 ||
                      progress.progress.completedLevels.contains(
                        '${activeCourse.name}:${lvl.levelIndex - 1}',
                      );

                  return Card(
                        elevation: isUnlocked ? 2 : 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isUnlocked
                            ? null
                            : colorScheme.surfaceVariant.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: isUnlocked
                              ? BorderSide.none
                              : BorderSide(
                                  color: colorScheme.outlineVariant.withOpacity(
                                    0.5,
                                  ),
                                ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: isUnlocked
                              ? () {
                                  audio.playClick();
                                  quiz.startQuiz(
                                    course: activeCourse,
                                    level: lvl.levelIndex,
                                    timerEnabled: appState.timerMode,
                                  );
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? lvl.color.withOpacity(0.1)
                                        : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isUnlocked ? lvl.icon : Icons.lock,
                                    color: isUnlocked ? lvl.color : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Level ${lvl.levelIndex}: ${lvl.title}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked
                                              ? null
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '20 Mixed Questions • 70% to unlock next',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isUnlocked
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (progress.progress.completedLevels.contains(
                                  '${activeCourse.name}:${lvl.levelIndex}',
                                ))
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                else if (isUnlocked)
                                  Icon(
                                    Icons.play_circle_fill,
                                    color: colorScheme.primary,
                                    size: 30,
                                  )
                                else
                                  Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 80).ms, duration: 300.ms)
                      .slideX(begin: 0.05);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== GAMEPLAY VIEW ====================
  Widget _buildGameplayView(
    BuildContext context,
    QuizProvider quiz,
    ProgressProvider progress,
    AppStateProvider appState,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final question = quiz.currentQuestion;
    if (question == null) return const Scaffold();

    final currentNum = quiz.currentQuestionIndex + 1;
    final totalNum = quiz.questions.length;
    final progressVal = currentNum / totalNum;

    return WillPopScope(
      onWillPop: () async {
        final confirm = await _showQuitConfirmation(context);
        if (confirm == true) {
          quiz.quitQuiz();
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final confirm = await _showQuitConfirmation(context);
              if (confirm == true) {
                quiz.quitQuiz();
              }
            },
          ),
          title: Text('${quiz.courseName} - Lvl ${quiz.level}'),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'Score: ${quiz.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator & Timer row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question $currentNum of $totalNum',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (appState.timerMode)
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.red, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.timerSeconds}s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: quiz.timerSeconds <= 5
                                ? Colors.red
                                : colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressVal,
                borderRadius: BorderRadius.circular(8),
                minHeight: 6,
              ),
              const SizedBox(height: 24),

              // Question display card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Options list
              Expanded(
                child: ListView.builder(
                  itemCount: quiz.currentOptions.length,
                  itemBuilder: (context, index) {
                    final optionStr = quiz.currentOptions[index];
                    final isSelected = quiz.selectedAnswerIndex == index;

                    // Identify correct indices based on shuffling
                    final isCorrectOption =
                        optionStr == question.options[question.answerIndex];

                    Color borderCol = colorScheme.outlineVariant;
                    Color bgCol = Colors.transparent;
                    Widget? trailingIcon;

                    if (quiz.hasAnswered) {
                      if (isCorrectOption) {
                        borderCol = Colors.green;
                        bgCol = Colors.green.withOpacity(0.08);
                        trailingIcon = const Icon(
                          Icons.check,
                          color: Colors.green,
                        );
                      } else if (isSelected) {
                        borderCol = Colors.red;
                        bgCol = Colors.red.withOpacity(0.08);
                        trailingIcon = const Icon(
                          Icons.close,
                          color: Colors.red,
                        );
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton(
                        onPressed: quiz.hasAnswered
                            ? null
                            : () {
                                quiz.answerQuestion(
                                  index,
                                  appState.timerMode,
                                  progress,
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          backgroundColor: bgCol,
                          side: BorderSide(
                            color: borderCol,
                            width:
                                quiz.hasAnswered &&
                                    (isCorrectOption || isSelected)
                                ? 2.5
                                : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: quiz.hasAnswered && isCorrectOption
                                    ? Colors.green
                                    : (quiz.hasAnswered && isSelected
                                          ? Colors.red
                                          : colorScheme.surfaceVariant),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      quiz.hasAnswered &&
                                          (isCorrectOption || isSelected)
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                optionStr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      quiz.hasAnswered && isCorrectOption
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: quiz.hasAnswered
                                      ? (isCorrectOption
                                            ? Colors.green.shade800
                                            : (isSelected
                                                  ? Colors.red.shade800
                                                  : Colors.grey))
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (trailingIcon != null) trailingIcon,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom action drawer
              if (quiz.hasAnswered)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explanation:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            question.explanation,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        audio.playClick();
                        quiz.nextQuestion(appState.timerMode, progress);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        currentNum == totalNum
                            ? 'Finish Quiz'
                            : 'Next Question',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== RESULTS VIEW ====================
  Widget _buildResultsView(
    BuildContext context,
    QuizProvider quiz,
    ProgressProvider progress,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final passed = (quiz.score / quiz.questions.length) >= 0.70;
    final percentage = (quiz.score / quiz.questions.length) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Completed'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration Banner
              Center(
                child: Column(
                  children: [
                    Icon(
                      passed
                          ? Icons.emoji_events
                          : Icons.sentiment_dissatisfied,
                      color: passed ? Colors.amber : Colors.orange,
                      size: 90,
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      passed ? 'Congratulations!' : 'Practice Makes Perfect!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      passed
                          ? 'You passed the level!'
                          : 'Achieve 70% to unlock the next level.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Score Circle Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Your Score',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${quiz.score}',
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: passed ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            ' / ${quiz.questions.length}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${percentage.toInt()}% Accuracy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: passed
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailStat(
                            context,
                            'Time Taken',
                            '${quiz.timeTaken.inMinutes}:${(quiz.timeTaken.inSeconds % 60).toString().padLeft(2, '0')}',
                            Icons.timer,
                          ),
                          _buildDetailStat(
                            context,
                            'Outcome',
                            passed ? 'Level Unlocked' : 'Locked',
                            passed ? Icons.lock_open : Icons.lock,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Diagnostics (Weak/Strong topics)
              if (quiz.strongTopics.isNotEmpty || quiz.weakTopics.isNotEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance Breakdown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (quiz.strongTopics.isNotEmpty) ...[
                          Row(
                            children: const [
                              Icon(
                                Icons.thumb_up,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Strong Topics:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: quiz.strongTopics.map((topic) {
                              return Chip(
                                label: Text(
                                  topic,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (quiz.weakTopics.isNotEmpty) ...[
                          Row(
                            children: const [
                              Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Needs Improvement:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: quiz.weakTopics.map((topic) {
                              return Chip(
                                label: Text(
                                  topic,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Navigation actions
              ElevatedButton(
                onPressed: () {
                  audio.playClick();
                  quiz.quitQuiz(); // Returns to level selector
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back to Level Select',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Future<bool?> _showQuitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quit Quiz?'),
          content: const Text(
            'Your current progress in this quiz session will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Quit', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _LevelData {
  final int levelIndex;
  final String title;
  final Color color;
  final IconData icon;

  _LevelData(this.levelIndex, this.title, this.color, this.icon);
}
