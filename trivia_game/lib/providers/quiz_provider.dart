import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trivia_game/models/course.dart';
import 'package:trivia_game/services/audio_service.dart';
import 'package:trivia_game/providers/progress_provider.dart';

class QuizProvider extends ChangeNotifier {
  final AudioService _audio;

  // Quiz Setup
  String _courseName = '';
  int _level = 1;
  List<Question> _quizQuestions = [];
  List<List<String>> _shuffledOptionsList = [];
  List<int> _originalAnswerIndices = []; // Maps shuffled option index back to original index

  // Gameplay State
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex; // Shuffled index selected by user
  bool _hasAnswered = false;
  int _score = 0;
  int _timerSeconds = 30;
  Timer? _timer;
  bool _isQuizActive = false;
  bool _isQuizFinished = false;

  // Performance Tracking
  Map<String, Map<String, int>> _sessionTopicStats = {}; // "Topic" -> {"correct": count, "total": count}
  DateTime? _startTime;
  Duration _timeTaken = Duration.zero;

  QuizProvider(this._audio);

  // Getters
  String get courseName => _courseName;
  int get level => _level;
  List<Question> get questions => _quizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get hasAnswered => _hasAnswered;
  int get score => _score;
  int get timerSeconds => _timerSeconds;
  bool get isQuizActive => _isQuizActive;
  bool get isQuizFinished => _isQuizFinished;
  Duration get timeTaken => _timeTaken;
  List<String> get currentOptions =>
      _quizQuestions.isNotEmpty ? _shuffledOptionsList[_currentQuestionIndex] : [];

  Question? get currentQuestion =>
      _quizQuestions.isNotEmpty ? _quizQuestions[_currentQuestionIndex] : null;

  // Start a Quiz
  void startQuiz({
    required Course course,
    required int level,
    required bool timerEnabled,
  }) {
    _courseName = course.name;
    _level = level;
    _currentQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _hasAnswered = false;
    _score = 0;
    _isQuizActive = true;
    _isQuizFinished = false;
    _sessionTopicStats = {};
    _startTime = DateTime.now();
    _timeTaken = Duration.zero;

    // Filter questions of this course matching the difficulty (level maps 1-5 to difficulty 1-5)
    final available = course.allQuestions
        .where((q) => q.difficulty == level)
        .toList();

    // Take 20 random questions
    available.shuffle();
    _quizQuestions = available.take(20).toList();

    // Prepare shuffled options for each question
    _shuffledOptionsList = [];
    _originalAnswerIndices = [];
    for (final q in _quizQuestions) {
      final list = List<String>.from(q.options);
      final indexedOptions = list.asMap().entries.toList();
      indexedOptions.shuffle();

      final shuffledOpts = indexedOptions.map((e) => e.value).toList();
      _shuffledOptionsList.add(shuffledOpts);

      // Find where the correct answer ended up
      final correctShuffledIdx = indexedOptions.indexWhere((e) => e.key == q.answerIndex);
      _originalAnswerIndices.add(correctShuffledIdx);
    }

    if (timerEnabled) {
      _startQuestionTimer();
    }
    notifyListeners();
  }

  // Answer a Question
  void answerQuestion(int shuffledIndex, bool timerEnabled, ProgressProvider progress) {
    if (_hasAnswered) return;

    _timer?.cancel();
    _selectedAnswerIndex = shuffledIndex;
    _hasAnswered = true;

    final correctIndex = _originalAnswerIndices[_currentQuestionIndex];
    final isCorrect = shuffledIndex == correctIndex;
    final question = _quizQuestions[_currentQuestionIndex];

    // Track topic statistics
    final stats = _sessionTopicStats.putIfAbsent(question.topic, () => {'correct': 0, 'total': 0});
    stats['total'] = (stats['total'] ?? 0) + 1;

    if (isCorrect) {
      _score++;
      stats['correct'] = (stats['correct'] ?? 0) + 1;
      _audio.playCorrect();
    } else {
      _audio.playWrong();
    }

    notifyListeners();
  }

  // Go to Next Question
  void nextQuestion(bool timerEnabled, ProgressProvider progress) {
    _timer?.cancel();
    _selectedAnswerIndex = null;
    _hasAnswered = false;

    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      _currentQuestionIndex++;
      if (timerEnabled) {
        _startQuestionTimer();
      }
    } else {
      _finishQuiz(progress);
    }
    notifyListeners();
  }

  // Handle Timeout
  void _handleTimeout() {
    _hasAnswered = true;
    _selectedAnswerIndex = -1; // No selection counts as wrong
    final question = _quizQuestions[_currentQuestionIndex];
    final stats = _sessionTopicStats.putIfAbsent(question.topic, () => {'correct': 0, 'total': 0});
    stats['total'] = (stats['total'] ?? 0) + 1;

    _audio.playWrong();
    notifyListeners();
  }

  // Finish Quiz
  void _finishQuiz(ProgressProvider progress) {
    _isQuizActive = false;
    _isQuizFinished = true;
    _timer?.cancel();

    if (_startTime != null) {
      _timeTaken = DateTime.now().difference(_startTime!);
    }

    // Save results to user progress in Hive
    progress.recordQuizResult(
      courseName: _courseName,
      level: _level,
      correct: _score,
      total: _quizQuestions.length,
      sessionTopicStats: _sessionTopicStats,
    );

    // Audio cue for completion
    final passed = (_score / _quizQuestions.length) >= 0.70;
    if (passed) {
      _audio.playLevelComplete();
    }
  }

  // Reset Quiz State
  void quitQuiz() {
    _timer?.cancel();
    _isQuizActive = false;
    _isQuizFinished = false;
    _quizQuestions = [];
    notifyListeners();
  }

  // Start Countdown Timer
  void _startQuestionTimer() {
    _timerSeconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        _timerSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Evaluates weak and strong topics from the current quiz session
  List<String> get strongTopics {
    final list = <String>[];
    _sessionTopicStats.forEach((topic, stats) {
      final total = stats['total'] ?? 0;
      final acc = (stats['correct'] ?? 0) / total;
      if (acc >= 0.75) {
        list.add(topic);
      }
    });
    return list;
  }

  List<String> get weakTopics {
    final list = <String>[];
    _sessionTopicStats.forEach((topic, stats) {
      final total = stats['total'] ?? 0;
      final acc = (stats['correct'] ?? 0) / total;
      if (acc < 0.70) {
        list.add(topic);
      }
    });
    return list;
  }
}
