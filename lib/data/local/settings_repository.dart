import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';

/// Persisted user preferences for theme, language, controls, and progression.
class AppSettings {
  const AppSettings({
    this.themeMode = ZetzyThemeMode.oledMidnight,
    this.localeCode = 'en',
    this.sfxEnabled = true,
    this.bgmEnabled = false,
    this.hapticsEnabled = true,
    this.wakelockEnabled = true,
    this.snakeControlMode = SnakeControlMode.swipe,
    this.snakeShowGridLines = true,
    this.chessPieceSet = ChessPieceSet.cburnett,
    this.chessAutoQueen = true,
    this.chessShowLegalMoves = true,
    this.chessShowCoordinates = true,
    this.sudokuAutoFinish = true,
    this.sudokuAutoFinishThreshold = 5,
    this.sudokuHighlightSameDigits = true,
    this.sudokuAutoClearNotes = true,
    this.minesweeperQuickChord = true,
    this.practiceRewindOnLoss = true,
    this.practiceRewindSteps = 2,
    this.guestChessElo = 1000,
    this.guestUnlockedLevels = const {
      GameType.sudoku: 5,
      GameType.chess: 5,
      GameType.minesweeper: 5,
      GameType.snake: 5,
    },
  });

  final ZetzyThemeMode themeMode;
  final String localeCode;
  final bool sfxEnabled;
  final bool bgmEnabled;
  final bool hapticsEnabled;
  final bool wakelockEnabled;
  final SnakeControlMode snakeControlMode;
  final bool snakeShowGridLines;
  final ChessPieceSet chessPieceSet;
  final bool chessAutoQueen;
  final bool chessShowLegalMoves;
  final bool chessShowCoordinates;
  final bool sudokuAutoFinish;
  final int sudokuAutoFinishThreshold;
  final bool sudokuHighlightSameDigits;
  final bool sudokuAutoClearNotes;
  final bool minesweeperQuickChord;
  final bool practiceRewindOnLoss;
  final int practiceRewindSteps;
  final int guestChessElo;
  final Map<GameType, int> guestUnlockedLevels;

  AppSettings copyWith({
    ZetzyThemeMode? themeMode,
    String? localeCode,
    bool? sfxEnabled,
    bool? bgmEnabled,
    bool? hapticsEnabled,
    bool? wakelockEnabled,
    SnakeControlMode? snakeControlMode,
    bool? snakeShowGridLines,
    ChessPieceSet? chessPieceSet,
    bool? chessAutoQueen,
    bool? chessShowLegalMoves,
    bool? chessShowCoordinates,
    bool? sudokuAutoFinish,
    int? sudokuAutoFinishThreshold,
    bool? sudokuHighlightSameDigits,
    bool? sudokuAutoClearNotes,
    bool? minesweeperQuickChord,
    bool? practiceRewindOnLoss,
    int? practiceRewindSteps,
    int? guestChessElo,
    Map<GameType, int>? guestUnlockedLevels,
  }) {
    final rawThreshold =
        sudokuAutoFinishThreshold ?? this.sudokuAutoFinishThreshold;
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      wakelockEnabled: wakelockEnabled ?? this.wakelockEnabled,
      snakeControlMode: snakeControlMode ?? this.snakeControlMode,
      snakeShowGridLines: snakeShowGridLines ?? this.snakeShowGridLines,
      chessPieceSet: chessPieceSet ?? this.chessPieceSet,
      chessAutoQueen: chessAutoQueen ?? this.chessAutoQueen,
      chessShowLegalMoves: chessShowLegalMoves ?? this.chessShowLegalMoves,
      chessShowCoordinates: chessShowCoordinates ?? this.chessShowCoordinates,
      sudokuAutoFinish: sudokuAutoFinish ?? this.sudokuAutoFinish,
      sudokuAutoFinishThreshold: rawThreshold >= 7 ? 7 : 5,
      sudokuHighlightSameDigits:
          sudokuHighlightSameDigits ?? this.sudokuHighlightSameDigits,
      sudokuAutoClearNotes: sudokuAutoClearNotes ?? this.sudokuAutoClearNotes,
      minesweeperQuickChord:
          minesweeperQuickChord ?? this.minesweeperQuickChord,
      practiceRewindOnLoss: practiceRewindOnLoss ?? this.practiceRewindOnLoss,
      practiceRewindSteps:
          (practiceRewindSteps ?? this.practiceRewindSteps).clamp(1, 3),
      guestChessElo: guestChessElo ?? this.guestChessElo,
      guestUnlockedLevels: guestUnlockedLevels ?? this.guestUnlockedLevels,
    );
  }
}

class SettingsRepository {
  SettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kTheme = 'zetzy_theme';
  static const _kLocale = 'zetzy_locale';
  static const _kSfx = 'zetzy_sfx';
  static const _kBgm = 'zetzy_bgm';
  static const _kHaptics = 'zetzy_haptics';
  static const _kWakelock = 'zetzy_wakelock';
  static const _kSnakeCtrl = 'zetzy_snake_ctrl';
  static const _kSnakeGrid = 'zetzy_snake_grid';
  static const _kChessPieces = 'zetzy_chess_pieces';
  static const _kChessAutoQueen = 'zetzy_chess_auto_queen';
  static const _kChessLegalMoves = 'zetzy_chess_legal_moves';
  static const _kChessCoordinates = 'zetzy_chess_coordinates';
  static const _kSudokuAutoFinish = 'zetzy_sudoku_auto_finish';
  static const _kSudokuAutoFinishThreshold =
      'zetzy_sudoku_auto_finish_threshold';
  static const _kSudokuHighlightSame = 'zetzy_sudoku_highlight_same';
  static const _kSudokuAutoClearNotes = 'zetzy_sudoku_auto_clear_notes';
  static const _kMinesweeperQuickChord = 'zetzy_minesweeper_quick_chord';
  static const _kPracticeRewindOnLoss = 'zetzy_practice_rewind_on_loss';
  static const _kPracticeRewindSteps = 'zetzy_practice_rewind_steps';
  static const _kGuestElo = 'zetzy_guest_elo';
  static const _kGuestUnlocked = 'zetzy_guest_unlocked';

