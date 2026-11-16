import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/features/games/chess/chess_screen.dart'
    deferred as chess_lib;
import 'package:zetzy/features/games/minesweeper/minesweeper_screen.dart'
    deferred as minesweeper_lib;
import 'package:zetzy/features/games/snake/snake_screen.dart'
    deferred as snake_lib;
import 'package:zetzy/features/games/sudoku/sudoku_screen.dart'
    deferred as sudoku_lib;
import 'package:zetzy/features/feedback/feedback_screen.dart';
import 'package:zetzy/features/shell/main_shell.dart';

/// Arguments passed when navigating to one of the 4 game routes.
class GameRouteArgs {
  const GameRouteArgs({
    required this.difficulty,
    this.isPractice = false,
    this.resumeSlot,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final AutoSaveSlot? resumeSlot;
}

/// Named route paths and URL deep-link generator for Web & Cross-Platform.
///
/// Supports:
/// - Main shell tabs: `/`, `/play`, `/leaderboard`, `/stats`, `/profile`
/// - Game routes: `/sudoku`, `/chess`, `/minesweeper`, `/snake`
///   (with optional query params, e.g. `/#/chess?level=3&practice=1`)
abstract final class AppRouter {
  static const String home = '/';
  static const String play = '/play';
  static const String leaderboard = '/leaderboard';
  static const String stats = '/stats';
  static const String profile = '/profile';
  static const String feedback = '/feedback';

  static const String sudoku = '/sudoku';
  static const String chess = '/chess';
  static const String minesweeper = '/minesweeper';
  static const String snake = '/snake';

  static String routeForGame(GameType gameType) => switch (gameType) {
    GameType.sudoku => sudoku,
    GameType.chess => chess,
    GameType.minesweeper => minesweeper,
    GameType.snake => snake,
  };

  static String routeForTab(int index) => switch (index) {
    0 => play,
    1 => leaderboard,
    2 => stats,
    3 => profile,
    _ => play,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final rawName = settings.name ?? home;
    final uri = Uri.tryParse(rawName) ?? Uri(path: home);
    final path = uri.path.isEmpty ? home : uri.path;

    switch (path) {
      case home:
      case play:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MainShell(initialTab: 0),
        );
      case leaderboard:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MainShell(initialTab: 1),
        );
      case stats:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MainShell(initialTab: 2),
        );
      case profile:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MainShell(initialTab: 3),
        );
      case feedback:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const FeedbackScreen(),
        );
      case sudoku:
        final args = _resolveGameArgs(settings.arguments, uri);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _DeferredGameScreen(
            loadLibrary: sudoku_lib.loadLibrary,
            builder: () => sudoku_lib.SudokuScreen(
              difficulty: args.difficulty,
              isPractice: args.isPractice,
              resumeSlot: args.resumeSlot,
            ),
          ),
        );
      case chess:
        final args = _resolveGameArgs(settings.arguments, uri);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _DeferredGameScreen(
            loadLibrary: chess_lib.loadLibrary,
            builder: () => chess_lib.ChessScreen(
              difficulty: args.difficulty,
              isPractice: args.isPractice,
              resumeSlot: args.resumeSlot,
            ),
          ),
        );
      case minesweeper:
        final args = _resolveGameArgs(settings.arguments, uri);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _DeferredGameScreen(
            loadLibrary: minesweeper_lib.loadLibrary,
            builder: () => minesweeper_lib.MinesweeperScreen(
              difficulty: args.difficulty,
              isPractice: args.isPractice,
              resumeSlot: args.resumeSlot,
            ),
          ),
        );
      case snake:
        final args = _resolveGameArgs(settings.arguments, uri);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _DeferredGameScreen(
            loadLibrary: snake_lib.loadLibrary,
            builder: () => snake_lib.SnakeScreen(
              difficulty: args.difficulty,
              isPractice: args.isPractice,
              resumeSlot: args.resumeSlot,
            ),
          ),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MainShell(initialTab: 0),
        );
    }
  }

  static GameRouteArgs _resolveGameArgs(Object? arguments, Uri uri) {
    if (arguments is GameRouteArgs) return arguments;
    final levelParam = int.tryParse(uri.queryParameters['level'] ?? '');
    final practiceParam = uri.queryParameters['practice'];
    final isPractice = practiceParam == '1' || practiceParam == 'true';
    return GameRouteArgs(
      difficulty: DifficultyLevel.fromLevel(
        (levelParam ?? 1).clamp(1, 5),
      ),
      isPractice: isPractice,
    );
  }
}

class _DeferredGameScreen extends StatefulWidget {
  const _DeferredGameScreen({
    required this.loadLibrary,
    required this.builder,
  });

  final Future<void> Function() loadLibrary;
  final Widget Function() builder;

  @override
  State<_DeferredGameScreen> createState() => _DeferredGameScreenState();
}

class _DeferredGameScreenState extends State<_DeferredGameScreen> {
  late final Future<void> _future = widget.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.builder();
      },
    );
  }
}
