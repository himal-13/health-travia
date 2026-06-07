import 'dart:convert';
import 'dart:io';

void main() {
  print('========================================');
  print('RUNNING DYNAMIC DATABASE SANITY CHECKS');
  print('========================================');

  _verifyCourse('assets/courses/health_assistant.json', 'Health Assistant');
  _verifyCourse('assets/courses/staff_nurse.json', 'Staff Nurse');

  _verifyAudioFiles();

  print('========================================');
  print('SANITY CHECKS COMPLETED SUCCESSFULLY');
  print('========================================');
}

void _verifyCourse(String path, String expectedName) {
  final file = File(path);
  if (!file.existsSync()) {
    print('FAIL: Database file not found at $path');
    exit(1);
  }

  final content = file.readAsStringSync();
  final List<dynamic> list = jsonDecode(content) as List<dynamic>;

  print('Database: $expectedName');
  print(' - Total Questions: ${list.length}');
  
  if (list.length < 500) {
    print('FAIL: $expectedName does not contain at least 500 questions (Actual: ${list.length})');
    exit(1);
  }

  final Set<String> uniqueKeys = {};
  final Map<int, int> difficultyCount = {};

  for (var i = 0; i < list.length; i++) {
    final q = list[i] as Map<String, dynamic>;
    
    // Check fields
    if (q['course'] != expectedName) {
      print('FAIL: Question at index $i belongs to course "${q['course']}" instead of "$expectedName"');
      exit(1);
    }
    if (q['topic'] == null || (q['topic'] as String).isEmpty) {
      print('FAIL: Question at index $i has empty topic');
      exit(1);
    }
    if (q['question'] == null || (q['question'] as String).isEmpty) {
      print('FAIL: Question at index $i has empty question text');
      exit(1);
    }
    final options = q['options'] as List;
    if (options.length != 4) {
      print('FAIL: Question at index $i does not have exactly 4 options');
      exit(1);
    }
    final answer = q['answer'] as int;
    if (answer < 0 || answer > 3) {
      print('FAIL: Question at index $i has invalid answer index $answer');
      exit(1);
    }
    if (q['explanation'] == null || (q['explanation'] as String).isEmpty) {
      print('FAIL: Question at index $i has empty explanation');
      exit(1);
    }

    // Check duplicates
    final key = '${q['course']}:${q['topic']}:${q['question']}';
    if (uniqueKeys.contains(key)) {
      print('FAIL: Duplicate question found at index $i: "${q['question']}"');
      exit(1);
    }
    uniqueKeys.add(key);

    // Difficulty count
    final diff = q['difficulty'] as int;
    difficultyCount[diff] = (difficultyCount[diff] ?? 0) + 1;
  }

  print(' - Unique Questions Verified: ${uniqueKeys.length}');
  print(' - Difficulty Distribution:');
  difficultyCount.forEach((k, v) {
    print('    * Level $k: $v questions');
  });
  print(' - SUCCESS: $expectedName database is valid.');
}

void _verifyAudioFiles() {
  print('Verifying Audio WAV Assets:');
  final requiredWavs = [
    'click.wav',
    'correct.wav',
    'wrong.wav',
    'level_complete.wav',
    'achievement.wav',
    'multiplayer_win.wav',
  ];

  for (final wavName in requiredWavs) {
    final path = 'assets/audio/$wavName';
    final file = File(path);
    if (!file.existsSync()) {
      print('FAIL: Required audio file not found at $path');
      exit(1);
    }
    final size = file.lengthSync();
    if (size < 44) {
      print('FAIL: WAV file $wavName is corrupt (size too small: $size bytes)');
      exit(1);
    }
    
    // Check RIFF header
    final bytes = file.readAsBytesSync();
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') {
      print('FAIL: $wavName has invalid RIFF/WAVE header formats');
      exit(1);
    }
    print(' - $wavName: OK (${size} bytes)');
  }
  print(' - SUCCESS: All audio assets verified.');
}