  AppSettings load() {
    final unlockedRaw = _prefs.getString(_kGuestUnlocked);
    final unlocked = <GameType, int>{
      for (final g in GameType.values)
        g: DifficultyLevel.defaultUnlockedLevel,
    };
    if (unlockedRaw != null) {
      try {
        final decoded = jsonDecode(unlockedRaw) as Map<String, dynamic>;
        for (final g in GameType.values) {
          unlocked[g] =
              (decoded[g.id] as num?)?.toInt() ??
              DifficultyLevel.defaultUnlockedLevel;
        }
      } catch (_) {}
    }

    final savedThreshold = _prefs.getInt(_kSudokuAutoFinishThreshold) ?? 5;
    return AppSettings(
      themeMode: ZetzyThemeMode.fromId(
        _prefs.getString(_kTheme) ?? ZetzyThemeMode.oledMidnight.id,
      ),
      localeCode: _prefs.getString(_kLocale) ?? 'en',
      sfxEnabled: _prefs.getBool(_kSfx) ?? true,
      bgmEnabled: _prefs.getBool(_kBgm) ?? false,
      hapticsEnabled: _prefs.getBool(_kHaptics) ?? true,
      wakelockEnabled: _prefs.getBool(_kWakelock) ?? true,
      snakeControlMode: SnakeControlMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kSnakeCtrl),
        orElse: () => SnakeControlMode.swipe,
      ),
      snakeShowGridLines: _prefs.getBool(_kSnakeGrid) ?? true,
      chessPieceSet: ChessPieceSet.values.firstWhere(
        (s) => s.folder == _prefs.getString(_kChessPieces),
        orElse: () => ChessPieceSet.cburnett,
      ),
      chessAutoQueen: _prefs.getBool(_kChessAutoQueen) ?? true,
      chessShowLegalMoves: _prefs.getBool(_kChessLegalMoves) ?? true,
      chessShowCoordinates: _prefs.getBool(_kChessCoordinates) ?? true,
      sudokuAutoFinish: _prefs.getBool(_kSudokuAutoFinish) ?? true,
      sudokuAutoFinishThreshold: savedThreshold >= 7 ? 7 : 5,
      sudokuHighlightSameDigits:
          _prefs.getBool(_kSudokuHighlightSame) ?? true,
      sudokuAutoClearNotes: _prefs.getBool(_kSudokuAutoClearNotes) ?? true,
      minesweeperQuickChord:
          _prefs.getBool(_kMinesweeperQuickChord) ?? true,
      practiceRewindOnLoss: _prefs.getBool(_kPracticeRewindOnLoss) ?? true,
      practiceRewindSteps: (_prefs.getInt(_kPracticeRewindSteps) ?? 2).clamp(
        1,
        3,
      ),
      guestChessElo: _prefs.getInt(_kGuestElo) ?? 1000,
      guestUnlockedLevels: unlocked,
    );
  }

  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString(_kTheme, s.themeMode.id),
      _prefs.setString(_kLocale, s.localeCode),
      _prefs.setBool(_kSfx, s.sfxEnabled),
      _prefs.setBool(_kBgm, s.bgmEnabled),
      _prefs.setBool(_kHaptics, s.hapticsEnabled),
      _prefs.setBool(_kWakelock, s.wakelockEnabled),
      _prefs.setString(_kSnakeCtrl, s.snakeControlMode.name),
      _prefs.setBool(_kSnakeGrid, s.snakeShowGridLines),
      _prefs.setString(_kChessPieces, s.chessPieceSet.folder),
      _prefs.setBool(_kChessAutoQueen, s.chessAutoQueen),
      _prefs.setBool(_kChessLegalMoves, s.chessShowLegalMoves),
      _prefs.setBool(_kChessCoordinates, s.chessShowCoordinates),
      _prefs.setBool(_kSudokuAutoFinish, s.sudokuAutoFinish),
      _prefs.setInt(_kSudokuAutoFinishThreshold, s.sudokuAutoFinishThreshold),
      _prefs.setBool(_kSudokuHighlightSame, s.sudokuHighlightSameDigits),
      _prefs.setBool(_kSudokuAutoClearNotes, s.sudokuAutoClearNotes),
      _prefs.setBool(_kMinesweeperQuickChord, s.minesweeperQuickChord),
      _prefs.setBool(_kPracticeRewindOnLoss, s.practiceRewindOnLoss),
      _prefs.setInt(_kPracticeRewindSteps, s.practiceRewindSteps.clamp(1, 3)),
      _prefs.setInt(_kGuestElo, s.guestChessElo),
      _prefs.setString(
        _kGuestUnlocked,
        jsonEncode({
          for (final entry in s.guestUnlockedLevels.entries)
            entry.key.id: entry.value,
        }),
      ),
    ]);
  }
}
