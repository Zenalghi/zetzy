import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/zetzy_database.dart' hide AutoSaveSlot;
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/features/games/chess/chess_ai.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_controller.dart';
import 'package:zetzy/features/games/minesweeper/minesweeper_engine.dart';
import 'package:zetzy/features/games/snake/snake_controller.dart';
import 'package:zetzy/features/games/sudoku/sudoku_controller.dart';
import 'package:zetzy/features/games/sudoku/sudoku_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Core Validation & Formatters', () {
    test('ValidationRules enforces PRD username & password constraints', () {
      expect(ValidationRules.isValidUsername('zain_99'), isTrue);
      expect(ValidationRules.isValidUsername('ab'), isFalse);
      expect(ValidationRules.isValidUsername('Zain_99'), isFalse);
      expect(ValidationRules.isValidUsername('zain 99'), isFalse);
      expect(
        ValidationRules.dummyEmailFor('zain_99'),
        equals('zain_99@arcade.local'),
      );

      expect(ValidationRules.isValidPassword('abc12345'), isTrue);
      expect(ValidationRules.isValidPassword('12345678'), isFalse);
      expect(ValidationRules.isValidPassword('abcdefgh'), isFalse);
      expect(ValidationRules.isValidPassword('abc123'), isFalse);
    });

    test('TimeFormatter formats MM:SS.ms accurately', () {
      expect(TimeFormatter.formatMs(0), equals('00:00.00'));
      expect(TimeFormatter.formatMs(134850), equals('02:14.85'));
      expect(TimeFormatter.formatClock(60000), equals('01:00'));
    });
  });

  group('Drift LocalStorageService (4 Auto-Save Slots & Offline Queue)', () {
    late ZetzyDatabase db;
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      db = ZetzyDatabase(NativeDatabase.memory());
      storage = LocalStorageService.forTesting(database: db, prefs: prefs);
    });

    tearDown(() async {
      await storage.close();
    });

    test('stores 4 independent game auto-save slots without overwriting', () async {
      for (final game in GameType.values) {
        await storage.saveGameSlot(
          AutoSaveSlot(
            gameType: game,
            difficulty: game.index + 1,
            elapsedMs: (game.index + 1) * 1000,
            stateJson: {'game': game.id},
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }

      final all = await storage.loadAllGameSlots();
      expect(all.length, equals(4));
      expect(all[GameType.sudoku]?.difficulty, equals(1));
      expect(all[GameType.snake]?.difficulty, equals(4));

      await storage.clearGameSlot(GameType.sudoku);
      final afterClear = await storage.loadAllGameSlots();
      expect(afterClear.length, equals(3));
      expect(afterClear[GameType.chess], isNotNull);
    });

    test('queues offline score and removes on sync', () async {
      final rec = GameRecord(
        id: 'rec-1',
        userId: 'guest',
        username: 'guest',
        gameType: GameType.minesweeper,
        difficulty: 3,
        isWon: true,
        score: 2400,
        durationMs: 18500,
        platform: 'linux',
        playedAt: DateTime.now().toUtc(),
      );

      await storage.enqueueScore(rec);
      final queue = await storage.getQueuedScores();
      expect(queue.length, equals(1));
      expect(queue.first.platform, equals('linux'));

      await storage.removeQueuedScore('rec-1');
      expect((await storage.getQueuedScores()), isEmpty);
    });
  });

  group('Sudoku Engine & Controller', () {
    test('Level 7 Master Seed produces 17 clues and valid 81-cell solution', () async {
      final generated = await SudokuEngine.generateAsync(DifficultyLevel.god);
      final clueCount = generated.puzzle.where((v) => v != 0).length;
      expect(clueCount, equals(17));
      expect(generated.solution.contains(0), isFalse);
      for (var i = 0; i < 81; i++) {
        expect(SudokuEngine.hasConflict(generated.solution, i), isFalse);
      }
    });

    test('SudokuController enforces notes-only Undo and max 3 hints', () async {
      final audio = AudioService();
      final haptics = HapticService()..enabled = false;
      final ctrl = SudokuController(
        audio: audio,
        haptics: haptics,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );

      await ctrl.startNew(
        difficulty: DifficultyLevel.chill,
        isPractice: false,
      );
      expect(ctrl.state.unlimitedLives, isTrue);
      expect(ctrl.state.hintsLeft, equals(3));

      // Find first empty cell
      final emptyIdx = ctrl.state.givens.indexOf(0);
      ctrl.selectCell(emptyIdx);
      ctrl.toggleNotesMode();
      ctrl.onDigitTap(5);
      expect(ctrl.state.notes[emptyIdx].contains(5), isTrue);
      expect(ctrl.state.canUndoNote, isTrue);

      ctrl.undoNotes();
      expect(ctrl.state.notes[emptyIdx].contains(5), isFalse);

      ctrl.useHint();
      expect(ctrl.state.hintsLeft, equals(2));
      expect(ctrl.state.values[emptyIdx], equals(ctrl.state.solution[emptyIdx]));
      ctrl.dispose();
    });
  });

  group('Minesweeper Engine & Controller', () {
    test('first click is safe and 3BV is positive', () {
      final grid = MinesweeperEngine.populateMines(
        rows: 9,
        cols: 9,
        mineCount: 12,
        firstRow: 4,
        firstCol: 4,
        difficultyLevel: 2,
      );
      expect(grid[4][4].isMine, isFalse);
      expect(MinesweeperEngine.compute3BV(grid), greaterThan(0));
    });

    test('Level 1 has 1x Defuse Shield', () {
      final ctrl = MinesweeperController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(difficulty: DifficultyLevel.chill, isPractice: false);
      expect(ctrl.state.shieldRemaining, equals(1));
      ctrl.dispose();
    });
  });

  group('Snake Controller', () {
    test('2-step input queue queues valid perpendicular turns only', () {
      final ctrl = SnakeController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(difficulty: DifficultyLevel.chill, isPractice: false);
      expect(ctrl.state.wrapWalls, isTrue);
      expect(ctrl.state.gridSize, equals(15));

      // Currently moving right; opposite (left) should be ignored, up+left queued
      ctrl.queueDirection(SnakeDirection.left);
      ctrl.queueDirection(SnakeDirection.up);
      ctrl.queueDirection(SnakeDirection.left);
      ctrl.dispose();
    });

    test('Level 6 enables starvation bar and dynamic obstacles', () {
      final ctrl = SnakeController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(difficulty: DifficultyLevel.nightmare, isPractice: false);
      expect(ctrl.state.hasStarvation, isTrue);
      expect(ctrl.state.hasDynamicObstacles, isTrue);
      expect(ctrl.state.gridSize, equals(25));
      ctrl.dispose();
    });
  });

  group('Chess AI & ELO', () {
    test('finds legal move from starting position and updates ELO', () async {
      final move = await ChessAiEngine.findBestMoveAlgebraic(
        fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        level: 2,
      );
      expect(move, isNotNull);
      expect(move!.length, greaterThanOrEqualTo(4));

      final nextElo = ChessAiEngine.calculateNewElo(
        currentElo: 1000,
        opponentElo: 1450,
        score: 1.0,
      );
      expect(nextElo, greaterThan(1000));
    });
  });
}
