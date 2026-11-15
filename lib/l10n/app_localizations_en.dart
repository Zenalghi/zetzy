// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zetzy';

  @override
  String get navHome => 'Play';

  @override
  String get navLeaderboard => 'Leaderboard';

  @override
  String get navStatistics => 'Stats';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeSubtitle => 'Tactile Arcade & Strategy Suite';

  @override
  String get continueGame => 'Continue';

  @override
  String get newGame => 'New Game';

  @override
  String get play => 'Play';

  @override
  String get practiceMode => 'Practice Mode';

  @override
  String get practiceModeDesc =>
      'Unlimited retries. Scores are not saved to leaderboard.';

  @override
  String get selectDifficulty => 'Select Difficulty';

  @override
  String lockedLevelHint(String prevLevel) {
    return 'Win $prevLevel once to unlock';
  }

  @override
  String get guestModeBanner => 'Playing Offline (Guest Mode)';

  @override
  String syncQueuePending(int count) {
    return '$count score(s) queued for cloud sync';
  }

  @override
  String get gameSudoku => 'Sudoku';

  @override
  String get gameSudokuDesc =>
      '9×9 logic puzzle with smart notes & 17-clue mastery';

  @override
  String get gameChess => 'Chess';

  @override
  String get gameChessDesc =>
      'Vs AI, Pass & Play, or Online Room with ELO rating';

  @override
  String get gameMinesweeper => 'Minesweeper';

  @override
  String get gameMinesweeperDesc =>
      'Chording, Defuse shield & 3BV speedrun metrics';

  @override
  String get gameSnake => 'Snake';

  @override
  String get gameSnakeDesc =>
      'Smooth arcade with mazes, power-ups & starvation mode';

  @override
  String get diffChill => 'Chill';

  @override
  String get diffEasy => 'Easy';

  @override
  String get diffNormal => 'Normal';

  @override
  String get diffHigh => 'High';

  @override
  String get diffPro => 'PRO';

  @override
  String get diffNightmare => 'Nightmare';

  @override
  String get diffGod => 'Are U a God?';

  @override
  String get pausedTitle => 'Game Paused';

  @override
  String get pausedSubtitle => 'Anti-cheat blur active. Timer stopped.';

  @override
  String get resume => 'Resume';

  @override
  String get restart => 'Restart';

  @override
  String get quit => 'Exit';

  @override
  String get victory => 'Victory!';

  @override
  String get gameOver => 'Game Over';

  @override
  String get draw => 'Draw';

  @override
  String get newRecord => 'New Personal Best!';

  @override
  String get timeLabel => 'Time';

  @override
  String get scoreLabel => 'Score';

  @override
  String get mistakesLabel => 'Mistakes';

  @override
  String get playAgain => 'Play Again';

  @override
  String get shareScore => 'Share Score';

  @override
  String get backToHome => 'Back to Menu';

  @override
  String get sudokuLives => 'Lives';

  @override
  String get sudokuUnlimited => 'Unlimited';

  @override
  String get sudokuNotes => 'Notes';

  @override
  String get sudokuErase => 'Erase';

  @override
  String get sudokuHint => 'Hint';

  @override
  String get sudokuUndoNotes => 'Undo Note';

  @override
  String get sudokuDigitLockHint => 'Long-press a digit to lock rapid input';

  @override
  String get sudokuConflictOnlyNote => 'PRO+ mode: Conflict check only';

  @override
  String get chessModeVsAi => 'Vs AI';

  @override
  String get chessModePassPlay => 'Pass & Play';

  @override
  String get chessModeOnline => 'Online Room';

  @override
  String get chessPlayAs => 'Play As';

  @override
  String get chessWhite => 'White';

  @override
  String get chessBlack => 'Black';

  @override
  String get chessRandom => 'Random';

  @override
  String get chessTimeControl => 'Time Control';

  @override
  String get chessUntimed => 'Untimed';

  @override
  String get chessBullet => 'Bullet (1m)';

  @override
  String get chessBlitz3 => 'Blitz (3m)';

  @override
  String get chessBlitz5 => 'Blitz (5m)';

  @override
  String get chessRapid => 'Rapid (10m)';

  @override
  String get chessUndo => 'Undo';

  @override
  String get chessUndoLocked => 'Undo locked on PRO+';

  @override
  String get chessResign => 'Resign';

  @override
  String get chessFlipBoard => 'Flip';

  @override
  String get chessMoves => 'Moves (PGN)';

  @override
  String get chessCaptured => 'Captured';

  @override
  String get chessPromotion => 'Promote Pawn';

  @override
  String get chessAiThinking => 'AI thinking...';

  @override
  String get chessCheck => 'Check!';

  @override
  String get chessCreateRoom => 'Create Room';

  @override
  String get chessJoinRoom => 'Join Room';

  @override
  String get chessRoomCode => 'Room Code';

  @override
  String get chessWaitingOpponent => 'Waiting for opponent...';

  @override
  String get chessOnlineRequiresAuth =>
      'Sign in to your account to play Online Multiplayer.';

  @override
  String get mineRemaining => 'Mines';

  @override
  String get mineModeDig => 'Dig';

  @override
  String get mineModeFlag => 'Flag';

  @override
  String get mineModeQuestion => 'Mark (?)';

  @override
  String get mineShieldActive => 'Defuse Shield Ready';

  @override
  String get mineShieldUsed => 'Shield Used!';

  @override
  String get mine3bv => '3BV';

  @override
  String get mine3bvSec => '3BV/s';

  @override
  String get mineDesktopHint =>
      'Scroll: Zoom • Right-click: Flag • Middle/Space+Drag: Pan';

  @override
  String get snakeSpeed => 'Speed';

  @override
  String get snakeLength => 'Length';

  @override
  String get snakeStarvation => 'Hunger';

  @override
  String get snakeDebuffReversed => 'POISONED! Controls Reversed';

  @override
  String get snakeObstacleWarning => 'Shifting walls incoming!';

  @override
  String get snakeDesktopHint => 'Use WASD or Arrow Keys';

  @override
  String get snakeTapLeft => 'Turn Left';

  @override
  String get snakeTapRight => 'Turn Right';

  @override
  String get leaderboardGlobal => 'Global Top 100';

  @override
  String get leaderboardMyBest => 'My Best';

  @override
  String get leaderboardChessElo => 'Chess ELO';

  @override
  String get leaderboardEmpty => 'No records yet for this filter.';

  @override
  String get leaderboardRank => 'Rank';

  @override
  String get leaderboardPlayer => 'Player';

  @override
  String get leaderboardPlatform => 'Device';

  @override
  String get statsTotalGames => 'Total Played';

  @override
  String get statsTotalWins => 'Wins';

  @override
  String get statsWinRate => 'Win Rate';

  @override
  String get statsBestStreak => 'Best Streak';

  @override
  String get statsTotalTime => 'Play Time';

  @override
  String get statsAvgTime => 'Avg Duration';

  @override
  String statsPlayerLevel(int level) {
    return 'Level $level';
  }

  @override
  String statsXp(int xp) {
    return '$xp XP';
  }

  @override
  String get statsChartTitle => 'Recent Performance & Win Trend';

  @override
  String get profileGuest => 'Guest Player';

  @override
  String get profileSignIn => 'Sign In';

  @override
  String get profileRegister => 'Create Account';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileUsername => 'Username';

  @override
  String get profilePassword => 'Password';

  @override
  String get profileConfirmPassword => 'Confirm Password';

  @override
  String get profileOldPassword => 'Old Password';

  @override
  String get profileNewPassword => 'New Password';

  @override
  String get profileForgotPassword => 'Forgot Password?';

  @override
  String get profileRecoveryPhrase => 'Recovery Code / Passphrase';

  @override
  String get profileRecoveryToggle => 'Enable Recovery Code';

  @override
  String get profileRecoveryDesc =>
      'Allows password reset without email via hashed recovery phrase.';

  @override
  String get profileChangeUsername => 'Change Username';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileUploadAvatar => 'Upload Avatar';

  @override
  String get profileAvatarUpdated => 'Profile photo updated!';

  @override
  String get profileAvatarSignInRequired =>
      'Sign in or create an account to upload a profile photo.';

  @override
  String get profileAvatarSourceGallery => 'Choose from Gallery / Photos';

  @override
  String get profileAvatarSourceCamera => 'Take Photo with Camera';

  @override
  String get profileResetStats => 'Reset All Statistics';

  @override
  String get profileDeleteAccount => 'Delete Account Permanently';

  @override
  String get profileDangerZone => 'Account & Data Management';

  @override
  String get settingsAppearance => 'Appearance & Language';

  @override
  String get settingsTheme => 'Theme Skin';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsGameplay => 'Gameplay & Controls';

  @override
  String get settingsAudioSfx => 'Sound Effects (SFX)';

  @override
  String get settingsAudioBgm => 'Background Music (BGM)';

  @override
  String get settingsAudioPending => 'Audio asset pack coming soon';

  @override
  String get settingsHaptics => 'Haptic Feedback';

  @override
  String get settingsWakelock => 'Keep Screen Awake in Game';

  @override
  String get settingsSnakeControl => 'Snake Touch Control';

  @override
  String get settingsSnakeSwipe => 'Swipe Gesture';

  @override
  String get settingsSnakeDpad => 'Virtual D-Pad';

  @override
  String get settingsSnakeSplit => 'Split-Screen Tap';

  @override
  String get settingsChessPieces => 'Chess Piece Style';

  @override
  String get settingsChessAutoQueen => 'Auto-Queen Promotion';

  @override
  String get settingsCloudStatus => 'Cloud & Sync';

  @override
  String get settingsSupabaseConfigured => 'Cloud Sync Connected';

  @override
  String get settingsSupabaseLocalOnly =>
      'Offline Mode (Cloud sync unavailable)';

  @override
  String get themeOledMidnight => 'OLED Midnight';

  @override
  String get themeClassicWood => 'Classic Wood & Slate';

  @override
  String get themeNordicFrost => 'Nordic Frost';

  @override
  String get themeDraculaNeon => 'Dracula Neon';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get requiredHint => '* Required';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get invalidUsername =>
      '3–16 chars: lowercase letters, numbers, or _ only.';

  @override
  String get invalidPassword =>
      'Min 8 characters with both letters and numbers.';
}
