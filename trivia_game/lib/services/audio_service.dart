import 'package:flame_audio/flame_audio.dart';
import 'package:trivia_game/services/storage_service.dart';

class AudioService {
  final StorageService _storage;

  AudioService(this._storage) {
    // Initialize Flame Audio BGM system
    try {
      FlameAudio.bgm.initialize();
    } catch (e) {
      print('Failed to initialize Flame Audio BGM: $e');
    }
  }

  void playClick() {
    _play('click.wav');
  }

  void playCorrect() {
    _play('correct.wav');
  }

  void playWrong() {
    _play('wrong.wav');
  }

  void playLevelComplete() {
    _play('level_complete.wav');
  }

  void playAchievement() {
    _play('achievement.wav');
  }

  void playMultiplayerWin() {
    _play('multiplayer_win.wav');
  }

  void _play(String fileName) {
    if (!_storage.soundOn) return;
    try {
      FlameAudio.play(fileName);
    } catch (e) {
      print('AudioService: error playing $fileName: $e');
    }
  }
}
