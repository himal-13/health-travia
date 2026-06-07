import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trivia_game/providers/study_provider.dart';
import 'package:trivia_game/providers/progress_provider.dart';
import 'package:trivia_game/services/audio_service.dart';
import 'package:trivia_game/models/course.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  bool _revealAnswer = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final progress = context.read<ProgressProvider>();
    final audio = context.read<AudioService>();
    final colorScheme = Theme.of(context).colorScheme;

    // Get all available topics for the current selected course
    List<String> topics = [];
    if (study.selectedCourse != null) {
      final course = study.courses.firstWhere(
        (c) => c.name.toLowerCase() == study.selectedCourse!.toLowerCase(),
      );
      topics = course.topics.map((t) => t.name).toList();
    } else {
      topics = study.courses.expand((c) => c.topics.map((t) => t.name)).toSet().toList();
    }

    final question = study.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Mode'),
        centerTitle: true,
        actions: [
          if (question != null)
            IconButton(
              icon: Icon(
                study.isBookmarked(question) ? Icons.bookmark : Icons.bookmark_border,
                color: study.isBookmarked(question) ? Colors.amber : null,
              ),
              onPressed: () {
                audio.playClick();
                study.toggleBookmark(question);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel
          _buildFilterPanel(context, study, topics),

          // Main content area
          Expanded(
            child: study.filteredQuestions.isEmpty
                ? _buildEmptyState(context)
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Progress Bar Indicator
                        _buildProgressBar(study),
                        const SizedBox(height: 16),

                        // Question Card
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildQuestionCard(context, question!, study, progress, audio),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Navigation Control Panel
                        _buildNavigationControls(study, audio),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, StudyProvider study, List<String> topics) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => study.updateSearch(val),
            decoration: InputDecoration(
              hintText: 'Search questions and answers...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(height: 10),

          // Course and Topic Dropdowns
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: study.selectedCourse,
                      hint: const Text('All Courses', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Courses', style: TextStyle(fontSize: 13)),
                        ),
                        ...study.courses.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.name,
                            child: Text(c.name, style: const TextStyle(fontSize: 13)),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        study.filterCourse(val);
                        setState(() {
                          _revealAnswer = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: study.selectedTopic,
                      hint: const Text('All Topics', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Topics', style: TextStyle(fontSize: 13)),
                        ),
                        ...topics.map((topic) {
                          return DropdownMenuItem<String>(
                            value: topic,
                            child: Text(
                              topic,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        study.filterTopic(val);
                        setState(() {
                          _revealAnswer = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Difficulty Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Difficulty:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    ChoiceChip(
                      label: const Text('All', style: TextStyle(fontSize: 11)),
                      selected: study.selectedDifficulty == null,
                      onSelected: (selected) {
                        if (selected) {
                          study.filterDifficulty(null);
                          setState(() => _revealAnswer = false);
                        }
                      },
                    ),
                    ...List.generate(5, (index) {
                      final val = index + 1;
                      final names = ['V. Easy', 'Easy', 'Medium', 'Hard', 'Expert'];
                      return ChoiceChip(
                        label: Text(names[index], style: const TextStyle(fontSize: 11)),
                        selected: study.selectedDifficulty == val,
                        onSelected: (selected) {
                          if (selected) {
                            study.filterDifficulty(val);
                            setState(() => _revealAnswer = false);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(StudyProvider study) {
    final current = study.currentIndex + 1;
    final total = study.filteredQuestions.length;
    final progressVal = total > 0 ? (current / total) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $current of $total',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(progressVal * 100).toInt()}% Done',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progressVal,
          borderRadius: BorderRadius.circular(8),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Question question,
    StudyProvider study,
    ProgressProvider progress,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAlreadyStudied = progress.progress.studiedQuestions.contains(question.uniqueKey);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Metadata Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    question.topic,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(question.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getDifficultyName(question.difficulty),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(question.difficulty),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question Text
            Text(
              question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Options outline list
            ...question.options.asMap().entries.map((entry) {
              final isCorrectOption = entry.key == question.answerIndex;
              final showAsGreen = _revealAnswer && isCorrectOption;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: showAsGreen ? Colors.green.withOpacity(0.08) : Colors.transparent,
                  border: Border.all(
                    color: showAsGreen ? Colors.green : colorScheme.outlineVariant,
                    width: showAsGreen ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: showAsGreen ? Colors.green : colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        String.fromCharCode(65 + entry.key), // A, B, C, D
                        style: TextStyle(
                          color: showAsGreen ? Colors.white : colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: showAsGreen ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Reveal/Explanation Button
            if (!_revealAnswer)
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('Show Correct Answer & Explanation'),
                onPressed: () {
                  audio.playClick();
                  setState(() {
                    _revealAnswer = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Correct Answer: Option ${String.fromCharCode(65 + question.answerIndex)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),
                  
                  // Mark as studied button
                  OutlinedButton.icon(
                    icon: Icon(isAlreadyStudied ? Icons.check : Icons.menu_book),
                    label: Text(isAlreadyStudied ? 'Marked as Studied' : 'Mark as Studied'),
                    onPressed: isAlreadyStudied
                        ? null
                        : () {
                            audio.playCorrect();
                            progress.markAsStudied(question);
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls(StudyProvider study, AudioService audio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: study.currentIndex > 0
              ? () {
                  audio.playClick();
                  study.previousQuestion();
                  setState(() => _revealAnswer = false);
                }
              : null,
        ),
        Text(
          '${study.currentIndex + 1} / ${study.filteredQuestions.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: study.currentIndex < study.filteredQuestions.length - 1
              ? () {
                  audio.playClick();
                  study.nextQuestion();
                  setState(() => _revealAnswer = false);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: colorScheme.outline),
            const SizedBox(height: 16),
            const Text(
              'No Questions Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search criteria to view study cards.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyName(int diff) {
    switch (diff) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Expert';
      default:
        return 'Easy';
    }
  }

  Color _getDifficultyColor(int diff) {
    switch (diff) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.teal;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }
}
