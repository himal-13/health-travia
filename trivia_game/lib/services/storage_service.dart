import 'dart:convert';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:trivia_game/models/user_progress.dart';
import 'package:trivia_game/models/bookmark.dart';
import 'package:trivia_game/models/achievement.dart';

class StorageService {
  static const String _settingsBoxName = 'settings_box';
  static const String _progressBoxName = 'progress_box';
  static const String _bookmarksBoxName = 'bookmarks_box';
  static const String _achievementsBoxName = 'achievements_box';

  late Box _settingsBox;
  late Box _progressBox;
  late Box _bookmarksBox;
  late Box _achievementsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _progressBox = await Hive.openBox(_progressBoxName);
    _bookmarksBox = await Hive.openBox(_bookmarksBoxName);
    _achievementsBox = await Hive.openBox(_achievementsBoxName);
  }

  // --- Settings ---
  String get themeMode => _settingsBox.get('themeMode', defaultValue: 'system') as String;
  set themeMode(String value) => _settingsBox.put('themeMode', value);

  bool get soundOn => _settingsBox.get('soundOn', defaultValue: true) as bool;
  set soundOn(bool value) => _settingsBox.put('soundOn', value);

  bool get musicOn => _settingsBox.get('musicOn', defaultValue: true) as bool;
  set musicOn(bool value) => _settingsBox.put('musicOn', value);

  bool get timerMode => _settingsBox.get('timerMode', defaultValue: true) as bool;
  set timerMode(bool value) => _settingsBox.put('timerMode', value);

  // --- Progress ---
  UserProgress getProgress() {
    final raw = _progressBox.get('user_progress');
    if (raw == null) return UserProgress.initial();
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      return UserProgress.fromJson(decoded);
    } catch (_) {
      return UserProgress.initial();
    }
  }

  Future<void> saveProgress(UserProgress progress) async {
    final encoded = jsonEncode(progress.toJson());
    await _progressBox.put('user_progress', encoded);
  }

  // --- Bookmarks ---
  List<Bookmark> getBookmarks() {
    final rawList = _bookmarksBox.get('bookmarks_list', defaultValue: []) as List;
    return rawList.map((item) {
      final decoded = jsonDecode(item as String) as Map<String, dynamic>;
      return Bookmark.fromJson(decoded);
    }).toList();
  }

  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final encodedList = bookmarks.map((b) => jsonEncode(b.toJson())).toList();
    await _bookmarksBox.put('bookmarks_list', encodedList);
  }

  // --- Achievements ---
  List<Achievement> getAchievements() {
    final rawList = _achievementsBox.get('achievements_list', defaultValue: []) as List;
    if (rawList.isEmpty) {
      return _defaultAchievements();
    }
    return rawList.map((item) {
      final decoded = jsonDecode(item as String) as Map<String, dynamic>;
      return Achievement.fromJson(decoded);
    }).toList();
  }

  Future<void> saveAchievements(List<Achievement> achievements) async {
    final encodedList = achievements.map((a) => jsonEncode(a.toJson())).toList();
    await _achievementsBox.put('achievements_list', encodedList);
  }

  List<Achievement> _defaultAchievements() {
    return [
      Achievement(
        id: 'first_quiz',
        title: 'First Steps',
        description: 'Complete your first quiz practice session.',
        iconName: 'quiz',
      ),
      Achievement(
        id: 'study_100',
        title: 'Diligent Student',
        description: 'Browse and study 100 questions in Study Mode.',
        iconName: 'school',
      ),
      Achievement(
        id: 'multiplayer_10',
        title: 'Trivia Champion',
        description: 'Win 10 local multiplayer battles.',
        iconName: 'emoji_events',
      ),
      Achievement(
        id: 'anatomy_master',
        title: 'Anatomy Master',
        description: 'Achieve 100% in an Anatomy & Physiology level.',
        iconName: 'accessibility_new',
      ),
      Achievement(
        id: 'first_aid_expert',
        title: 'First Responder',
        description: 'Achieve 100% in a First Aid level.',
        iconName: 'local_hospital',
      ),
      Achievement(
        id: 'perfect_score',
        title: 'Flawless Victory',
        description: 'Score a perfect 100% on any level quiz.',
        iconName: 'star',
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week of Wisdom',
        description: 'Maintain a 7-day learning streak.',
        iconName: 'calendar_today',
      ),
    ];
  }

  // --- Reset All Data ---
  Future<void> clearAllData() async {
    await _settingsBox.clear();
    await _progressBox.clear();
    await _bookmarksBox.clear();
    await _achievementsBox.clear();
  }
}
