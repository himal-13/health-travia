import 'package:flutter/material.dart';
import 'package:trivia_game/models/course.dart';
import 'package:trivia_game/models/bookmark.dart';
import 'package:trivia_game/services/storage_service.dart';

class StudyProvider extends ChangeNotifier {
  final StorageService _storage;
  List<Course> _courses = [];

  // Active filters
  String? selectedCourse;
  String? selectedTopic;
  int? selectedDifficulty;
  String searchQuery = '';

  List<Bookmark> _bookmarks = [];
  List<Question> _filteredQuestions = [];
  int _currentIndex = 0;

  StudyProvider(this._storage) {
    _bookmarks = _storage.getBookmarks();
  }

  void initialize(List<Course> courses) {
    _courses = courses;
    _updateFilteredQuestions();
  }

  List<Course> get courses => _courses;
  List<Bookmark> get bookmarks => _bookmarks;
  List<Question> get filteredQuestions => _filteredQuestions;
  int get currentIndex => _currentIndex;

  Question? get currentQuestion {
    if (_filteredQuestions.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _filteredQuestions.length) {
      return null;
    }
    return _filteredQuestions[_currentIndex];
  }

  // --- Filtering Actions ---
  void filterCourse(String? course) {
    selectedCourse = course;
    selectedTopic = null; // reset topic when changing course
    _currentIndex = 0;
    _updateFilteredQuestions();
    notifyListeners();
  }

  void filterTopic(String? topic) {
    selectedTopic = topic;
    _currentIndex = 0;
    _updateFilteredQuestions();
    notifyListeners();
  }

  void filterDifficulty(int? difficulty) {
    selectedDifficulty = difficulty;
    _currentIndex = 0;
    _updateFilteredQuestions();
    notifyListeners();
  }

  void updateSearch(String query) {
    searchQuery = query;
    _currentIndex = 0;
    _updateFilteredQuestions();
    notifyListeners();
  }

  void _updateFilteredQuestions() {
    List<Question> all = [];
    if (selectedCourse != null) {
      final course = _courses.firstWhere(
        (c) => c.name.toLowerCase() == selectedCourse!.toLowerCase(),
        orElse: () => _courses.first,
      );
      all = course.allQuestions;
    } else {
      all = _courses.expand((c) => c.allQuestions).toList();
    }

    _filteredQuestions = all.where((q) {
      final matchesTopic =
          selectedTopic == null || q.topic.toLowerCase() == selectedTopic!.toLowerCase();
      final matchesDiff =
          selectedDifficulty == null || q.difficulty == selectedDifficulty;
      final matchesSearch = searchQuery.isEmpty ||
          q.question.toLowerCase().contains(searchQuery.toLowerCase()) ||
          q.explanation.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesTopic && matchesDiff && matchesSearch;
    }).toList();
  }

  // --- Navigation Actions ---
  void nextQuestion() {
    if (_currentIndex < _filteredQuestions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void setIndex(int index) {
    if (index >= 0 && index < _filteredQuestions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // --- Bookmarks Management ---
  bool isBookmarked(Question question) {
    return _bookmarks.any((b) => b.question.uniqueKey == question.uniqueKey);
  }

  Future<void> toggleBookmark(Question question) async {
    final idx =
        _bookmarks.indexWhere((b) => b.question.uniqueKey == question.uniqueKey);
    if (idx != -1) {
      _bookmarks.removeAt(idx);
    } else {
      _bookmarks.add(Bookmark(question: question, bookmarkedAt: DateTime.now()));
    }
    await _storage.saveBookmarks(_bookmarks);
    notifyListeners();
  }
}
