import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/audio');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  
  _writeWav(dir.path + '/click.wav', _generateClick());
  _writeWav(dir.path + '/correct.wav', _generateCorrect());
  _writeWav(dir.path + '/wrong.wav', _generateWrong());
  _writeWav(dir.path + '/level_complete.wav', _generateLevelComplete());
  _writeWav(dir.path + '/achievement.wav', _generateAchievement());
  _writeWav(dir.path + '/multiplayer_win.wav', _generateMultiplayerWin());
  print('WAV files generated successfully in assets/audio/');
}

void _writeWav(String path, List<int> samples) {
  final sampleRate = 22050;
  final channels = 1;
  final bitsPerSample = 16;
  
  final file = File(path);
  final bytes = BytesBuilder();
  
  // Header
  bytes.add(Uint8List.fromList('RIFF'.codeUnits));
  final dataSize = samples.length * 2;
  final fileSize = 36 + dataSize;
  bytes.add(_int32ToBytes(fileSize));
  
  bytes.add(Uint8List.fromList('WAVE'.codeUnits));
  bytes.add(Uint8List.fromList('fmt '.codeUnits));
  bytes.add(_int32ToBytes(16));
  bytes.add(_int16ToBytes(1));
  bytes.add(_int16ToBytes(channels));
  bytes.add(_int32ToBytes(sampleRate));
  final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  bytes.add(_int32ToBytes(byteRate));
  final blockAlign = channels * (bitsPerSample ~/ 8);
  bytes.add(_int16ToBytes(blockAlign));
  bytes.add(_int16ToBytes(bitsPerSample));
  
  bytes.add(Uint8List.fromList('data'.codeUnits));
  bytes.add(_int32ToBytes(dataSize));
  
  for (final sample in samples) {
    bytes.add(_int16ToBytes(sample));
  }
  
  file.writeAsBytesSync(bytes.toBytes());
}

Uint8List _int32ToBytes(int value) {
  final bytes = Uint8List(4);
  bytes[0] = value & 0xff;
  bytes[1] = (value >> 8) & 0xff;
  bytes[2] = (value >> 16) & 0xff;
  bytes[3] = (value >> 24) & 0xff;
  return bytes;
}

Uint8List _int16ToBytes(int value) {
  final bytes = Uint8List(2);
  bytes[0] = value & 0xff;
  bytes[1] = (value >> 8) & 0xff;
  return bytes;
}

List<int> _generateClick() {
  final samples = <int>[];
  final sampleRate = 22050;
  final duration = 0.05;
  final numSamples = (sampleRate * duration).toInt();
  final freq = 1200.0;
  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final envelope = exp(-t * 120.0);
    final val = (sin(2 * pi * freq * t) * 16000 * envelope).toInt();
    samples.add(val);
  }
  return samples;
}

List<int> _generateCorrect() {
  final samples = <int>[];
  final sampleRate = 22050;
  final duration1 = 0.12;
  final duration2 = 0.28;
  final numSamples1 = (sampleRate * duration1).toInt();
  final numSamples2 = (sampleRate * duration2).toInt();
  
  for (var i = 0; i < numSamples1; i++) {
    final t = i / sampleRate;
    final envelope = (1.0 - (i / numSamples1) * 0.2);
    final val = (sin(2 * pi * 523.25 * t) * 12000 * envelope).toInt();
    samples.add(val);
  }
  for (var i = 0; i < numSamples2; i++) {
    final t = i / sampleRate;
    final envelope = (1.0 - (i / numSamples2));
    final val = (sin(2 * pi * 659.25 * t) * 12000 * envelope).toInt();
    samples.add(val);
  }
  return samples;
}

List<int> _generateWrong() {
  final samples = <int>[];
  final sampleRate = 22050;
  final duration = 0.45;
  final numSamples = (sampleRate * duration).toInt();
  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final envelope = (1.0 - (i / numSamples));
    final wave1 = sin(2 * pi * 120.0 * t);
    final wave2 = sin(2 * pi * 123.0 * t);
    final val = (((wave1 + wave2) / 2.0) * 14000 * envelope).toInt();
    samples.add(val);
  }
  return samples;
}

List<int> _generateLevelComplete() {
  final samples = <int>[];
  final sampleRate = 22050;
  final notes = [261.63, 329.63, 392.00, 523.25];
  final noteDuration = 0.18;
  
  for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
    final freq = notes[noteIndex];
    final isLast = noteIndex == notes.length - 1;
    final duration = isLast ? 0.5 : noteDuration;
    final totalSamples = (sampleRate * duration).toInt();
    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      var envelope = 1.0;
      if (isLast) {
        envelope = (1.0 - (i / totalSamples));
      } else {
        envelope = (1.0 - (i / totalSamples) * 0.3);
      }
      final val = (sin(2 * pi * freq * t) * 10000 * envelope).toInt();
      samples.add(val);
    }
  }
  return samples;
}

List<int> _generateAchievement() {
  final samples = <int>[];
  final sampleRate = 22050;
  final notes = [523.25, 659.25, 783.99, 1046.50];
  final noteDuration = 0.12;
  
  for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
    final freq = notes[noteIndex];
    final isLast = noteIndex == notes.length - 1;
    final duration = isLast ? 0.4 : noteDuration;
    final totalSamples = (sampleRate * duration).toInt();
    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      var envelope = 1.0;
      if (isLast) {
        envelope = (1.0 - (i / totalSamples));
      } else {
        envelope = (1.0 - (i / totalSamples) * 0.3);
      }
      final val = (sin(2 * pi * freq * t) * 8000 * envelope).toInt();
      samples.add(val);
    }
  }
  return samples;
}

List<int> _generateMultiplayerWin() {
  final samples = <int>[];
  final sampleRate = 22050;
  final frequencies = [261.63, 392.00, 523.25, 659.25];
  final durations = [0.15, 0.15, 0.15, 0.6];
  
  for (var idx = 0; idx < frequencies.length; idx++) {
    final freq = frequencies[idx];
    final duration = durations[idx];
    final totalSamples = (sampleRate * duration).toInt();
    final isLast = idx == frequencies.length - 1;
    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      var currentFreq = freq;
      if (isLast) {
        currentFreq += 6.0 * sin(2 * pi * 8.0 * t);
      }
      var envelope = 1.0;
      if (isLast) {
        envelope = (1.0 - (i / totalSamples));
      }
      final val = (sin(2 * pi * currentFreq * t) * 9000 * envelope).toInt();
      samples.add(val);
    }
  }
  return samples;
}
