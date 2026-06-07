import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trivia_game/providers/app_state_provider.dart';
import 'package:trivia_game/providers/progress_provider.dart';
import 'package:trivia_game/services/audio_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final progress = context.watch<ProgressProvider>();
    final audio = context.read<AudioService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Theme settings section
              _buildSectionHeader('Appearance'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text(
                          'Theme Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: appState.themeModeName,
                          items: const [
                            DropdownMenuItem(
                              value: 'system',
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: 'light',
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: 'dark',
                              child: Text('Dark'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              audio.playClick();
                              appState.toggleTheme(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Audio preferences section
              _buildSectionHeader('Sound & Music'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.volume_up),
                      title: const Text(
                        'Sound Effects',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Game answer chimings & ticks',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: appState.soundOn,
                      onChanged: (val) {
                        appState.toggleSound(val);
                        audio.playClick();
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.music_note),
                      title: const Text(
                        'Background Music',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Atmospheric study soundscapes',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: appState.musicOn,
                      onChanged: (val) {
                        audio.playClick();
                        appState.toggleMusic(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Gameplay parameters
              _buildSectionHeader('Default Configurations'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: SwitchListTile(
                  secondary: const Icon(Icons.timer),
                  title: const Text(
                    'Quiz Countdown Timer',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Default timed rules when starting quiz levels',
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

              // Database operations (resets & exports)
              _buildSectionHeader('Backup & Maintenance'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.download, color: colorScheme.primary),
                      title: const Text(
                        'Export Progress Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Download raw JSON of your study stats',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        audio.playClick();
                        _showExportDialog(context, progress);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Reset All Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      subtitle: const Text(
                        'Permanently clear all studied counts and levels',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        audio.playClick();
                        _showResetConfirmation(context, progress);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, ProgressProvider progress) {
    final rawJson = jsonEncode(progress.progress.toJson());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Copy this JSON code block to backup or transfer your metrics:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    rawJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: rawJson));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progress JSON copied to clipboard!'),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Copy & Close'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, ProgressProvider progress) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset All Data?'),
          content: const Text(
            'This action is irreversible. You will lose your study statistics, unlocked levels, bookmarks, and badges.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await progress.resetProgress();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been cleared.')),
                );
              },
              child: const Text(
                'Reset Everything',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
