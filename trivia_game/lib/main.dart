import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trivia_game/core/router/router.dart';
import 'package:trivia_game/services/storage_service.dart';
import 'package:trivia_game/services/audio_service.dart';
import 'package:trivia_game/services/course_importer.dart';
import 'package:trivia_game/providers/app_state_provider.dart';
import 'package:trivia_game/providers/progress_provider.dart';
import 'package:trivia_game/providers/study_provider.dart';
import 'package:trivia_game/providers/quiz_provider.dart';
import 'package:trivia_game/providers/multiplayer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline storage service
  final storage = StorageService();
  await storage.init();

  // Initialize audio playback service
  final audio = AudioService(storage);

  // Load course databases
  final courses = await CourseImporter.importAllCourses();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<AudioService>.value(value: audio),
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(storage),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider(storage, audio),
        ),
        ChangeNotifierProvider<StudyProvider>(
          create: (_) => StudyProvider(storage)..initialize(courses),
        ),
        ChangeNotifierProvider<QuizProvider>(
          create: (_) => QuizProvider(audio),
        ),
        ChangeNotifierProvider<MultiplayerProvider>(
          create: (_) => MultiplayerProvider(audio)..initialize(courses),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return MaterialApp.router(
      title: 'Health Trivia Prep',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056B3), // Professional medical blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056B3),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      routerConfig: router,
    );
  }
}
