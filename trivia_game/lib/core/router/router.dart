import 'package:go_router/go_router.dart';
import 'package:trivia_game/features/home/home_screen.dart';
import 'package:trivia_game/features/study/study_screen.dart';
import 'package:trivia_game/features/quiz/quiz_screen.dart';
import 'package:trivia_game/features/multiplayer/multiplayer_screen.dart';
import 'package:trivia_game/features/progress/statistics_screen.dart';
import 'package:trivia_game/features/settings/settings_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/study',
      builder: (context, state) => const StudyScreen(),
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => const QuizScreen(),
    ),
    GoRoute(
      path: '/multiplayer',
      builder: (context, state) => const MultiplayerScreen(),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
