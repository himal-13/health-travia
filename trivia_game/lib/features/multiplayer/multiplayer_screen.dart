import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trivia_game/models/course.dart';
import 'package:trivia_game/providers/multiplayer_provider.dart';
import 'package:trivia_game/providers/progress_provider.dart';
import 'package:trivia_game/providers/study_provider.dart';
import 'package:trivia_game/services/audio_service.dart';

class MultiplayerScreen extends StatelessWidget {
  const MultiplayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final multiplayer = context.watch<MultiplayerProvider>();
    final progress = context.watch<ProgressProvider>();
    final study = context.watch<StudyProvider>();
    final audio = context.read<AudioService>();

    // Dynamic initialisation of courses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      multiplayer.initialize(study.courses);
    });

    if (multiplayer.isGameOver) {
      return _buildWinnerView(context, multiplayer, audio);
    }

    if (multiplayer.currentQuestion != null) {
      return _buildMatchView(context, multiplayer, progress, audio);
    }

    return _buildLobbyView(context, multiplayer, study, audio);
  }

  // ==================== MATCH LOBBY SETUP ====================
  Widget _buildLobbyView(
    BuildContext context,
    MultiplayerProvider multiplayer,
    StudyProvider study,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer Battle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_alt,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Local Splitscreen Arena',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sit opposite your friend on a single phone or tablet. Choose a mode and start the trivia clash!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Game Mode Select
              const Text(
                'Select Battle Mode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildModeSelector(multiplayer, audio),
              const SizedBox(height: 24),

              // Course Selection
              const Text(
                'Select Question Deck',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildCourseSelector(context, multiplayer, study, audio),
              const SizedBox(height: 32),

              // Start Button
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Enter Arena',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  audio.playClick();
                  multiplayer.startMatch();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ).animate().scale(
                delay: 200.ms,
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(
    MultiplayerProvider multiplayer,
    AudioService audio,
  ) {
    final modes = [
      _ModeConfig(
        MultiplayerMode.classic,
        'Classic',
        'First to 20 points wins.',
        Icons.wine_bar,
        Colors.blue,
      ),
      _ModeConfig(
        MultiplayerMode.survival,
        'Survival',
        '3 Lives each. Wrong choice loses life.',
        Icons.favorite,
        Colors.red,
      ),
      _ModeConfig(
        MultiplayerMode.speed,
        'Speed Battle',
        '10s timer. Passing turn on timeout.',
        Icons.bolt,
        Colors.amber,
      ),
    ];

    return Column(
      children: modes.map((m) {
        final isSelected = multiplayer.mode == m.mode;
        return Card(
          elevation: isSelected ? 2 : 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? m.color : Colors.grey.shade300,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: ListTile(
            leading: Icon(m.icon, color: isSelected ? m.color : Colors.grey),
            title: Text(
              m.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? m.color : null,
              ),
            ),
            subtitle: Text(m.description, style: const TextStyle(fontSize: 11)),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: m.color)
                : null,
            onTap: () {
              audio.playClick();
              multiplayer.mode = m.mode;
              multiplayer.notifyListeners();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseSelector(
    BuildContext context,
    MultiplayerProvider multiplayer,
    StudyProvider study,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final courses = study.courses;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Course?>(
          value: multiplayer.selectedCourse,
          hint: const Text('All Courses Mixed'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<Course?>(
              value: null,
              child: Text('All Decks Mixed'),
            ),
            ...courses.map((c) {
              return DropdownMenuItem<Course?>(value: c, child: Text(c.name));
            }),
          ],
          onChanged: (val) {
            audio.playClick();
            multiplayer.selectedCourse = val;
            multiplayer.notifyListeners();
          },
        ),
      ),
    );
  }

  // ==================== BATTLE SPLITSCREEN ARENA ====================
  Widget _buildMatchView(
    BuildContext context,
    MultiplayerProvider multiplayer,
    ProgressProvider progress,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ==================== TOP PLAYER (PLAYER 1) ====================
            Expanded(
              child: RotatedBox(
                quarterTurns: 2, // Rotate 180 degrees
                child: _buildPlayerHalf(
                  context,
                  1,
                  multiplayer,
                  progress,
                  audio,
                ),
              ),
            ),

            // ==================== MIDDLE CONTROL DIVIDER ====================
            Container(
              height: 48,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'P1: ${multiplayer.p1Score} pts' +
                        (multiplayer.mode == MultiplayerMode.survival
                            ? ' | ❤️x${multiplayer.p1Lives}'
                            : ''),
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  _buildCenterTurnStatus(context, multiplayer),
                  Text(
                    'P2: ${multiplayer.p2Score} pts' +
                        (multiplayer.mode == MultiplayerMode.survival
                            ? ' | ❤️x${multiplayer.p2Lives}'
                            : ''),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ==================== BOTTOM PLAYER (PLAYER 2) ====================
            Expanded(
              child: _buildPlayerHalf(context, 2, multiplayer, progress, audio),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterTurnStatus(
    BuildContext context,
    MultiplayerProvider multiplayer,
  ) {
    if (multiplayer.mode == MultiplayerMode.speed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.yellow, size: 16),
            const SizedBox(width: 4),
            Text(
              '${multiplayer.timerSeconds}s • Turn: P${multiplayer.activePlayer}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    final isP1Active = multiplayer.activePlayer == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isP1Active
            ? Colors.blueAccent.withOpacity(0.2)
            : Colors.orangeAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isP1Active ? Colors.blueAccent : Colors.orangeAccent,
        ),
      ),
      child: Text(
        'Turn: Player ${multiplayer.activePlayer}',
        style: TextStyle(
          color: isP1Active ? Colors.blueAccent : Colors.orangeAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPlayerHalf(
    BuildContext context,
    int playerNum,
    MultiplayerProvider multiplayer,
    ProgressProvider progress,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = multiplayer.activePlayer == playerNum;
    final themeColor = playerNum == 1 ? Colors.blue : Colors.orange;

    final question = multiplayer.currentQuestion;
    if (question == null) return const SizedBox();

    return Container(
      color: isActive
          ? themeColor.withOpacity(0.03)
          : Colors.grey.withOpacity(0.02),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info row (Header for player half)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Player $playerNum',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isActive ? themeColor : Colors.grey,
                ),
              ),
              Text(
                question.topic,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Question Card inside player's half
          Card(
            elevation: isActive ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isActive
                    ? themeColor.withOpacity(0.4)
                    : colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Text(
                question.question,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Options grid/list
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: multiplayer.currentOptions.length,
              itemBuilder: (context, index) {
                final isEliminated = multiplayer.eliminatedOptionIndices
                    .contains(index);
                if (isEliminated) {
                  return const SizedBox(); // Disappear!
                }

                final optionStr = multiplayer.currentOptions[index];

                return OutlinedButton(
                  onPressed: !isActive
                      ? null
                      : () {
                          multiplayer.chooseOption(index, progress);
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    side: BorderSide(
                      color: isActive
                          ? themeColor.withOpacity(0.7)
                          : Colors.grey.shade300,
                    ),
                    backgroundColor: isActive
                        ? Colors.white
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      optionStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.black87 : Colors.grey,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),

          // Safety quit button inside player 2's half (so someone can stop the match)
          if (playerNum == 2)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.exit_to_app, size: 14),
                label: const Text('Quit Match', style: TextStyle(fontSize: 10)),
                onPressed: () {
                  audio.playClick();
                  multiplayer.quitMatch();
                },
              ),
            ),
        ],
      ),
    );
  }

  // ==================== WINNER / RESULTS OVERLAY ====================
  Widget _buildWinnerView(
    BuildContext context,
    MultiplayerProvider multiplayer,
    AudioService audio,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final winner = multiplayer.winner;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                winner > 0 ? Icons.military_tech : Icons.handshake,
                color: winner == 1
                    ? Colors.blue
                    : (winner == 2 ? Colors.orange : Colors.teal),
                size: 100,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                winner > 0 ? 'PLAYER $winner WINS!' : 'IT\'S A DRAW!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: winner == 1
                      ? Colors.blue
                      : (winner == 2 ? Colors.orange : Colors.teal),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Final Standings:\nPlayer 1: ${multiplayer.p1Score} points\nPlayer 2: ${multiplayer.p2Score} points',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  audio.playClick();
                  multiplayer.quitMatch(); // returns to multiplayer lobby
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Return to Lobby',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeConfig {
  final MultiplayerMode mode;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _ModeConfig(this.mode, this.title, this.description, this.icon, this.color);
}
