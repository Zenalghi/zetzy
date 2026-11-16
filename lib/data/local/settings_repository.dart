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
    this.bgmMode = BgmMode.auto,
    this.bgmTrack = '5.mp3',
    this.hapticsEnabled = true,
    this.hapticIntensity = HapticIntensity.medium,
    this.wakelockEnabled = true,
    this.snakeControlMode = SnakeControlMode.swipe,
    this.snakeShowGridLines = true,
    this.snakeAssistOverlay = true,
    this.chessPieceSet = ChessPieceSet.cburnett,
    this.chessAutoQueen = true,
    this.chessShowLegalMoves = true,
    this.chessShowCoordinates = true,
    this.chessMoveConfirmMode = ChessMoveConfirmMode.off,
    this.chessAutoFlipPassPlay = false,
    this.sudokuAutoFinish = true,
    this.sudokuAutoFinishThreshold = 5,
    this.sudokuHighlightSameDigits = true,
    this.sudokuAutoClearNotes = true,
    this.sudokuShowStreakStats = true,
    this.sudokuSmartCandidateNotes = false,
    this.minesweeperQuickChord = true,
    this.minesweeperSwapTapFlag = false,
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
  final BgmMode bgmMode;
  final String bgmTrack;
  final bool hapticsEnabled;
  final HapticIntensity hapticIntensity;

  bool get bgmEnabled => bgmMode != BgmMode.off;
  final bool wakelockEnabled;
  final SnakeControlMode snakeControlMode;
  final bool snakeShowGridLines;
  final bool snakeAssistOverlay;
  final ChessPieceSet chessPieceSet;
  final bool chessAutoQueen;
  final bool chessShowLegalMoves;
  final bool chessShowCoordinates;
  final ChessMoveConfirmMode chessMoveConfirmMode;
  final bool chessAutoFlipPassPlay;
  final bool sudokuAutoFinish;
  final int sudokuAutoFinishThreshold;
  final bool sudokuHighlightSameDigits;
  final bool sudokuAutoClearNotes;
  final bool sudokuShowStreakStats;
  final bool sudokuSmartCandidateNotes;
  final bool minesweeperQuickChord;
  final bool minesweeperSwapTapFlag;
  final bool practiceRewindOnLoss;
  final int practiceRewindSteps;
  final int guestChessElo;
  final Map<GameType, int> guestUnlockedLevels;

  AppSettings copyWith({
    ZetzyThemeMode? themeMode,
    String? localeCode,
    bool? sfxEnabled,
    BgmMode? bgmMode,
    String? bgmTrack,
    bool? bgmEnabled,
    bool? hapticsEnabled,
    HapticIntensity? hapticIntensity,
    bool? wakelockEnabled,
    SnakeControlMode? snakeControlMode,
    bool? snakeShowGridLines,
    bool? snakeAssistOverlay,
    ChessPieceSet? chessPieceSet,
    bool? chessAutoQueen,
    bool? chessShowLegalMoves,
    bool? chessShowCoordinates,
    ChessMoveConfirmMode? chessMoveConfirmMode,
    bool? chessAutoFlipPassPlay,
    bool? sudokuAutoFinish,
    int? sudokuAutoFinishThreshold,
    bool? sudokuHighlightSameDigits,
    bool? sudokuAutoClearNotes,
    bool? sudokuShowStreakStats,
    bool? sudokuSmartCandidateNotes,
    bool? minesweeperQuickChord,
    bool? minesweeperSwapTapFlag,
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
      bgmMode:
          bgmMode ??
          (bgmEnabled == null
              ? this.bgmMode
              : (bgmEnabled ? BgmMode.auto : BgmMode.off)),
      bgmTrack: bgmTrack ?? this.bgmTrack,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      wakelockEnabled: wakelockEnabled ?? this.wakelockEnabled,
      snakeControlMode: snakeControlMode ?? this.snakeControlMode,
      snakeShowGridLines: snakeShowGridLines ?? this.snakeShowGridLines,
      snakeAssistOverlay: snakeAssistOverlay ?? this.snakeAssistOverlay,
      chessPieceSet: chessPieceSet ?? this.chessPieceSet,
      chessAutoQueen: chessAutoQueen ?? this.chessAutoQueen,
      chessShowLegalMoves: chessShowLegalMoves ?? this.chessShowLegalMoves,
      chessShowCoordinates: chessShowCoordinates ?? this.chessShowCoordinates,
      chessMoveConfirmMode: chessMoveConfirmMode ?? this.chessMoveConfirmMode,
      chessAutoFlipPassPlay:
          chessAutoFlipPassPlay ?? this.chessAutoFlipPassPlay,
      sudokuAutoFinish: sudokuAutoFinish ?? this.sudokuAutoFinish,
      sudokuAutoFinishThreshold: rawThreshold >= 7 ? 7 : 5,
      sudokuHighlightSameDigits:
          sudokuHighlightSameDigits ?? this.sudokuHighlightSameDigits,
      sudokuAutoClearNotes: sudokuAutoClearNotes ?? this.sudokuAutoClearNotes,
      sudokuShowStreakStats:
          sudokuShowStreakStats ?? this.sudokuShowStreakStats,
      sudokuSmartCandidateNotes:
          sudokuSmartCandidateNotes ?? this.sudokuSmartCandidateNotes,
      minesweeperQuickChord:
          minesweeperQuickChord ?? this.minesweeperQuickChord,
      minesweeperSwapTapFlag:
          minesweeperSwapTapFlag ?? this.minesweeperSwapTapFlag,
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
  static const _kBgmMode = 'zetzy_bgm_mode';
  static const _kBgmTrack = 'zetzy_bgm_track';
  static const _kHaptics = 'zetzy_haptics';
  static const _kHapticIntensity = 'zetzy_haptic_intensity';
  static const _kWakelock = 'zetzy_wakelock';
  static const _kSnakeCtrl = 'zetzy_snake_ctrl';
  static const _kSnakeGrid = 'zetzy_snake_grid';
  static const _kSnakeAssistOverlay = 'zetzy_snake_assist_overlay';
  static const _kChessPieces = 'zetzy_chess_pieces';
  static const _kChessAutoQueen = 'zetzy_chess_auto_queen';
  static const _kChessLegalMoves = 'zetzy_chess_legal_moves';
  static const _kChessCoordinates = 'zetzy_chess_coordinates';
  static const _kChessMoveConfirm = 'zetzy_chess_move_confirm';
  static const _kChessAutoFlipPassPlay = 'zetzy_chess_auto_flip_pass_play';
  static const _kSudokuAutoFinish = 'zetzy_sudoku_auto_finish';
  static const _kSudokuAutoFinishThreshold =
      'zetzy_sudoku_auto_finish_threshold';
  static const _kSudokuHighlightSame = 'zetzy_sudoku_highlight_same';
  static const _kSudokuAutoClearNotes = 'zetzy_sudoku_auto_clear_notes';
  static const _kSudokuStreakStats = 'zetzy_sudoku_streak_stats';
  static const _kSudokuSmartNotes = 'zetzy_sudoku_smart_notes';
  static const _kMinesweeperQuickChord = 'zetzy_minesweeper_quick_chord';
  static const _kMinesweeperSwapTapFlag = 'zetzy_minesweeper_swap_tap_flag';
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
      bgmMode: BgmMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kBgmMode),
        orElse: () => BgmMode.auto,
      ),
      bgmTrack: _prefs.getString(_kBgmTrack) ?? '5.mp3',
      hapticsEnabled: _prefs.getBool(_kHaptics) ?? true,
      hapticIntensity: HapticIntensity.values.firstWhere(
        (m) => m.name == _prefs.getString(_kHapticIntensity),
        orElse: () => HapticIntensity.medium,
      ),
      wakelockEnabled: _prefs.getBool(_kWakelock) ?? true,
      snakeControlMode: SnakeControlMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kSnakeCtrl),
        orElse: () => SnakeControlMode.swipe,
      ),
      snakeShowGridLines: _prefs.getBool(_kSnakeGrid) ?? true,
      snakeAssistOverlay: _prefs.getBool(_kSnakeAssistOverlay) ?? true,
      chessPieceSet: ChessPieceSet.values.firstWhere(
        (s) => s.folder == _prefs.getString(_kChessPieces),
        orElse: () => ChessPieceSet.cburnett,
      ),
      chessAutoQueen: _prefs.getBool(_kChessAutoQueen) ?? true,
      chessShowLegalMoves: _prefs.getBool(_kChessLegalMoves) ?? true,
      chessShowCoordinates: _prefs.getBool(_kChessCoordinates) ?? true,
      chessMoveConfirmMode: ChessMoveConfirmMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kChessMoveConfirm),
        orElse: () => ChessMoveConfirmMode.off,
      ),
      chessAutoFlipPassPlay: _prefs.getBool(_kChessAutoFlipPassPlay) ?? false,
      sudokuAutoFinish: _prefs.getBool(_kSudokuAutoFinish) ?? true,
      sudokuAutoFinishThreshold: savedThreshold >= 7 ? 7 : 5,
      sudokuHighlightSameDigits:
          _prefs.getBool(_kSudokuHighlightSame) ?? true,
      sudokuAutoClearNotes: _prefs.getBool(_kSudokuAutoClearNotes) ?? true,
      sudokuShowStreakStats: _prefs.getBool(_kSudokuStreakStats) ?? true,
      sudokuSmartCandidateNotes: _prefs.getBool(_kSudokuSmartNotes) ?? false,
      minesweeperQuickChord:
          _prefs.getBool(_kMinesweeperQuickChord) ?? true,
      minesweeperSwapTapFlag:
          _prefs.getBool(_kMinesweeperSwapTapFlag) ?? false,
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
      _prefs.setString(_kBgmMode, s.bgmMode.name),
      _prefs.setString(_kBgmTrack, s.bgmTrack),
      _prefs.setBool(_kHaptics, s.hapticsEnabled),
      _prefs.setString(_kHapticIntensity, s.hapticIntensity.name),
      _prefs.setBool(_kWakelock, s.wakelockEnabled),
      _prefs.setString(_kSnakeCtrl, s.snakeControlMode.name),
      _prefs.setBool(_kSnakeGrid, s.snakeShowGridLines),
      _prefs.setBool(_kSnakeAssistOverlay, s.snakeAssistOverlay),
      _prefs.setString(_kChessPieces, s.chessPieceSet.folder),
      _prefs.setBool(_kChessAutoQueen, s.chessAutoQueen),
      _prefs.setBool(_kChessLegalMoves, s.chessShowLegalMoves),
      _prefs.setBool(_kChessCoordinates, s.chessShowCoordinates),
      _prefs.setString(_kChessMoveConfirm, s.chessMoveConfirmMode.name),
      _prefs.setBool(_kChessAutoFlipPassPlay, s.chessAutoFlipPassPlay),
      _prefs.setBool(_kSudokuAutoFinish, s.sudokuAutoFinish),
      _prefs.setInt(_kSudokuAutoFinishThreshold, s.sudokuAutoFinishThreshold),
      _prefs.setBool(_kSudokuHighlightSame, s.sudokuHighlightSameDigits),
      _prefs.setBool(_kSudokuAutoClearNotes, s.sudokuAutoClearNotes),
      _prefs.setBool(_kSudokuStreakStats, s.sudokuShowStreakStats),
      _prefs.setBool(_kSudokuSmartNotes, s.sudokuSmartCandidateNotes),
      _prefs.setBool(_kMinesweeperQuickChord, s.minesweeperQuickChord),
      _prefs.setBool(_kMinesweeperSwapTapFlag, s.minesweeperSwapTapFlag),
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
