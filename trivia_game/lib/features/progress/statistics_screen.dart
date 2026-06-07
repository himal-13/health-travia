import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trivia_game/models/user_progress.dart';
import 'package:trivia_game/providers/progress_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics & Badges'),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart), text: 'Progress Stats'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatsTab(context, progress),
            _buildAchievementsTab(context, progress),
          ],
        ),
      ),
    );
  }

  // ==================== STATISTICS TAB ====================
  Widget _buildStatsTab(
    BuildContext context,
    ProgressProvider progressProvider,
  ) {
    final progress = progressProvider.progress;
    final colorScheme = Theme.of(context).colorScheme;

    final double studyHours = progress.timeStudiedSeconds / 3600;
    final String timeStr = studyHours < 0.1
        ? '${(progress.timeStudiedSeconds / 60).toStringAsFixed(0)} mins'
        : '${studyHours.toStringAsFixed(1)} hours';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Cards row
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Study Time',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.star_border,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Completed Levels',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${progress.completedLevels.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Diagnostic Strengths/Weaknesses
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Topic Mastery Analysis',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDiagnosticRow(
                      context,
                      'Strongest Topic',
                      progressProvider.strongestTopic,
                      Icons.trending_up,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildDiagnosticRow(
                      context,
                      'Weakest Topic',
                      progressProvider.weakestTopic,
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Accuracy By Topic Chart Title
            const Text(
              'Accuracy by Medical Subject',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Only includes topics with at least 5 questions answered.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Accuracy Chart
            _buildAccuracyChart(context, progress),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(
    BuildContext context,
    String label,
    String topic,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                topic,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyChart(BuildContext context, UserProgress progress) {
    final Map<String, double> accuracies = {};
    progress.topicStats.forEach((topic, stats) {
      final total = stats['total'] ?? 0;
      if (total >= 5) {
        final acc = ((stats['correct'] ?? 0) / total) * 100;
        accuracies[topic] = acc;
      }
    });

    if (accuracies.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No topic stats available.\nComplete quiz mode levels to build statistics!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final List<MapEntry<String, double>> sortedData =
        accuracies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Show top 6 topics
    final displayData = sortedData.take(6).toList();

    return Container(
      height: 240,
      padding: const EdgeInsets.only(top: 24, right: 16, left: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colorScheme.secondaryContainer,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${displayData[groupIndex].key}\n${rod.toY.toInt()}%',
                  TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < displayData.length) {
                    // Extract initials or short name
                    final name = displayData[idx].key;
                    final initials = name.split(' ').map((e) => e[0]).join();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        initials.length > 3
                            ? initials.substring(0, 3)
                            : initials,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  );
                },
                reservedSize: 32,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(displayData.length, (index) {
            final entry = displayData[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ==================== ACHIEVEMENTS TAB ====================
  Widget _buildAchievementsTab(
    BuildContext context,
    ProgressProvider progress,
  ) {
    final list = progress.achievements;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unlocked Badges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${list.where((a) => a.isUnlocked).length} / ${list.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final ach = list[index];
                return Card(
                      elevation: ach.isUnlocked ? 2 : 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: ach.isUnlocked
                          ? null
                          : colorScheme.surfaceVariant.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: ach.isUnlocked
                            ? BorderSide.none
                            : BorderSide(
                                color: colorScheme.outlineVariant.withOpacity(
                                  0.4,
                                ),
                              ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Badge Icon
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: ach.isUnlocked
                                    ? Colors.amber.withOpacity(0.1)
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconData(ach.iconName),
                                color: ach.isUnlocked
                                    ? Colors.amber
                                    : Colors.grey.shade500,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Title & details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ach.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: ach.isUnlocked
                                          ? null
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ach.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ach.isUnlocked
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  if (ach.isUnlocked &&
                                      ach.unlockedAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Unlocked on ${DateFormat('yyyy-MM-dd').format(ach.unlockedAt!)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!ach.isUnlocked)
                              Icon(
                                Icons.lock_outline,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (index * 60).ms, duration: 250.ms)
                    .slideY(begin: 0.05);
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String key) {
    switch (key) {
      case 'quiz':
        return Icons.quiz;
      case 'school':
        return Icons.school;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'star':
        return Icons.star;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.stars;
    }
  }
}
