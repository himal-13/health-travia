import 'package:flutter/material.dart';
import 'package:trivia_game/models/user_progress.dart';
import 'package:trivia_game/models/course.dart';
import 'package:trivia_game/models/achievement.dart';
import 'package:trivia_game/services/storage_service.dart';
import 'package:trivia_game/services/audio_service.dart';

class ProgressProvider extends ChangeNotifier {
  final StorageService _storage;
  final AudioService _audio;

  late UserProgress _progress;
  late List<Achievement> _achievements;
  
  // Local trigger for achievement popup
  Achievement? newlyUnlockedAchievement;

  ProgressProvider(this._storage, this._audio) {
    _progress = _storage.getProgress();
    _achievements = _storage.getAchievements();
    // Daily streak check on startup
    _checkDailyStreak();
  }

  UserProgress get progress => _progress;
  List<Achievement> get achievements => _achievements;

  int get totalQuestionsStudied => _progress.studiedQuestions.length;
  double get accuracy => _progress.accuracyPercentage;
  int get multiplayerWins => _progress.multiplayerWins;
  int get currentStreak => _progress.currentStreak;
  int get bestStreak => _progress.bestStreak;

  // --- Record Study Event ---
  Future<void> markAsStudied(Question question) async {
    if (_progress.studiedQuestions.contains(question.uniqueKey)) return;

    final updatedStudied = Set<String>.from(_progress.studiedQuestions)..add(question.uniqueKey);
    
    _progress = UserProgress(
      studiedQuestions: updatedStudied,
      quizAttempts: _progress.quizAttempts,
      correctAnswers: _progress.correctAnswers,
      totalAnswers: _progress.totalAnswers,
      multiplayerWins: _progress.multiplayerWins,
      bestStreak: _progress.bestStreak,
      currentStreak: _progress.currentStreak,
      lastActiveDate: _progress.lastActiveDate,
      completedLevels: _progress.completedLevels,
      timeStudiedSeconds: _progress.timeStudiedSeconds,
      topicStats: _progress.topicStats,
    );

    await _storage.saveProgress(_progress);
    _checkDailyStreak(); // update active date
    _checkAchievements();
    notifyListeners();
  }

  // --- Record Quiz Event ---
  Future<void> recordQuizResult({
    required String courseName,
    required int level,
    required int correct,
    required int total,
    required Map<String, Map<String, int>> sessionTopicStats,
  }) async {
    final updatedLevels = Set<String>.from(_progress.completedLevels);
    final isLevelPassed = (correct / total) >= 0.70;
    if (isLevelPassed) {
      updatedLevels.add('$courseName:$level');
    }

    // Merge topic stats
    final updatedTopicStats = Map<String, Map<String, int>>.from(
      _progress.topicStats.map((k, v) => MapEntry(k, Map<String, int>.from(v))),
    );
    sessionTopicStats.forEach((topic, stats) {
      final existing = updatedTopicStats.putIfAbsent(topic, () => {'correct': 0, 'total': 0});
      existing['correct'] = (existing['correct'] ?? 0) + (stats['correct'] ?? 0);
      existing['total'] = (existing['total'] ?? 0) + (stats['total'] ?? 0);
    });

    _progress = UserProgress(
      studiedQuestions: _progress.studiedQuestions,
      quizAttempts: _progress.quizAttempts + 1,
      correctAnswers: _progress.correctAnswers + correct,
      totalAnswers: _progress.totalAnswers + total,
      multiplayerWins: _progress.multiplayerWins,
      bestStreak: _progress.bestStreak,
      currentStreak: _progress.currentStreak,
      lastActiveDate: _progress.lastActiveDate,
      completedLevels: updatedLevels,
      timeStudiedSeconds: _progress.timeStudiedSeconds,
      topicStats: updatedTopicStats,
    );

    await _storage.saveProgress(_progress);
    _checkDailyStreak();
    _checkAchievements(lastQuizCorrect: correct, lastQuizTotal: total, courseName: courseName);
    notifyListeners();
  }

  // --- Record Multiplayer Event ---
  Future<void> recordMultiplayerWin() async {
    _progress = UserProgress(
      studiedQuestions: _progress.studiedQuestions,
      quizAttempts: _progress.quizAttempts,
      correctAnswers: _progress.correctAnswers,
      totalAnswers: _progress.totalAnswers,
      multiplayerWins: _progress.multiplayerWins + 1,
      bestStreak: _progress.bestStreak,
      currentStreak: _progress.currentStreak,
      lastActiveDate: _progress.lastActiveDate,
      completedLevels: _progress.completedLevels,
      timeStudiedSeconds: _progress.timeStudiedSeconds,
      topicStats: _progress.topicStats,
    );

    await _storage.saveProgress(_progress);
    _checkDailyStreak();
    _checkAchievements();
    notifyListeners();
  }

