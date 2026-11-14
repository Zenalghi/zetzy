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
    this.chessPieceSet = ChessPieceSet.cburnett,
    this.chessAutoQueen = true,
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
  final ChessPieceSet chessPieceSet;
  final bool chessAutoQueen;
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
    ChessPieceSet? chessPieceSet,
    bool? chessAutoQueen,
    int? guestChessElo,
    Map<GameType, int>? guestUnlockedLevels,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      wakelockEnabled: wakelockEnabled ?? this.wakelockEnabled,
      snakeControlMode: snakeControlMode ?? this.snakeControlMode,
      chessPieceSet: chessPieceSet ?? this.chessPieceSet,
      chessAutoQueen: chessAutoQueen ?? this.chessAutoQueen,
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
  static const _kChessPieces = 'zetzy_chess_pieces';
  static const _kChessAutoQueen = 'zetzy_chess_auto_queen';
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
      chessPieceSet: ChessPieceSet.values.firstWhere(
        (s) => s.folder == _prefs.getString(_kChessPieces),
        orElse: () => ChessPieceSet.cburnett,
      ),
      chessAutoQueen: _prefs.getBool(_kChessAutoQueen) ?? true,
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
      _prefs.setString(_kChessPieces, s.chessPieceSet.folder),
      _prefs.setBool(_kChessAutoQueen, s.chessAutoQueen),
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
