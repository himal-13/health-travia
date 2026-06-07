import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trivia_game/providers/progress_provider.dart';
import 'package:trivia_game/providers/app_state_provider.dart';
import 'package:trivia_game/services/audio_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final appState = context.watch<AppStateProvider>();
    final audio = context.read<AudioService>();
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Check for achievement popups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (progress.newlyUnlockedAchievement != null) {
        _showAchievementDialog(context, progress);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Trivia Prep',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              appState.themeModeName == 'dark'
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              audio.playClick();
              appState.toggleTheme(
                appState.themeModeName == 'dark' ? 'light' : 'dark',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              audio.playClick();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Banner
              _buildWelcomeBanner(context, progress),
              const SizedBox(height: 20),

              // Statistics Dashboard Card
              _buildStatsDashboard(context, progress, isTablet),
              const SizedBox(height: 24),

              // Mode Navigation Grid
              const Text(
                'Learning & Battle Modes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildModesGrid(context, audio, isTablet),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, ProgressProvider progress) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to Study?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text(
            'Sharpen your medical concepts and test your skills in real-time battles.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(
    BuildContext context,
    ProgressProvider progress,
    bool isTablet,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = [
      _StatItem(
        'Studied',
        '${progress.totalQuestionsStudied}',
        Icons.book,
        colorScheme.primary,
      ),
      _StatItem(
        'Accuracy',
        '${progress.accuracy.toStringAsFixed(1)}%',
        Icons.check_circle,
        Colors.green,
      ),
      _StatItem(
        'Daily Streak',
        '${progress.currentStreak} Days',
        Icons.local_fire_department,
        Colors.orange,
      ),
      _StatItem(
        'Wins',
        '${progress.multiplayerWins}',
        Icons.emoji_events,
        Colors.amber,
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isTablet ? 1.8 : 1.4,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final item = stats[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: item.color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(item.icon, color: item.color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModesGrid(
    BuildContext context,
    AudioService audio,
    bool isTablet,
  ) {
    final modes = [
      _ModeCardData(
        title: 'Study Mode',
        description: 'Read notes, browse questions & bookmark answers.',
        icon: Icons.school,
        color: Colors.blue,
        route: '/study',
      ),
      _ModeCardData(
        title: 'Quiz Mode',
        description: 'Level up your learning from level 1 to 5.',
        icon: Icons.assignment_turned_in,
        color: Colors.purple,
        route: '/quiz',
      ),
      _ModeCardData(
        title: 'Multiplayer Battle',
        description: 'Splitscreen local multiplayer modes.',
        icon: Icons.people_alt,
        color: Colors.deepOrange,
        route: '/multiplayer',
      ),
      _ModeCardData(
        title: 'Stats & Charts',
        description: 'Detail analysis of your preparation.',
        icon: Icons.bar_chart,
        color: Colors.teal,
        route: '/progress',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isTablet ? 2.5 : 3.0,
      ),
      itemCount: modes.length,
      itemBuilder: (context, index) {
        final mode = modes[index];
        return Card(
              elevation: 2,
              shadowColor: mode.color.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  audio.playClick();
                  context.push(mode.route);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: mode.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(mode.icon, color: mode.color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mode.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mode.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (index * 100).ms, duration: 400.ms)
            .slideY(begin: 0.1);
      },
    );
  }

  void _showAchievementDialog(BuildContext context, ProgressProvider progress) {
    final ach = progress.newlyUnlockedAchievement!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: Colors.amber,
                  size: 80,
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                const Text(
                  'ACHIEVEMENT UNLOCKED!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ach.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ach.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    progress.dismissAchievementPopup();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Awesome!'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}

class _ModeCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  _ModeCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}