  // --- Record Study Time ---
  Future<void> addStudyTime(int seconds) async {
    _progress = UserProgress(
      studiedQuestions: _progress.studiedQuestions,
      quizAttempts: _progress.quizAttempts,
      correctAnswers: _progress.correctAnswers,
      totalAnswers: _progress.totalAnswers,
      multiplayerWins: _progress.multiplayerWins,
      bestStreak: _progress.bestStreak,
      currentStreak: _progress.currentStreak,
      lastActiveDate: _progress.lastActiveDate,
      completedLevels: _progress.completedLevels,
      timeStudiedSeconds: _progress.timeStudiedSeconds + seconds,
      topicStats: _progress.topicStats,
    );
    await _storage.saveProgress(_progress);
  }

  // --- Streak Tracking ---
  void _checkDailyStreak() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (_progress.lastActiveDate == todayStr) return;

    int newStreak = _progress.currentStreak;
    int newBest = _progress.bestStreak;

    if (_progress.lastActiveDate.isNotEmpty) {
      final lastActive = DateTime.parse(_progress.lastActiveDate);
      final today = DateTime.parse(todayStr);
      final difference = today.difference(lastActive).inDays;

      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    if (newStreak > newBest) {
      newBest = newStreak;
    }

    _progress = UserProgress(
      studiedQuestions: _progress.studiedQuestions,
      quizAttempts: _progress.quizAttempts,
      correctAnswers: _progress.correctAnswers,
      totalAnswers: _progress.totalAnswers,
      multiplayerWins: _progress.multiplayerWins,
      bestStreak: newBest,
      currentStreak: newStreak,
      lastActiveDate: todayStr,
      completedLevels: _progress.completedLevels,
      timeStudiedSeconds: _progress.timeStudiedSeconds,
      topicStats: _progress.topicStats,
    );
    _storage.saveProgress(_progress);
  }

  // --- Reset Stats ---
  Future<void> resetProgress() async {
    await _storage.clearAllData();
    _progress = UserProgress.initial();
    _achievements = _storage.getAchievements();
    notifyListeners();
  }

  // --- Achievement Logic ---
  void dismissAchievementPopup() {
    newlyUnlockedAchievement = null;
    notifyListeners();
  }

  void _checkAchievements({
    int? lastQuizCorrect,
    int? lastQuizTotal,
    String? courseName,
  }) async {
    final toUnlock = <String>[];

    // 1. First Steps (first quiz completed)
    if (_progress.quizAttempts >= 1) {
      toUnlock.add('first_quiz');
    }

    // 2. Diligent Student (100+ questions studied)
    if (_progress.studiedQuestions.length >= 100) {
      toUnlock.add('study_100');
    }

    // 3. Trivia Champion (10 multiplayer wins)
    if (_progress.multiplayerWins >= 10) {
      toUnlock.add('multiplayer_10');
    }

    // 4. Perfect Score
    if (lastQuizCorrect != null && lastQuizTotal != null && lastQuizCorrect == lastQuizTotal && lastQuizTotal > 0) {
      toUnlock.add('perfect_score');
    }

    // 5. Anatomy Master (100% on Anatomy & Physiology level)
    if (courseName != null &&
        lastQuizCorrect != null &&
        lastQuizTotal != null &&
        lastQuizCorrect == lastQuizTotal &&
        _progress.topicStats['Anatomy & Physiology'] != null &&
        (_progress.topicStats['Anatomy & Physiology']!['correct'] ?? 0) >= 20) {
      toUnlock.add('anatomy_master');
    }

    // 6. First Aid Expert (100% on First Aid level)
    if (courseName != null &&
        lastQuizCorrect != null &&
        lastQuizTotal != null &&
        lastQuizCorrect == lastQuizTotal &&
        _progress.topicStats['First Aid'] != null &&
        (_progress.topicStats['First Aid']!['correct'] ?? 0) >= 20) {
      toUnlock.add('first_aid_expert');
    }

    // 7. Week of Wisdom (7 day streak)
    if (_progress.bestStreak >= 7) {
      toUnlock.add('streak_7');
    }

    bool updated = false;
    for (final id in toUnlock) {
      final index = _achievements.indexWhere((a) => a.id == id);
      if (index != -1 && !_achievements[index].isUnlocked) {
        _achievements[index] = _achievements[index].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        newlyUnlockedAchievement = _achievements[index];
        _audio.playAchievement();
        updated = true;
      }
    }

    if (updated) {
      await _storage.saveAchievements(_achievements);
    }
  }

  // --- Dynamic Stats Evaluation ---
  String get strongestTopic {
    if (_progress.topicStats.isEmpty) return 'N/A';
    String best = 'N/A';
    double bestAcc = -1.0;
    _progress.topicStats.forEach((topic, stats) {
      final total = stats['total'] ?? 0;
      if (total >= 10) {
        final acc = (stats['correct'] ?? 0) / total;
        if (acc > bestAcc) {
          bestAcc = acc;
          best = topic;
        }
      }
    });
    return best;
  }

  String get weakestTopic {
    if (_progress.topicStats.isEmpty) return 'N/A';
    String worst = 'N/A';
    double worstAcc = 2.0;
    _progress.topicStats.forEach((topic, stats) {
      final total = stats['total'] ?? 0;
      if (total >= 10) {
        final acc = (stats['correct'] ?? 0) / total;
        if (acc < worstAcc) {
          worstAcc = acc;
          worst = topic;
        }
      }
    });
    return worst;
  }
}
