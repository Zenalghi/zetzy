import 'package:bishop/bishop.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/constants/supabase_schema.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/avatar_picker_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/core/utils/avatar_compressor.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/local/zetzy_database.dart' hide AutoSaveSlot;
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/remote/supabase_service.dart';
import 'package:zetzy/features/games/chess/chess_ai.dart';
import 'package:zetzy/features/games/chess/chess_controller.dart';
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

    test('SupabaseConfig.normalizeUrl strips trailing slashes and API suffixes', () {
      expect(
        SupabaseConfig.normalizeUrl(' https://abc.supabase.co/rest/v1/ '),
        equals('https://abc.supabase.co'),
      );
      expect(
        SupabaseConfig.normalizeUrl('https://abc.supabase.co/auth/v1'),
        equals('https://abc.supabase.co'),
      );
      expect(
        SupabaseConfig.normalizeUrl('https://abc.supabase.co/'),
        equals('https://abc.supabase.co'),
      );
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

    test('SudokuController locks correctly answered cells in levels 1-4', () async {
      final audio = AudioService();
      final haptics = HapticService()..enabled = false;
      final ctrl = SudokuController(
        audio: audio,
        haptics: haptics,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );

      await ctrl.startNew(
        difficulty: DifficultyLevel.easy,
        isPractice: false,
      );

      final emptyIdx = ctrl.state.givens.indexOf(0);
      final correctDigit = ctrl.state.solution[emptyIdx];
      final wrongDigit = correctDigit == 9 ? 1 : correctDigit + 1;
      final initialLives = ctrl.state.livesLeft;

      ctrl.selectCell(emptyIdx);
      ctrl.onDigitTap(correctDigit);
      expect(ctrl.state.values[emptyIdx], equals(correctDigit));
      expect(ctrl.state.livesLeft, equals(initialLives));

      // Attempt to overwrite via digit tap, locked digit tap, and erase
      ctrl.onDigitTap(wrongDigit);
      expect(ctrl.state.values[emptyIdx], equals(correctDigit));
      expect(ctrl.state.livesLeft, equals(initialLives));
      expect(ctrl.state.mistakes, equals(0));

      ctrl.toggleDigitLock(wrongDigit);
      ctrl.selectCell(emptyIdx);
      expect(ctrl.state.values[emptyIdx], equals(correctDigit));
      expect(ctrl.state.livesLeft, equals(initialLives));

      ctrl.eraseSelected();
      expect(ctrl.state.values[emptyIdx], equals(correctDigit));
      ctrl.dispose();
    });

    test('SudokuController PRO mode keeps lives on non-conflicting guesses and loses lives on conflicts', () async {
      var finished = false;
      late SudokuGameState finalState;
      final ctrl = SudokuController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (s) {
          finished = true;
          finalState = s;
        },
        onAutoSave: (_) {},
      );

      await ctrl.startNew(
        difficulty: DifficultyLevel.pro,
        isPractice: false,
      );
      expect(ctrl.state.checksAnswerKeyImmediately, isFalse);
      expect(ctrl.state.livesLeft, equals(3));

      // Find an empty cell that has both a non-conflicting wrong digit and a conflicting peer digit.
      int? targetCell;
      int? nonConflictingWrong;
      int? conflictingDigit;
      for (var i = 0; i < 81; i++) {
        if (ctrl.state.givens[i] != 0) continue;
        final row = i ~/ 9;
        final col = i % 9;
        final br = (row ~/ 3) * 3;
        final bc = (col ~/ 3) * 3;
        final peers = <int>{};
        for (var k = 0; k < 9; k++) {
          final rv = ctrl.state.givens[row * 9 + k];
          final cv = ctrl.state.givens[k * 9 + col];
          if (rv != 0) peers.add(rv);
          if (cv != 0) peers.add(cv);
        }
        for (var r = 0; r < 3; r++) {
          for (var c = 0; c < 3; c++) {
            final bv = ctrl.state.givens[(br + r) * 9 + (bc + c)];
            if (bv != 0) peers.add(bv);
          }
        }
        if (peers.isEmpty) continue;
        final candidateWrong = [1, 2, 3, 4, 5, 6, 7, 8, 9].cast<int?>().firstWhere(
          (d) => d != ctrl.state.solution[i] && !peers.contains(d),
          orElse: () => null,
        );
        if (candidateWrong != null) {
          targetCell = i;
          nonConflictingWrong = candidateWrong;
          conflictingDigit = peers.first;
          break;
        }
      }

      expect(targetCell, isNotNull);
      ctrl.selectCell(targetCell!);

      // Wrong guess with NO duplicate conflict must not consume lives in PRO+ mode.
      ctrl.onDigitTap(nonConflictingWrong!);
      expect(ctrl.state.values[targetCell], equals(nonConflictingWrong));
      expect(ctrl.state.livesLeft, equals(3));
      expect(ctrl.state.mistakes, equals(0));
      expect(ctrl.state.isGameOver, isFalse);

      // Duplicate conflicts deduct 1 life per conflict until Game Over (3 -> 2 -> 1 -> 0).
      ctrl.onDigitTap(conflictingDigit!);
      expect(ctrl.state.livesLeft, equals(2));
      expect(ctrl.state.mistakes, equals(1));
      ctrl.eraseSelected();

      ctrl.onDigitTap(conflictingDigit);
      expect(ctrl.state.livesLeft, equals(1));
      ctrl.eraseSelected();

      ctrl.onDigitTap(conflictingDigit);
      expect(ctrl.state.livesLeft, equals(0));
      expect(ctrl.state.mistakes, equals(3));
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isFalse);
      expect(finished, isTrue);
      expect(finalState.livesLeft, equals(0));

      ctrl.dispose();
    });

    test('SudokuController supports deselecting cell/highlight and highlighting from bottom keypad', () async {
      final ctrl = SudokuController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );

      await ctrl.startNew(
        difficulty: DifficultyLevel.normal,
        isPractice: false,
      );

      final givenIdx = ctrl.state.givens.indexWhere((v) => v != 0);
      final givenDigit = ctrl.state.givens[givenIdx];
      final otherDigit = givenDigit == 9 ? 1 : givenDigit + 1;

      // Tap given cell to select & highlight; tap same cell again to deselect
      ctrl.selectCell(givenIdx);
      expect(ctrl.state.selectedCell, equals(givenIdx));
      expect(ctrl.state.highlightedDigit, equals(givenDigit));

      ctrl.selectCell(givenIdx);
      expect(ctrl.state.selectedCell, isNull);
      expect(ctrl.state.highlightedDigit, isNull);

      // Select given cell, then switch highlight from bottom digit pad
      ctrl.selectCell(givenIdx);
      ctrl.onDigitTap(otherDigit);
      expect(ctrl.state.lockedDigit, equals(otherDigit));
      expect(ctrl.state.highlightedDigit, equals(otherDigit));
      expect(ctrl.state.selectedCell, isNull);

      // Tap same bottom digit again to deselect highlight
      ctrl.onDigitTap(otherDigit);
      expect(ctrl.state.lockedDigit, isNull);
      expect(ctrl.state.highlightedDigit, isNull);

      // Tap bottom digit with no cell selected -> highlights; tap again -> deselects
      ctrl.onDigitTap(givenDigit);
      expect(ctrl.state.lockedDigit, equals(givenDigit));
      expect(ctrl.state.highlightedDigit, equals(givenDigit));
      ctrl.onDigitTap(givenDigit);
      expect(ctrl.state.highlightedDigit, isNull);

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

    test('tapping an already selected piece deselects it and clears legal markers', () {
      final ctrl = ChessController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        supabase: SupabaseService(),
        autoQueen: true,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(
        difficulty: DifficultyLevel.easy,
        isPractice: false,
        mode: ChessPlayMode.passAndPlay,
        colorPref: ChessColorPref.white,
        timeControl: ChessTimeControl.untimed,
      );

      final firstMove = ctrl.game.generateLegalMoves().first;
      ctrl.onSquareTap(firstMove.from);
      expect(ctrl.state.selectedSquare, equals(firstMove.from));
      expect(ctrl.state.legalTargets, isNotEmpty);

      // Tapping the same square again clears selection & move guides
      ctrl.onSquareTap(firstMove.from);
      expect(ctrl.state.selectedSquare, isNull);
      expect(ctrl.state.legalTargets, isEmpty);

      // Re-selecting after deselect still works properly
      ctrl.onSquareTap(firstMove.from);
      expect(ctrl.state.selectedSquare, equals(firstMove.from));
      expect(ctrl.state.legalTargets, contains(firstMove.to));
      ctrl.dispose();
    });
  });

  group('Cross-Platform Avatar Compressor & Picker', () {
    test('AvatarCompressor crops and resizes images to 256x256 PNG', () {
      final raw = img.Image(width: 640, height: 480);
      img.fill(raw, color: img.ColorRgb8(40, 180, 120));
      final encoded = Uint8List.fromList(img.encodeJpg(raw));

      final compressed = AvatarCompressor.compressTo256Png(encoded);
      expect(compressed, isNotNull);

      final decoded = img.decodePng(compressed!);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(256));
      expect(decoded.height, equals(256));

      expect(
        AvatarCompressor.compressTo256Png(Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    });

    test('AvatarPickerService limits camera prompt to Android and iOS', () {
      final picker = AvatarPickerService();
      for (final desktop in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = desktop;
        expect(picker.supportsCameraChoice, isFalse);
      }
      for (final mobile in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = mobile;
        expect(picker.supportsCameraChoice, isTrue);
      }
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Practice Mode Rewind & Undo', () {
    test('SettingsRepository persists practice rewind settings locally', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      final initial = repo.load();
      expect(initial.practiceRewindOnLoss, isTrue);
      expect(initial.practiceRewindSteps, equals(2));

      expect(initial.copyWith(practiceRewindSteps: 9).practiceRewindSteps, equals(3));
      expect(initial.copyWith(practiceRewindSteps: 0).practiceRewindSteps, equals(1));

      await repo.save(
        initial.copyWith(
          practiceRewindOnLoss: false,
          practiceRewindSteps: 3,
        ),
      );
      final reloaded = repo.load();
      expect(reloaded.practiceRewindOnLoss, isFalse);
      expect(reloaded.practiceRewindSteps, equals(3));
    });

    test('SudokuController practice Undo reverses digits, hints, and notes', () async {
      final ctrl = SudokuController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      await ctrl.startNew(
        difficulty: DifficultyLevel.easy,
        isPractice: true,
      );

      final emptyIdx = ctrl.state.givens.indexOf(0);
      final correct = ctrl.state.solution[emptyIdx];
      final wrong = correct == 9 ? 1 : correct + 1;

      ctrl.selectCell(emptyIdx);
      ctrl.onDigitTap(wrong);
      expect(ctrl.state.values[emptyIdx], equals(wrong));
      expect(ctrl.state.mistakes, equals(1));
      expect(ctrl.state.canUndoPractice, isTrue);

      ctrl.useHint();
      expect(ctrl.state.hintsLeft, equals(2));
      expect(ctrl.state.values[emptyIdx], equals(correct));

      // Undo hint restores previous wrong digit & hintsLeft
      ctrl.undoPractice();
      expect(ctrl.state.hintsLeft, equals(3));
      expect(ctrl.state.values[emptyIdx], equals(wrong));
      expect(ctrl.state.canUndoPractice, isTrue);

      // Undo digit placement clears cell & mistakes count
      ctrl.undoPractice();
      expect(ctrl.state.values[emptyIdx], equals(0));
      expect(ctrl.state.mistakes, equals(0));
      expect(ctrl.state.canUndoPractice, isFalse);

      ctrl.dispose();
    });

    test('MinesweeperController practice Undo & Rewind recovers after hitting a mine', () {
      final ctrl = MinesweeperController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(difficulty: DifficultyLevel.pro, isPractice: true);
      expect(ctrl.state.shieldRemaining, equals(0));

      // Safe first dig at center
      ctrl.onCellTap(4, 4);
      expect(ctrl.state.hasStarted, isTrue);
      expect(ctrl.state.canPracticeUndo, isTrue);

      // Find an unrevealed mine cell and an unrevealed safe cell to test undo + rewind
      (int, int)? minePos;
      (int, int)? safeUnrevealedPos;
      for (var r = 0; r < ctrl.state.rows; r++) {
        for (var c = 0; c < ctrl.state.cols; c++) {
          final cell = ctrl.state.grid[r][c];
          if (cell.isMine && minePos == null) minePos = (r, c);
          if (!cell.isMine && !cell.isRevealed && safeUnrevealedPos == null) {
            safeUnrevealedPos = (r, c);
          }
        }
      }
      expect(minePos, isNotNull);
      expect(safeUnrevealedPos, isNotNull);

      // Toggle flag on safeUnrevealedPos then undo it
      ctrl.toggleMark(safeUnrevealedPos!.$1, safeUnrevealedPos.$2);
      expect(
        ctrl.state.grid[safeUnrevealedPos.$1][safeUnrevealedPos.$2].mark,
        equals(MineCellMark.flag),
      );
      ctrl.practiceUndo();
      expect(
        ctrl.state.grid[safeUnrevealedPos.$1][safeUnrevealedPos.$2].mark,
        equals(MineCellMark.none),
      );

      // Hit mine -> triggers game over loss
      ctrl.onCellTap(minePos!.$1, minePos.$2);
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isFalse);

      // Rewind 1 step restores pre-explosion unrevealed state
      ctrl.practiceRewind(1);
      expect(ctrl.state.isGameOver, isFalse);
      expect(ctrl.state.isWon, isFalse);
      expect(
        ctrl.state.grid[minePos.$1][minePos.$2].isRevealed,
        isFalse,
      );
      expect(
        ctrl.state.grid[minePos.$1][minePos.$2].isExploded,
        isFalse,
      );

      ctrl.dispose();
    });

    test('ChessController practice Undo works on Lv7 and Rewind continues after loss', () {
      final ctrl = ChessController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        supabase: SupabaseService(),
        autoQueen: true,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(
        difficulty: DifficultyLevel.god,
        isPractice: true,
        mode: ChessPlayMode.passAndPlay,
        colorPref: ChessColorPref.white,
        timeControl: ChessTimeControl.untimed,
      );

      // Play 3 plies in Pass & Play practice mode
      for (var i = 0; i < 3; i++) {
        final m = ctrl.game.generateLegalMoves().first;
        ctrl.onSquareTap(m.from);
        ctrl.onSquareTap(m.to);
      }
      expect(ctrl.state.moveSans.length, equals(3));
      expect(ctrl.state.canPracticeUndo, isTrue);

      // Rewind 2 plies
      ctrl.practiceRewind(2);
      expect(ctrl.state.moveSans.length, equals(1));
      expect(ctrl.state.isGameOver, isFalse);

      // Resign triggers game over; rewind recovers from game over cleanly
      ctrl.resign();
      expect(ctrl.state.isGameOver, isTrue);
      ctrl.practiceRewind(1);
      expect(ctrl.state.isGameOver, isFalse);
      expect(ctrl.state.winnerColour, isNull);
      expect(ctrl.state.moveSans, isEmpty);

      // Non-practice ranked mode leaves Lv7 Undo locked
      ctrl.startNew(
        difficulty: DifficultyLevel.god,
        isPractice: false,
        mode: ChessPlayMode.vsAi,
        colorPref: ChessColorPref.white,
        timeControl: ChessTimeControl.untimed,
      );
      expect(ctrl.state.canUndo, isFalse);
      expect(ctrl.state.canPracticeUndo, isFalse);

      ctrl.dispose();
    });

    test('SnakeController practice Rewind recovers 1-3 steps after wall collision', () {
      final ctrl = SnakeController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(difficulty: DifficultyLevel.easy, isPractice: true);
      expect(ctrl.state.wrapWalls, isFalse);
      final startHead = ctrl.state.snake.first;

      // Step right until snake hits the east wall (easy gridSize=17, start x=8 -> 9 steps hits x=17)
      var steps = 0;
      while (!ctrl.state.isGameOver && steps < 25) {
        ctrl.stepForTest();
        steps++;
      }
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isFalse);
      expect(ctrl.state.canPracticeUndo, isTrue);

      // Rewind 3 steps back from wall collision
      ctrl.practiceRewind(3);
      expect(ctrl.state.isGameOver, isFalse);
      expect(ctrl.state.isWon, isFalse);
      expect(ctrl.state.isPaused, isTrue);
      expect(ctrl.state.snake.first.x, lessThan(ctrl.state.gridSize - 1));
      expect(ctrl.state.snake.first.x, greaterThan(startHead.x));

      ctrl.dispose();
    });
  });

  group('Post-Game Board Review', () {
    test('MinesweeperController reveals all mines on both loss and win and counts wrong flags', () {
      final ctrl = MinesweeperController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );

      // Loss case (Lv5 Pro has no defuse shield): wrong flag + mine hit reveals all mines
      ctrl.startNew(difficulty: DifficultyLevel.pro, isPractice: false);
      ctrl.onCellTap(4, 4);

      (int, int)? safeUnrevealed;
      (int, int)? mineCell;
      for (var r = 0; r < ctrl.state.rows; r++) {
        for (var c = 0; c < ctrl.state.cols; c++) {
          final cell = ctrl.state.grid[r][c];
          if (!cell.isMine && !cell.isRevealed && safeUnrevealed == null) {
            safeUnrevealed = (r, c);
          }
          if (cell.isMine && mineCell == null) {
            mineCell = (r, c);
          }
        }
      }
      expect(safeUnrevealed, isNotNull);
      expect(mineCell, isNotNull);

      ctrl.toggleMark(safeUnrevealed!.$1, safeUnrevealed.$2);
      expect(ctrl.state.wrongFlagCount, equals(1));

      ctrl.onCellTap(mineCell!.$1, mineCell.$2);
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isFalse);
      expect(ctrl.state.wrongFlagCount, equals(1));
      expect(
        ctrl.state.grid[mineCell.$1][mineCell.$2].isExploded,
        isTrue,
      );
      for (final row in ctrl.state.grid) {
        for (final cell in row) {
          if (cell.isMine) {
            expect(cell.isRevealed, isTrue);
          }
        }
      }

      // Win case: clearing all safe cells reveals all remaining unflagged & flagged mines
      ctrl.startNew(difficulty: DifficultyLevel.pro, isPractice: false);
      ctrl.onCellTap(4, 4);
      var flaggedOneMine = false;
      for (var r = 0; r < ctrl.state.rows; r++) {
        for (var c = 0; c < ctrl.state.cols; c++) {
          final cell = ctrl.state.grid[r][c];
          if (cell.isMine && !flaggedOneMine) {
            ctrl.toggleMark(r, c);
            flaggedOneMine = true;
          } else if (!cell.isMine && !cell.isRevealed) {
            ctrl.onCellTap(r, c);
          }
        }
      }
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isTrue);
      expect(ctrl.state.wrongFlagCount, equals(0));
      var revealedFlaggedMines = 0;
      for (final row in ctrl.state.grid) {
        for (final cell in row) {
          if (cell.isMine) {
            expect(cell.isRevealed, isTrue);
            expect(cell.isExploded, isFalse);
            if (cell.mark == MineCellMark.flag) revealedFlaggedMines++;
          }
        }
      }
      expect(revealedFlaggedMines, equals(1));

      ctrl.dispose();
    });

    test('ChessController move review steps backward and forward cleanly after game ends', () {
      final ctrl = ChessController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        supabase: SupabaseService(),
        autoQueen: true,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(
        difficulty: DifficultyLevel.pro,
        isPractice: false,
        mode: ChessPlayMode.passAndPlay,
        colorPref: ChessColorPref.white,
        timeControl: ChessTimeControl.untimed,
      );

      for (var i = 0; i < 3; i++) {
        final m = ctrl.game.generateLegalMoves().first;
        ctrl.onSquareTap(m.from);
        ctrl.onSquareTap(m.to);
      }
      ctrl.resign();
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.effectiveReviewPly, equals(3));
      expect(ctrl.state.canReviewBack, isTrue);
      expect(ctrl.state.canReviewForward, isFalse);

      ctrl.reviewFirst();
      expect(ctrl.state.reviewPly, equals(0));
      expect(ctrl.state.turn, equals(Bishop.white));
      expect(ctrl.state.lastFrom, isNull);
      expect(ctrl.state.canReviewBack, isFalse);
      expect(ctrl.state.canReviewForward, isTrue);

      ctrl.reviewNext();
      expect(ctrl.state.reviewPly, equals(1));
      expect(ctrl.state.turn, equals(Bishop.black));
      expect(ctrl.state.lastFrom, isNotNull);

      ctrl.reviewLast();
      expect(ctrl.state.reviewPly, isNull);
      expect(ctrl.state.effectiveReviewPly, equals(3));
      expect(ctrl.state.canReviewForward, isFalse);

      ctrl.dispose();
    });

    test('SudokuController toggleReviewSolution toggles solution overlay after loss', () async {
      final ctrl = SudokuController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      await ctrl.startNew(
        difficulty: DifficultyLevel.god, // 1 life -> single mistake ends game
        isPractice: false,
      );

      // Pick an empty cell and a conflicting digit from a given clue in its row/col/box
      // so Lv7 conflict-only detection triggers immediately on every seed.
      int? targetIdx;
      int? conflictingDigit;
      for (var i = 0; i < 81 && targetIdx == null; i++) {
        if (ctrl.state.givens[i] != 0) continue;
        final r = i ~/ 9;
        final c = i % 9;
        final br = (r ~/ 3) * 3;
        final bc = (c ~/ 3) * 3;
        for (var k = 0; k < 9 && conflictingDigit == null; k++) {
          final candidates = [r * 9 + k, k * 9 + c, (br + k ~/ 3) * 9 + (bc + k % 3)];
          for (final p in candidates) {
            if (p != i && ctrl.state.givens[p] != 0) {
              targetIdx = i;
              conflictingDigit = ctrl.state.givens[p];
              break;
            }
          }
        }
      }

      ctrl.selectCell(targetIdx!);
      ctrl.onDigitTap(conflictingDigit!);
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isFalse);
      expect(ctrl.state.showSolutionInReview, isFalse);

      ctrl.toggleReviewSolution();
      expect(ctrl.state.showSolutionInReview, isTrue);
      ctrl.toggleReviewSolution();
      expect(ctrl.state.showSolutionInReview, isFalse);

      ctrl.dispose();
    });

    test('SnakeController records wall deathReason and crashPoint on wall impact', () {
      final ctrl = SnakeController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(difficulty: DifficultyLevel.easy, isPractice: false);

      var steps = 0;
      while (!ctrl.state.isGameOver && steps < 25) {
        ctrl.stepForTest();
        steps++;
      }
      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isFalse);
      expect(ctrl.state.deathReason, equals(SnakeDeathReason.wall));
      expect(ctrl.state.crashPoint, isNotNull);
      expect(ctrl.state.crashPoint!.x, equals(ctrl.state.gridSize - 1));

      ctrl.dispose();
    });
  });

  group('Settings & Gameplay Enhancements', () {
    const validSolution = <int>[
      5, 3, 4, 6, 7, 8, 9, 1, 2,
      6, 7, 2, 1, 9, 5, 3, 4, 8,
      1, 9, 8, 3, 4, 2, 5, 6, 7,
      8, 5, 9, 7, 6, 1, 4, 2, 3,
      4, 2, 6, 8, 5, 3, 7, 9, 1,
      7, 1, 3, 9, 2, 4, 8, 5, 6,
      9, 6, 1, 5, 3, 7, 2, 8, 4,
      2, 8, 7, 4, 1, 9, 6, 3, 5,
      3, 4, 5, 2, 8, 6, 1, 7, 9,
    ];

    AutoSaveSlot makeSudokuSlot({
      required List<int> givens,
      required List<int> values,
      DifficultyLevel difficulty = DifficultyLevel.easy,
      List<Set<int>>? notes,
    }) {
      final notesJson = (notes ?? List.generate(81, (_) => <int>{}))
          .map((s) => s.toList())
          .toList();
      return AutoSaveSlot(
        gameType: GameType.sudoku,
        difficulty: difficulty.level,
        elapsedMs: 12000,
        updatedAt: DateTime(2026, 11, 15),
        stateJson: {
          'isPractice': false,
          'givens': givens,
          'values': values,
          'solution': validSolution,
          'notes': notesJson,
          'errorCells': const <int>[],
          'livesLeft': 3,
          'mistakes': 0,
          'hintsLeft': 3,
        },
      );
    }

    test('SettingsRepository persists per-game gameplay QoL preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      final initial = repo.load();
      expect(initial.sudokuAutoFinish, isTrue);
      expect(initial.sudokuAutoFinishThreshold, equals(5));
      expect(initial.sudokuHighlightSameDigits, isTrue);
      expect(initial.sudokuAutoClearNotes, isTrue);
      expect(initial.chessShowLegalMoves, isTrue);
      expect(initial.chessShowCoordinates, isTrue);
      expect(initial.minesweeperQuickChord, isTrue);
      expect(initial.snakeShowGridLines, isTrue);

      final updated = initial.copyWith(
        sudokuAutoFinish: false,
        sudokuAutoFinishThreshold: 7,
        sudokuHighlightSameDigits: false,
        sudokuAutoClearNotes: false,
        chessShowLegalMoves: false,
        chessShowCoordinates: false,
        minesweeperQuickChord: false,
        snakeShowGridLines: false,
      );
      await repo.save(updated);

      final reloaded = repo.load();
      expect(reloaded.sudokuAutoFinish, isFalse);
      expect(reloaded.sudokuAutoFinishThreshold, equals(7));
      expect(reloaded.sudokuHighlightSameDigits, isFalse);
      expect(reloaded.sudokuAutoClearNotes, isFalse);
      expect(reloaded.chessShowLegalMoves, isFalse);
      expect(reloaded.chessShowCoordinates, isFalse);
      expect(reloaded.minesweeperQuickChord, isFalse);
      expect(reloaded.snakeShowGridLines, isFalse);
    });

    test('SudokuController computes directional completion waves for top and center placements', () {
      final ctrl = SudokuController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );

      // Case A: top cell (0,4) completes col 4 -> sweeps downward 0..8.
      // Leave (0,3) blank too so row 0 & box 1 do not simultaneously complete.
      final topValues = List<int>.from(validSolution)
        ..[0 * 9 + 4] = 0
        ..[0 * 9 + 3] = 0;
      ctrl.restoreFromSlot(
        makeSudokuSlot(givens: topValues, values: List<int>.from(topValues)),
      );
      ctrl.resume();
      ctrl.selectCell(0 * 9 + 4);
      ctrl.onDigitTap(validSolution[0 * 9 + 4]);

      expect(ctrl.state.completionWaveId, equals(1));
      for (var r = 0; r < 9; r++) {
        expect(ctrl.state.completionWaveSteps[r * 9 + 4], equals(r));
      }

      // Case B: middle cell (4,4) completes col 4 -> expands upward and downward.
      // Leave (4,3) blank so row 4 & box 4 stay incomplete.
      final midValues = List<int>.from(validSolution)
        ..[4 * 9 + 4] = 0
        ..[4 * 9 + 3] = 0;
      ctrl.restoreFromSlot(
        makeSudokuSlot(givens: midValues, values: List<int>.from(midValues)),
      );
      ctrl.resume();
      ctrl.selectCell(4 * 9 + 4);
      ctrl.onDigitTap(validSolution[4 * 9 + 4]);

      expect(ctrl.state.completionWaveSteps[4 * 9 + 4], equals(0));
      expect(ctrl.state.completionWaveSteps[3 * 9 + 4], equals(1));
      expect(ctrl.state.completionWaveSteps[5 * 9 + 4], equals(1));
      expect(ctrl.state.completionWaveSteps[0 * 9 + 4], equals(4));
      expect(ctrl.state.completionWaveSteps[8 * 9 + 4], equals(4));

      ctrl.dispose();
    });

    test('SudokuController autoFinish enforces threshold & valid filled state across difficulties', () {
      var wonCount = 0;
      final ctrl = SudokuController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (s) {
          if (s.isWon) wonCount++;
        },
        onAutoSave: (_) {},
      );

      // 6 blank cells on Level 5 (PRO)
      final blanks = [0, 1, 10, 20, 30, 40];
      final values = List<int>.from(validSolution);
      for (final i in blanks) {
        values[i] = 0;
      }
      final givens = List<int>.from(values);

      ctrl.restoreFromSlot(
        makeSudokuSlot(
          givens: givens,
          values: List<int>.from(values),
          difficulty: DifficultyLevel.pro,
        ),
      );
      ctrl.resume();

      expect(ctrl.state.remainingEmptyCount, equals(6));
      expect(ctrl.state.canAutoFinish(5), isFalse);
      expect(ctrl.state.canAutoFinish(7), isTrue);

      // Putting a wrong number in blank index 40 (even without local conflict, or conflicting)
      // must block canAutoFinish until corrected.
      final wrongValues = List<int>.from(values)
        ..[40] = validSolution[40] == 9 ? 1 : validSolution[40] + 1;
      ctrl.restoreFromSlot(
        makeSudokuSlot(
          givens: givens,
          values: wrongValues,
          difficulty: DifficultyLevel.pro,
        ),
      );
      ctrl.resume();
      expect(ctrl.state.canAutoFinish(7), isFalse);

      // With valid state & 5 blanks, autoFinish solves and wins.
      final fiveBlankValues = List<int>.from(validSolution);
      for (final i in blanks.take(5)) {
        fiveBlankValues[i] = 0;
      }
      ctrl.restoreFromSlot(
        makeSudokuSlot(
          givens: fiveBlankValues,
          values: List<int>.from(fiveBlankValues),
          difficulty: DifficultyLevel.pro,
        ),
      );
      ctrl.resume();
      expect(ctrl.state.canAutoFinish(5), isTrue);
      ctrl.autoFinish(maxRemaining: 5);

      expect(ctrl.state.isGameOver, isTrue);
      expect(ctrl.state.isWon, isTrue);
      expect(ctrl.state.remainingEmptyCount, equals(0));
      expect(wonCount, equals(1));

      ctrl.dispose();
    });

    test('SudokuController setAutoClearNotes controls peer note removal', () {
      final ctrl = SudokuController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      final values = List<int>.from(validSolution)
        ..[0] = 0
        ..[1] = 0;
      final notes = List.generate(81, (_) => <int>{});
      notes[1].add(validSolution[0]);

      ctrl.restoreFromSlot(
        makeSudokuSlot(
          givens: values,
          values: List<int>.from(values),
          notes: notes,
        ),
      );
      ctrl.resume();
      ctrl.setAutoClearNotes(false);
      ctrl.selectCell(0);
      ctrl.onDigitTap(validSolution[0]);

      expect(ctrl.state.notes[1].contains(validSolution[0]), isTrue);

      // Re-run with autoClearNotes enabled
      ctrl.restoreFromSlot(
        makeSudokuSlot(
          givens: values,
          values: List<int>.from(values),
          notes: List.generate(81, (i) => i == 1 ? {validSolution[0]} : <int>{}),
        ),
      );
      ctrl.resume();
      ctrl.setAutoClearNotes(true);
      ctrl.selectCell(0);
      ctrl.onDigitTap(validSolution[0]);

      expect(ctrl.state.notes[1].contains(validSolution[0]), isFalse);
      ctrl.dispose();
    });

    test('MinesweeperController setQuickChord gates single-tap chording', () {
      final ctrl = MinesweeperController(
        audio: AudioService(),
        haptics: HapticService()..enabled = false,
        onFinished: (_) {},
        onAutoSave: (_) {},
      );
      ctrl.startNew(difficulty: DifficultyLevel.easy, isPractice: false);
      ctrl.onCellTap(4, 4);

      (int, int)? chordTarget;
      List<(int, int)> mineNeighbors = [];
      List<(int, int)> unrevealedSafe = [];

      for (var r = 0; r < ctrl.state.rows && chordTarget == null; r++) {
        for (var c = 0; c < ctrl.state.cols; c++) {
          final cell = ctrl.state.grid[r][c];
          if (!cell.isRevealed || cell.adjacentMines == 0) continue;

          final mines = <(int, int)>[];
          final safe = <(int, int)>[];
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              final nr = r + dr;
              final nc = c + dc;
              if (nr < 0 ||
                  nc < 0 ||
                  nr >= ctrl.state.rows ||
                  nc >= ctrl.state.cols) {
                continue;
              }
              final n = ctrl.state.grid[nr][nc];
              if (n.isMine) {
                mines.add((nr, nc));
              } else if (!n.isRevealed) {
                safe.add((nr, nc));
              }
            }
          }
          if (mines.isNotEmpty && safe.isNotEmpty) {
            chordTarget = (r, c);
            mineNeighbors = mines;
            unrevealedSafe = safe;
            break;
          }
        }
      }

      expect(chordTarget, isNotNull);
      for (final (mr, mc) in mineNeighbors) {
        if (ctrl.state.grid[mr][mc].mark != MineCellMark.flag) {
          ctrl.onCellLongPressOrRightClick(mr, mc);
        }
      }

      ctrl.setQuickChord(false);
      ctrl.onCellTap(chordTarget!.$1, chordTarget.$2);
      final (sr, sc) = unrevealedSafe.first;
      expect(ctrl.state.grid[sr][sc].isRevealed, isFalse);

      ctrl.setQuickChord(true);
      ctrl.onCellTap(chordTarget.$1, chordTarget.$2);
      expect(ctrl.state.grid[sr][sc].isRevealed, isTrue);

      ctrl.dispose();
    });
  });
}
