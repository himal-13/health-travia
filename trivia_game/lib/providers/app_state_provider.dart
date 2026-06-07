import 'package:flutter/material.dart';
import 'package:trivia_game/services/storage_service.dart';

class AppStateProvider extends ChangeNotifier {
  final StorageService _storage;

  AppStateProvider(this._storage);

  ThemeMode get themeMode {
    final mode = _storage.themeMode;
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  String get themeModeName => _storage.themeMode;

  bool get soundOn => _storage.soundOn;
  bool get musicOn => _storage.musicOn;
  bool get timerMode => _storage.timerMode;

  void toggleTheme(String mode) {
    _storage.themeMode = mode;
    notifyListeners();
  }

  void toggleSound(bool value) {
    _storage.soundOn = value;
    notifyListeners();
  }

  void toggleMusic(bool value) {
    _storage.musicOn = value;
    notifyListeners();
  }

  void toggleTimer(bool value) {
    _storage.timerMode = value;
    notifyListeners();
  }
}
