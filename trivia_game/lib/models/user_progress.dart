class UserProgress {
  final Set<String> studiedQuestions;
  final int quizAttempts;
  final int correctAnswers;
  final int totalAnswers;
  final int multiplayerWins;
  final int bestStreak;
  final int currentStreak;
  final String lastActiveDate; // yyyy-MM-dd
  final Set<String> completedLevels; // Set of "CourseName:Level"
  final int timeStudiedSeconds; // in seconds
  final Map<String, Map<String, int>> topicStats; // "TopicName" -> {"correct": count, "total": count}

  UserProgress({
    required this.studiedQuestions,
    required this.quizAttempts,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.multiplayerWins,
    required this.bestStreak,
    required this.currentStreak,
    required this.lastActiveDate,
    required this.completedLevels,
    required this.timeStudiedSeconds,
    required this.topicStats,
  });

  factory UserProgress.initial() {
    return UserProgress(
      studiedQuestions: {},
      quizAttempts: 0,
      correctAnswers: 0,
      totalAnswers: 0,
      multiplayerWins: 0,
      bestStreak: 0,
      currentStreak: 0,
      lastActiveDate: '',
      completedLevels: {},
      timeStudiedSeconds: 0,
      topicStats: {},
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      studiedQuestions: Set<String>.from(json['studiedQuestions'] as List? ?? []),
      quizAttempts: json['quizAttempts'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalAnswers: json['totalAnswers'] as int? ?? 0,
      multiplayerWins: json['multiplayerWins'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String? ?? '',
      completedLevels: Set<String>.from(json['completedLevels'] as List? ?? []),
      timeStudiedSeconds: json['timeStudiedSeconds'] as int? ?? 0,
      topicStats: (json['topicStats'] as Map?)?.map(
            (k, v) => MapEntry(
              k as String,
              (v as Map).map((ki, vi) => MapEntry(ki as String, vi as int)),
            ),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studiedQuestions': studiedQuestions.toList(),
      'quizAttempts': quizAttempts,
      'correctAnswers': correctAnswers,
      'totalAnswers': totalAnswers,
      'multiplayerWins': multiplayerWins,
      'bestStreak': bestStreak,
      'currentStreak': currentStreak,
      'lastActiveDate': lastActiveDate,
      'completedLevels': completedLevels.toList(),
      'timeStudiedSeconds': timeStudiedSeconds,
      'topicStats': topicStats,
    };
  }

  double get accuracyPercentage {
    if (totalAnswers == 0) return 0.0;
    return (correctAnswers / totalAnswers) * 100;
  }
}
