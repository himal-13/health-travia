import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trivia_game/models/course.dart';
import 'package:trivia_game/services/audio_service.dart';
import 'package:trivia_game/providers/progress_provider.dart';

enum MultiplayerMode { classic, survival, speed }

class MultiplayerProvider extends ChangeNotifier {
  final AudioService _audio;

  // Setup Options
  MultiplayerMode mode = MultiplayerMode.classic;
  Course? selectedCourse;
  List<Course> _courses = [];

  // Match State
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int p1Score = 0;
  int p2Score = 0;
  int p1Lives = 3;
  int p2Lives = 3;
  int activePlayer = 1; // 1 or 2
  int questionStartPlayer = 1; // Alternates starting player for questions

  List<String> _currentShuffledOptions = [];
  int _correctShuffledIndex = 0;
  final Set<int> _eliminatedOptionIndices = {}; // Wrong selections that vanish

  bool _isGameOver = false;
  int _winner = 0; // 1 = Player 1, 2 = Player 2, 0 = Draw

  // Timer for Speed Battle
  int timerSeconds = 10;
  Timer? _timer;

  MultiplayerProvider(this._audio);

  void initialize(List<Course> courses) {
    _courses = courses;
    if (_courses.isNotEmpty && selectedCourse == null) {
      selectedCourse = _courses.first;
    }
  }

  // Getters
  bool get isGameOver => _isGameOver;
  int get winner => _winner;
  int get currentQuestionIndex => _currentQuestionIndex;
  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;
  List<String> get currentOptions => _currentShuffledOptions;
  Set<int> get eliminatedOptionIndices => _eliminatedOptionIndices;

  // Start the Multiplayer Battle
  void startMatch() {
    _timer?.cancel();
    p1Score = 0;
    p2Score = 0;
    p1Lives = 3;
    p2Lives = 3;
    activePlayer = 1;
    questionStartPlayer = 1;
    _currentQuestionIndex = 0;
    _isGameOver = false;
    _winner = 0;
    _eliminatedOptionIndices.clear();

    List<Question> all = [];
    if (selectedCourse != null) {
      all = selectedCourse!.allQuestions;
    } else {
      all = _courses.expand((c) => c.allQuestions).toList();
    }

    all.shuffle();
    _questions = all.take(50).toList(); // Max 50 questions per match

    _loadQuestion();
  }

  void _loadQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      _finishMatch();
      return;
    }

    final q = _questions[_currentQuestionIndex];
    _eliminatedOptionIndices.clear();

    // Shuffle options
    final indexedOpts = q.options.asMap().entries.toList()..shuffle();
    _currentShuffledOptions = indexedOpts.map((e) => e.value).toList();
    _correctShuffledIndex = indexedOpts.indexWhere((e) => e.key == q.answerIndex);

    // Question start player begins
    activePlayer = questionStartPlayer;

    if (mode == MultiplayerMode.speed) {
      _startTurnTimer();
    }
    notifyListeners();
  }

  // Play Turn
  void chooseOption(int shuffledIndex, ProgressProvider progress) {
    if (_isGameOver || _eliminatedOptionIndices.contains(shuffledIndex)) return;

    _timer?.cancel();
    final isCorrect = shuffledIndex == _correctShuffledIndex;

    if (isCorrect) {
      _audio.playCorrect();
      
      if (activePlayer == 1) {
        p1Score++;
      } else {
        p2Score++;
      }

      // Check Classic mode victory limit (20 points)
      if (mode == MultiplayerMode.classic && (p1Score >= 20 || p2Score >= 20)) {
        _finishMatch(progress: progress);
        return;
      }

      // Alternate question starter
      questionStartPlayer = questionStartPlayer == 1 ? 2 : 1;
      _currentQuestionIndex++;
      _loadQuestion();
    } else {
      _audio.playWrong();
      _eliminatedOptionIndices.add(shuffledIndex);

      // Survival life subtraction
      if (mode == MultiplayerMode.survival) {
        if (activePlayer == 1) {
          p1Lives--;
          if (p1Lives <= 0) {
            _finishMatch(progress: progress);
            return;
          }
        } else {
          p2Lives--;
          if (p2Lives <= 0) {
            _finishMatch(progress: progress);
            return;
          }
        }
      }

      // Standard advance if all but one are eliminated
      if (_eliminatedOptionIndices.length >= 3) {
        questionStartPlayer = questionStartPlayer == 1 ? 2 : 1;
        _currentQuestionIndex++;
        _loadQuestion();
        return;
      }

      // Swap turn
      activePlayer = activePlayer == 1 ? 2 : 1;
      if (mode == MultiplayerMode.speed) {
        _startTurnTimer();
      }
      notifyListeners();
    }
  }

  void _handleTimeout() {
    _timer?.cancel();
    _audio.playWrong();

    // Pass turn to other player on timeout
    activePlayer = activePlayer == 1 ? 2 : 1;
    _startTurnTimer();
    notifyListeners();
  }

  void _startTurnTimer() {
    _timer?.cancel();
    timerSeconds = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        timerSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _finishMatch({ProgressProvider? progress}) {
    _timer?.cancel();
    _isGameOver = true;

    if (mode == MultiplayerMode.survival) {
      if (p1Lives <= 0 && p2Lives > 0) {
        _winner = 2;
      } else if (p2Lives <= 0 && p1Lives > 0) {
        _winner = 1;
      } else {
        _winner = p1Score > p2Score ? 1 : (p2Score > p1Score ? 2 : 0);
      }
    } else {
      if (p1Score > p2Score) {
        _winner = 1;
      } else if (p2Score > p1Score) {
        _winner = 2;
      } else {
        _winner = 0;
      }
    }

    _audio.playMultiplayerWin();

    if (progress != null && _winner > 0) {
      progress.recordMultiplayerWin();
    }
    notifyListeners();
  }

  void quitMatch() {
    _timer?.cancel();
    _isGameOver = false;
    _winner = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
