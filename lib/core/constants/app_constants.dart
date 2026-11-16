import 'package:material_ui/material_ui.dart';
import 'package:zetzy/l10n/app_localizations.dart';

/// The four core games in the Zetzy suite.
enum GameType {
  sudoku('sudoku'),
  chess('chess'),
  minesweeper('minesweeper'),
  snake('snake');

  const GameType(this.id);
  final String id;

  static GameType fromId(String id) => GameType.values.firstWhere(
    (g) => g.id == id,
    orElse: () => GameType.sudoku,
  );

  String localizedTitle(AppLocalizations l10n) => switch (this) {
    GameType.sudoku => l10n.gameSudoku,
    GameType.chess => l10n.gameChess,
    GameType.minesweeper => l10n.gameMinesweeper,
    GameType.snake => l10n.gameSnake,
  };

  String localizedSubtitle(AppLocalizations l10n) => switch (this) {
    GameType.sudoku => l10n.gameSudokuDesc,
    GameType.chess => l10n.gameChessDesc,
    GameType.minesweeper => l10n.gameMinesweeperDesc,
    GameType.snake => l10n.gameSnakeDesc,
  };

  IconData get icon => switch (this) {
    GameType.sudoku => Icons.grid_on_rounded,
    GameType.chess => Icons.castle_rounded,
    GameType.minesweeper => Icons.flag_rounded,
    GameType.snake => Icons.route_rounded,
  };
}

/// Seven official difficulty levels with progressive unlock rules.
enum DifficultyLevel {
  chill(1, 'Chill', 10),
  easy(2, 'Easy', 25),
  normal(3, 'Normal', 50),
  high(4, 'High', 100),
  pro(5, 'PRO', 175),
  nightmare(6, 'Nightmare', 300),
  god(7, 'Are U a God?', 500);

  const DifficultyLevel(this.level, this.defaultLabel, this.xpReward);

  final int level;
  final String defaultLabel;
  final int xpReward;

  String get badgeAsset => 'assets/images/badge/$level.png';

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    DifficultyLevel.chill => l10n.diffChill,
    DifficultyLevel.easy => l10n.diffEasy,
    DifficultyLevel.normal => l10n.diffNormal,
    DifficultyLevel.high => l10n.diffHigh,
    DifficultyLevel.pro => l10n.diffPro,
    DifficultyLevel.nightmare => l10n.diffNightmare,
    DifficultyLevel.god => l10n.diffGod,
  };

  static DifficultyLevel fromLevel(int level) =>
      DifficultyLevel.values.firstWhere(
        (d) => d.level == level,
        orElse: () => DifficultyLevel.normal,
      );

  /// Levels 1..5 are open by default; 6 unlocks on winning 5; 7 on winning 6.
  static const int defaultUnlockedLevel = 5;
}

/// Touch control styles for Snake on mobile/touch devices.
enum SnakeControlMode { swipe, dpad, splitTap }

/// Controls when Chess asks for a second tap/confirm before submitting a move.
enum ChessMoveConfirmMode { off, fastOnly, always }

/// Controls vibration duration and amplitude for in-game haptic feedback.
enum HapticIntensity { light, medium, strong }

/// Available SVG chess piece themes bundled in assets/icons/chess/.
enum ChessPieceSet {
  cburnett('cburnett', 'Cburnett'),
  cburnettV2('cburnett-v2', 'Cburnett v2'),
  tatiana('tatiana', 'Tatiana');

  const ChessPieceSet(this.folder, this.label);
  final String folder;
  final String label;

  String pieceAsset(String colorPrefix, String pieceCode) =>
      'assets/icons/chess/$folder/$colorPrefix$pieceCode.svg';
}

/// Asset paths matching the repository's assets directory.
abstract final class AssetPaths {
  static const String appIcon = 'assets/images/ico.jpeg';

  // Minesweeper images
  static const String mineNormal = 'assets/images/minesweeper/mine_normal.png';
  static const String mineExploded =
      'assets/images/minesweeper/mine_exploded.png';
  static const String mineDefused =
      'assets/images/minesweeper/mine_defused.png';
  static const String mineFlag = 'assets/images/minesweeper/flag.png';
  static const String mineQuestion =
      'assets/images/minesweeper/question_mark.png';
  static const String mineShield = 'assets/images/minesweeper/shield_icon.png';

  // Snake item sprites
  static const String snakeApple = 'assets/images/snake/food_apple.png';
  static const String snakeGolden = 'assets/images/snake/food_golden.png';
  static const String snakeScissors = 'assets/images/snake/item_scissors.png';
  static const String snakePoison = 'assets/images/snake/item_poison.png';
  static const String snakeWall = 'assets/images/snake/wall_brick.png';

  // Platform SVG icons
  static const String chessPawn = 'assets/icons/chess/cburnett/bP.svg';

  static String platformIcon(String platform) => switch (platform) {
    'android' => 'assets/icons/platforms/ic_platform_android.svg',
    'web' => 'assets/icons/platforms/ic_platform_web.svg',
    'windows' => 'assets/icons/platforms/ic_platform_windows.svg',
    'linux' => 'assets/icons/platforms/ic_platform_linux.svg',
    'ios' => 'assets/icons/platforms/ic_platform_ios.svg',
    'macos' => 'assets/icons/platforms/ic_platform_macos.svg',
    _ => 'assets/icons/platforms/ic_platform_web.svg',
  };
}

/// Authentication & validation rules from PRD Section 2.2.
abstract final class ValidationRules {
  static final RegExp usernameRegex = RegExp(r'^[a-z0-9_]{3,16}$');
  static final RegExp passwordLetterRegex = RegExp(r'[A-Za-z]');
  static final RegExp passwordDigitRegex = RegExp(r'[0-9]');

  static bool isValidUsername(String value) => usernameRegex.hasMatch(value);

  static bool isValidPassword(String value) =>
      value.length >= 8 &&
      passwordLetterRegex.hasMatch(value) &&
      passwordDigitRegex.hasMatch(value);

  static String dummyEmailFor(String username) => '$username@arcade.local';
}
