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
      'Undo anytime & rewind 1–3 steps on loss. Scores stay off leaderboard.';

  @override
  String get practiceUndo => 'Undo';

  @override
  String practiceRewindContinue(int count) {
    return 'Rewind $count & Continue';
  }

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
  String get sudokuConflictGuideTitle => 'PRO+ Conflict Check Mode';

  @override
  String get sudokuConflictGuideBody =>
      '• Chill – High (Levels 1–4): Digits are checked immediately against the solution key. Any wrong entry costs 1 life, and correct cells lock.\n• PRO – God (Levels 5–7): The hidden solution is not spoiled, so you can test and change guesses freely.\n• How Lives Decrease in PRO+: Placing a duplicate conflict in the same row, column, or 3×3 box costs 1 life (PRO: 3, Nightmare: 2, God: 1 Sudden Death).\n• Win / Lose: Running out of lives ends the game. Completing all 81 cells with zero conflicts wins.';

  @override
  String get chessModeVsAi => 'Vs AI';

  @override
  String get chessModePassPlay => 'Pass & Play';

  @override
  String get chessModeFindMatch => 'Find Match';

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
  String get chessFindMatchStart => 'Find Match';

  @override
  String get chessFindingMatchTitle => 'Finding Ranked Opponent...';

  @override
  String chessSearchingEloRange(int minElo, int maxElo, int radius) {
    return 'Searching ELO: $minElo – $maxElo (±$radius)';
  }

  @override
  String chessSearchingNearestElo(int minElo, int maxElo) {
    return 'Searching ELO: $minElo – $maxElo (Nearest Available)';
  }

  @override
  String get chessExpandingRangeHint =>
      'No equal ELO found yet? Range widens automatically to the nearest online player.';

  @override
  String chessFindMatchStage(int stage, int total, int seconds) {
    return 'Stage $stage/$total • ${seconds}s';
  }

  @override
  String get chessMatchTimedOnlyNote =>
      'Find Match requires a timed clock (Untimed disabled to prevent AFK stalling).';

  @override
  String get chessAutoColorFair =>
      'Colors are assigned randomly and fairly upon match.';

  @override
  String get chessOnlineUnratedNote =>
      'Private Friend Rooms are Unrated (Casual) to prevent ELO/PRO+ score boosting.';

  @override
  String get chessAbortedTooShortTitle => 'Match Aborted';

  @override
  String get chessAbortedTooShortNote =>
      'Ended before 4 half-moves — marked Unrated (0 ELO change) under Fair Play rules.';

  @override
  String get chessOpponentLabel => 'Opponent';

  @override
  String chessYourElo(int elo) {
    return 'Your ELO: $elo';
  }

  @override
  String chessMatchFoundBanner(String username, int elo) {
    return 'Matched vs @$username (ELO $elo)';
  }

  @override
  String get chessTapForDetails => 'Tap for ELO, scoring & setup guide';

  @override
  String get chessModeGuideTitle => 'Match Rules & Scoring';

  @override
  String get chessPracticeDisabledNote =>
      'Practice Mode is active: ELO, Leaderboard, XP, and level unlocks are turned off for this match.';

  @override
  String chessTimeControlRule(String timeLabel) {
    return 'Time Control ($timeLabel) sets the countdown clock for each player only. Bullet, Blitz, Rapid, and Untimed all give the same ELO and XP (faster wins only break Leaderboard ties).';
  }

  @override
  String get chessInfoSummaryVsAi => 'Ranked • ELO vs AI & Leaderboard';

  @override
  String get chessInfoSummaryPassPlay =>
      'Local 2-Player • Unrated (No ELO/Score)';

  @override
  String get chessInfoSummaryFindMatch =>
      'Ranked Random 1v1 • Dynamic ELO Matchmaking';

  @override
  String get chessInfoSummaryOnline => 'Friend Room 1v1 • Unrated (Anti-Cheat)';

  @override
  String get chessInfoSummaryPractice =>
      'Practice Mode • Unrated (No ELO/Score)';

  @override
  String chessInfoDetailVsAi(String level, String rating, String xp) {
    return '• Opponent Strength: AI Level $level (Rating $rating).\n• Chess ELO & Leaderboard: Wins, draws, and losses update your Chess ELO (K=32 formula). Your ELO delta is saved as score, and wins appear on the Leaderboard plus grant +$xp XP.\n• Level Unlocks: Winning PRO unlocks Nightmare, and winning Nightmare unlocks Are U a God?.';
  }

  @override
  String get chessInfoDetailPassPlay =>
      '• How to Play: Take turns playing White and Black on this same device — hand the device over after each move.\n• Score & ELO: Treated as a casual local match (same as Practice Mode). It does NOT change Chess ELO, does NOT save to Leaderboard, and does NOT award XP or unlock levels.';

  @override
  String get chessInfoDetailFindMatch =>
      '• Fair Random Matchmaking: Matches you against another live player queued in the same Timed control (Bullet, Blitz, or Rapid).\n• Expanding ELO Window: Starts searching near your ELO (±50) and widens automatically over time (±120 → ±250 → ±500 → ±1000). After 45s, it opens to the nearest online player (400–3500) even if the ELO gap is hundreds or thousands of points.\n• Anti-Cheat Protection: Colors are assigned randomly, self-matching is blocked, resigns/abandons before 4 half-moves are Aborted (0 ELO), ELO updates use the matched opponent rating (K=32), and AI Nightmare/God levels only unlock in Vs AI.';

  @override
  String get chessInfoDetailOnline =>
      '• Concept: Private 1v1 room via Supabase Realtime for playing with friends.\n• Host & Join: Sign in first. Host picks side & Time Control then shares the 6-character code; friend enters the code to join.\n• Anti-Cheat & Unrated Rule: Private Room matches are strictly Unrated — no Chess ELO change, no PRO+ Leaderboard entry, no XP, and no Nightmare/God level unlock so private rooms cannot be used for win-trading.';

  @override
  String get chessCopyCode => 'Copy';

  @override
  String chessRoomCodeCopied(String code) {
    return 'Room code copied: $code';
  }

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
  String leaderboardLoadMore(int count) {
    return 'Load $count more';
  }

  @override
  String get leaderboardRefresh => 'Refresh';

  @override
  String leaderboardShowingCount(int count) {
    return 'Showing $count entries • Refresh for newest';
  }

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
  String get profileConfigureAccount => 'Configure Account';

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
  String get profileDangerZoneDesc =>
      'Destructive actions here erase your statistics or permanently delete your account and cannot be undone.';

  @override
  String profileAppVersion(String version) {
    return 'Zetzy v$version';
  }

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
  String get settingsPracticeRewind => 'Practice Rewind on Loss';

  @override
  String get settingsPracticeRewindDesc =>
      'Allow rewinding 1–3 steps on loss instead of restarting in Practice Mode.';

  @override
  String get settingsPracticeRewindSteps => 'Rewind Steps on Loss';

  @override
  String practiceRewindStepOption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Steps',
      one: '1 Step',
    );
    return '$_temp0';
  }

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
  String get themeAbyssalCyan => 'Abyssal Cyan';

  @override
  String get themeWarmParchment => 'Warm Parchment';

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

  @override
  String get reviewBoard => 'View Board';

  @override
  String get viewResult => 'View Result';

  @override
  String wrongFlagsCount(int count) {
    return '$count wrong flag(s)';
  }

  @override
  String get minesRevealedHint =>
      'All mines & flags revealed. Pinch or drag to inspect.';

  @override
  String get chessReviewTitle => 'Move Review';

  @override
  String chessMoveStep(int current, int total) {
    return 'Ply $current/$total';
  }

  @override
  String get sudokuShowSolution => 'Show Answer';

  @override
  String get sudokuHideSolution => 'Hide Answer';

  @override
  String get sudokuMistakeReviewHint =>
      'Incorrect entries are highlighted in red.';

  @override
  String get snakeDeathWall => 'Crashed into the arena wall.';

  @override
  String get snakeDeathObstacle => 'Crashed into an obstacle block.';

  @override
  String get snakeDeathSelf => 'Collided with your own body.';

  @override
  String get snakeDeathStarvation => 'Energy ran out before reaching food.';

  @override
  String get snakeAllCleared => 'Cleared the arena!';

  @override
  String get settingsInGameTitle => 'Quick Settings';

  @override
  String get settingsInGameSubtitle => 'Safe to adjust during an active match';

  @override
  String get settingsSudokuAutoFinish => 'Auto-Finish Endgame';

  @override
  String get settingsSudokuAutoFinishDesc =>
      'Show Auto-Finish button when only a few cells remain.';

  @override
  String get settingsSudokuAutoFinishThreshold => 'Remaining Empty Cells';

  @override
  String sudokuRemainingCellsOption(int count) {
    return '$count Cells';
  }

  @override
  String sudokuAutoFinishAction(int count) {
    return 'Auto-Finish ($count)';
  }

  @override
  String get settingsSudokuHighlightSame => 'Highlight Matching Digits';

  @override
  String get settingsSudokuAutoClearNotes => 'Auto-Clear Peer Notes';

  @override
  String get settingsChessLegalMoves => 'Show Legal Move Hints';

  @override
  String get settingsChessCoordinates => 'Show Board Coordinates';

  @override
  String get settingsMinesweeperQuickChord => 'Tap Number to Chord';

  @override
  String get settingsMinesweeperQuickChordDesc =>
      'Open adjacent tiles when surrounding flags match.';

  @override
  String get settingsSnakeGridLines => 'Show Arena Grid Lines';

  @override
  String get settingsPracticeSection => 'Practice Mode';

  @override
  String get settingsSudokuStreakStats => 'Mistake-Free Streak & Accuracy';

  @override
  String get settingsSudokuStreakStatsDesc =>
      'Show live streak and accuracy percentage on board & summary.';

  @override
  String get settingsSudokuSmartNotes => 'Smart Candidate Notes';

  @override
  String get settingsSudokuSmartNotesDesc =>
      'Auto-fill valid candidates in Practice Mode or Beginner Lv 1–2.';

  @override
  String get sudokuFillCandidates => 'Smart Notes';

  @override
  String sudokuStreakBadge(int count) {
    return 'Streak $count';
  }

  @override
  String get sudokuBestStreakLabel => 'Best Streak';

  @override
  String get sudokuAccuracyLabel => 'Accuracy';

  @override
  String get settingsMinesweeperSwapTapFlag => 'Swap Tap & Flag (One-Handed)';

  @override
  String get settingsMinesweeperSwapTapFlagDesc =>
      'Short tap places flags and long-press digs instead.';

  @override
  String get mineTapFlagActive => '1-Tap: Flag';

  @override
  String get mineTapDigActive => '1-Tap: Dig';

  @override
  String get settingsChessMoveConfirm => 'Touch Move Confirmation';

  @override
  String get settingsChessConfirmOff => 'Off';

  @override
  String get settingsChessConfirmFast => 'Bullet/Blitz';

  @override
  String get settingsChessConfirmAlways => 'Always';

  @override
  String get settingsChessAutoFlipPassPlay => 'Auto-Flip in Pass & Play';

  @override
  String chessConfirmMovePrompt(String move) {
    return 'Confirm $move?';
  }

  @override
  String get settingsSnakeAssistOverlay => 'Ghost Wall & Turn Guide';

  @override
  String get settingsSnakeAssistOverlayDesc =>
      'Show obstacle warning preview and swipe direction arrows.';

  @override
  String get settingsHapticIntensity => 'Vibration Strength';

  @override
  String get hapticLight => 'Light';

  @override
  String get hapticMedium => 'Medium';

  @override
  String get hapticStrong => 'Strong';

  @override
  String get bgmModeOff => 'Off';

  @override
  String get bgmModeAuto => 'Auto';

  @override
  String get bgmModeManual => 'Manual';

  @override
  String bgmAutoDesc(int number) {
    return 'Smart shuffle across all tracks (★ Track $number plays more often).';
  }

  @override
  String get bgmFavoriteTrackLabel => 'Favorite Track (3× Priority in Auto)';

  @override
  String bgmTrackLabel(int number) {
    return 'Track $number';
  }

  @override
  String bgmNowPlaying(int number) {
    return 'Playing: Track $number';
  }

  @override
  String get bgmNextTrack => 'Next Track';

  @override
  String get badgesTitle => 'Rank Badges';

  @override
  String get badgesSubtitle => 'Tap any crest to enlarge & inspect';

  @override
  String badgesConqueredCount(int count, int total) {
    return '$count/$total Conquered';
  }

  @override
  String badgeWonCount(int count) {
    return '$count× Won';
  }

  @override
  String get badgeStatusOpen => 'Ready';

  @override
  String get badgeStatusLocked => 'Locked';

  @override
  String get badgeAvailableAllGames => 'Open from start across all 4 games';

  @override
  String get badgeUnlockedChallenge => 'Unlocked tier — Master-level challenge';

  @override
  String get badgeSelectedPreview => 'Selected Tier';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackAdminInboxTitle => 'Feedback Inbox';

  @override
  String get feedbackTabInbox => 'Admin Inbox';

  @override
  String get feedbackTabMine => 'My Feedback';

  @override
  String get feedbackPrivacyNote =>
      'Feedback can only be seen by you and admins.';

  @override
  String get feedbackSignInRequired =>
      'Sign in to your account to send feedback or view admin responses.';

  @override
  String feedbackPendingCount(int count, int max) {
    return 'Pending: $count/$max';
  }

  @override
  String get feedbackPlaceholder =>
      'Share a bug report, feature suggestion, or experience...';

  @override
  String get feedbackSubmit => 'Send Feedback';

  @override
  String feedbackLimitReached(int max) {
    return 'Max $max pending feedback items reached. Wait for admin review or delete an older one.';
  }

  @override
  String get feedbackStatusPending => 'Pending';

  @override
  String get feedbackStatusApproved => 'Approved';

  @override
  String get feedbackStatusRejected => 'Rejected';

  @override
  String get feedbackEditAction => 'Edit';

  @override
  String get feedbackEditDialogTitle => 'Edit Feedback';

  @override
  String feedbackEditWindow(String time) {
    return 'Editable ($time)';
  }

  @override
  String get feedbackEditLocked => 'Edit locked (>6h)';

  @override
  String get feedbackDeleteAction => 'Delete';

  @override
  String get feedbackDeleteConfirmTitle => 'Delete Feedback?';

  @override
  String get feedbackDeleteConfirmBody =>
      'This feedback item will be removed permanently.';

  @override
  String get feedbackAdminReplyLabel => 'Admin Reply';

  @override
  String feedbackAutoDeleteNotice(String time) {
    return 'Deletes in $time';
  }

  @override
  String get feedbackReviewActionApprove => 'Approve';

  @override
  String get feedbackReviewActionReject => 'Reject';

  @override
  String get feedbackReviewDialogTitle => 'Review & Reply (1× Only)';

  @override
  String get feedbackReviewReplyHint => 'Optional reply message for player...';

  @override
  String get feedbackEmptyMine => 'No feedback sent yet.';

  @override
  String get feedbackEmptyInbox => 'No player feedback yet.';

  @override
  String get feedbackLoadMore => 'Load More (20)';

  @override
  String get profileFeedbackButton => 'Feedback';

  @override
  String get profileRoleAdminBadge => 'ADMIN';

  @override
  String get homeGuideTutorialButton => 'Guide & Tutorial';

  @override
  String guideDialogTitle(String game) {
    return '$game Visual Guide';
  }

  @override
  String get guideDialogSubtitle =>
      'Swipe slides to explore visual rules & tips';

  @override
  String get guidePrev => 'Prev';

  @override
  String get guideNext => 'Next';

  @override
  String get guideClose => 'Close Guide';

  @override
  String get guideStartTutorial => 'Start Tutorial';

  @override
  String get guideSudokuS1Badge => '1. CORE RULE';

  @override
  String get guideSudokuS1Title => 'Fill 1–9 Without Duplicates';

  @override
  String get guideSudokuS1Desc =>
      'A 9×9 Sudoku board is divided into nine 3×3 boxes. Fill every empty cell with a digit from 1 to 9.';

  @override
  String get guideSudokuS1Bullets =>
      'Every horizontal ROW must contain 1–9 with no repeats.\nEvery vertical COLUMN must contain 1–9 with no repeats.\nEvery bold 3×3 BOX must contain 1–9 with no repeats.';

  @override
  String get guideSudokuS1VisualCaption =>
      'Only 5 is missing in the center box!';

  @override
  String get guideSudokuS2Badge => '2. HOW TO PLAY';

  @override
  String get guideSudokuS2Title => 'Tap a Cell & Use Number Highlights';

  @override
  String get guideSudokuS2Desc =>
      'Tapping any digit highlights all identical numbers across the board so you can quickly cross-check rows and columns.';

  @override
  String get guideSudokuS2Bullets =>
      'Select an empty cell, then tap 1–9 on the bottom keypad.\nOn Levels 1–4, correct placements lock automatically.\nTap the selected cell again to clear the highlight.';

  @override
  String get guideSudokuS3Badge => '3. SAFE STRATEGY';

  @override
  String get guideSudokuS3Title => 'Use Pencil Notes & Smart Notes';

  @override
  String get guideSudokuS3Desc =>
      'Unsure between two numbers? Never guess blindly! Toggle Notes (✏️) to jot down mini candidate digits inside a cell.';

  @override
  String get guideSudokuS3Bullets =>
      'Entering Notes never costs a life (♥).\nSmart Notes automatically prunes impossible candidates.\nUse Erase to clear a cell or its pencil marks.';

  @override
  String get guideSudokuS3VisualBadge => 'Notes ON (Safe)';

  @override
  String get guideSudokuS4Badge => '4. LIVES & ASSISTS';

  @override
  String get guideSudokuS4Title => '3 Lives (♥), 3 Hints & ⚡ Auto-Finish';

  @override
  String get guideSudokuS4Desc =>
      'You start with 3 lives and up to 3 Hints. When only a few empty cells remain, the lightning Auto-Finish button appears!';

  @override
  String get guideSudokuS4Bullets =>
      'Mistakes flash red and cost 1 heart (♥).\n⚡ Auto-Finish completes the board when ≤ 5–7 cells remain.\nIn Practice Mode, Undo and Rewind on Loss are freely available!';

  @override
  String get guideSudokuS4VisualBadge => 'Auto-Finish (≤ 5 Left)';

  @override
  String get guideMineS1Badge => '1. NUMBER MEANING';

  @override
  String get guideMineS1Title => 'Numbers Show Adjacent Mines';

  @override
  String get guideMineS1Desc =>
      'Every revealed number (1, 2, 3...) tells you exactly how many mines hide in the 8 surrounding tiles (including diagonals).';

  @override
  String get guideMineS1Bullets =>
      'Your first tap is ALWAYS 100% safe and opens a clear zone.\nA \"1\" means exactly 1 touching hidden tile contains a mine.\nBlank tiles (0) flood-fill open all safe neighbors automatically.';

  @override
  String get guideMineS1VisualCaption =>
      'The center \"1\" touches exactly 1 mine in the top-right corner!';

  @override
  String get guideMineS2Badge => '2. DIG VS FLAG';

  @override
  String get guideMineS2Title => 'Plant Flags (🚩) on Suspected Mines';

  @override
  String get guideMineS2Desc =>
      'Never dig a tile you suspect is a mine! Mark it with a Flag (🚩) so it cannot be accidentally tapped.';

  @override
  String get guideMineS2Bullets =>
      'Long-press any hidden tile to place or remove a Flag.\nOr toggle the 1-Tap Swap button between Dig ⛏️ and Flag 🚩.\nYou win as soon as all safe non-mine tiles are revealed!';

  @override
  String get guideMineS2VisualCaption =>
      'Lock suspected mine tiles with a Flag (🚩)!';

  @override
  String get guideMineS3Badge => '3. PRO TECHNIQUE';

  @override
  String get guideMineS3Title => 'Chording: Fast-Open Safe Neighbors';

  @override
  String get guideMineS3Desc =>
      'When an open number already touches the matching number of Flags (🚩), tap the number itself to open all remaining neighbors instantly!';

  @override
  String get guideMineS3Bullets =>
      'Example: A \"1\" already touches 1 Flag → tap that \"1\"!\nAll other hidden tiles touching that \"1\" open at once.\nMake sure your flag placement is accurate before chording!';

  @override
  String get guideMineS4Badge => '4. BEGINNER SHIELD';

  @override
  String get guideMineS4Title => 'Defuse Shield (🛡️) Saves You';

  @override
  String get guideMineS4Desc =>
      'On Beginner Levels 1–2, you start with a Defuse Shield (🛡️) that automatically disarms a mine if you make a mistake!';

  @override
  String get guideMineS4Bullets =>
      'Defused mines appear safely disarmed on the board.\nPost-game review highlights all mines and any misplaced flags.\nTap View Board after a match to inspect the full mine layout.';

  @override
  String get guideMineS4VisualCaption =>
      'Lv. 1–2 Shield automatically defuses a mine!';

  @override
  String get guideChessS1Badge => '1. PIECE MOVEMENTS';

  @override
  String get guideChessS1Title => 'How All 6 Chess Pieces Move';

  @override
  String get guideChessS1Desc =>
      'Tap any of your pieces to see legal target dots on the board. Only the Knight (♘) can jump over other pieces!';

  @override
  String get guideChessS1Bullets =>
      '♔ King: 1 step any way • ♕ Queen: any distance straight or diagonal.\n♖ Rook: straight lines • ♗ Bishop: diagonals only.\n♘ Knight: L-shape jump (2+1) • ♙ Pawn: moves forward, captures diagonally.';

  @override
  String get guideChessS2Badge => '2. CHECKMATE VS STALEMATE';

  @override
  String get guideChessS2Title => 'Watch Out: Stalemate Is a Draw!';

  @override
  String get guideChessS2Desc =>
      'Trapping the enemy King without putting it in Check leaves them with zero legal moves—resulting in a STALEMATE (Draw), not a win!';

  @override
  String get guideChessS2Bullets =>
      'Check: King is under attack and must escape immediately.\nCheckmate: King is in Check with no legal escape → YOU WIN!\nDraw: Stalemate, 3-fold repetition, 50-move rule, or insufficient material.';

  @override
  String get guideChessS2Checkmate => 'CHECKMATE (Win)';

  @override
  String get guideChessS2Stalemate => 'STALEMATE (Draw!)';

  @override
  String get guideChessS3Badge => '3. SPECIAL RULE #1';

  @override
  String get guideChessS3Title => 'Castling (♔⇄♖): King + Rook Double Move';

  @override
  String get guideChessS3Desc =>
      'The only move where two pieces move at once! Move your King 2 squares toward your Rook, and the Rook jumps over to the other side.';

  @override
  String get guideChessS3Bullets =>
      'Rule 1: Neither the King nor that Rook has moved yet.\nRule 2: Every square between King and Rook must be empty.\nRule 3: The King cannot be in Check or pass through an attacked square.';

  @override
  String get guideChessS3VisualCaption =>
      'Kingside Castling: King e1 → g1, Rook h1 → f1 jumps over!';

  @override
  String get guideChessS4Badge => '4. SPECIAL RULE #2';

  @override
  String get guideChessS4Title => 'En Passant & Pawn Promotion (♙ → ♕)';

  @override
  String get guideChessS4Desc =>
      'Two crucial pawn rules that often surprise players: capturing \"in passing\" (En Passant) and promoting at the 8th rank!';

  @override
  String get guideChessS4Bullets =>
      'En Passant: When an enemy pawn advances 2 squares beside yours, you can capture it diagonally on the very next turn as if it moved 1 square.\nPromotion: Reaching the last rank transforms your pawn into a Queen (♕), Rook, Bishop, or Knight!';

  @override
  String get guideChessS4VisualPromo => 'Promotion → Queen';

  @override
  String get guideChessS5Badge => '5. ZETZY CHESS FEATURES';

  @override
  String get guideChessS5Title => 'Touch Confirmation, Board Flip & Review';

  @override
  String get guideChessS5Desc =>
      'Zetzy includes thoughtful touch safeguards and post-match analysis tools.';

  @override
  String get guideChessS5Bullets =>
      'Touch Move Confirmation previews your move before locking it in.\n4 Modes: Vs AI (Lv. 1–7), Pass & Play (2P), Friend Room, & Rated Matchmaking.\nUse the post-game move scrubber (⏮ ◀ ▶ ⏭) to replay every turn!';

  @override
  String get guideSnakeS1Badge => '1. CONTROLS & MOVEMENT';

  @override
  String get guideSnakeS1Title => 'Turn 90° & Never Bite Your Own Tail';

  @override
  String get guideSnakeS1Desc =>
      'Your snake advances smoothly across the grid. Steer toward apples while avoiding walls and your own growing body.';

  @override
  String get guideSnakeS1Bullets =>
      'Choose Swipe, Virtual D-Pad, or Split-Screen Tap in Profile settings.\nYou can turn 90° perpendicular to your heading, never 180° backward.\nArrow keys and WASD are also supported on keyboard devices.';

  @override
  String get guideSnakeS2Badge => '2. APPLES & POWER-UPS';

  @override
  String get guideSnakeS2Title => 'Red Apples, Golden Bonus, Scissors & Poison';

  @override
  String get guideSnakeS2Desc =>
      'Learn what each arena item does to maximize your score and manage tail length!';

  @override
  String get guideSnakeS2Bullets =>
      '🍎 Red Apple (+10 pts): core food needed to reach the level target.\n🌟 Golden Apple (+30 pts): timed bonus item for massive points!\n✂️ Scissors: trims your tail shorter to free up space on the board.\n☠️ Poison: avoid! Stepping on poison triggers a hazard penalty.';

  @override
  String get guideSnakeS2Trim => 'Trim';

  @override
  String get guideSnakeS2Hazard => 'Hazard';

  @override
  String get guideSnakeS3Badge => '3. WALLS & OBSTACLES';

  @override
  String get guideSnakeS3Title => 'Brick Walls & Dynamic Obstacles';

  @override
  String get guideSnakeS3Desc =>
      'Higher difficulty tiers introduce brick wall obstacles inside the arena that require sharp turns.';

  @override
  String get guideSnakeS3Bullets =>
      '2-Step Input Queue lets you buffer quick zig-zag turns cleanly.\nEnable Assist Overlay in settings for helpful hazard indicators.';

  @override
  String get guideSnakeS3VisualCaption => 'Dodge brick walls inside the arena!';

  @override
  String get guideSnakeS4Badge => '4. STARVATION BAR';

  @override
  String get guideSnakeS4Title => 'Watch the Starvation Bar on High Tiers!';

  @override
  String get guideSnakeS4Desc =>
      'On Levels 6–7, a Starvation Bar drains over time. Eat apples promptly to refill your stamina before it runs out!';

  @override
  String get guideSnakeS4Bullets =>
      'Plan the shortest path toward the next Red Apple.\nIn Practice Mode, use Rewind 1–3 steps to recover from any crash!';

  @override
  String get guideSnakeS4VisualCaption => 'Starvation Timer (Lv. 6–7)';

  @override
  String get tutorialExitTooltip => 'Exit Tutorial';

  @override
  String tutorialAppBarTitle(String game) {
    return 'Tutorial • $game';
  }

  @override
  String get tutorialPausedBadge => '⏸️ PAUSED • COACH GUIDE';

  @override
  String get tutorialTryItBadge => '👆 YOUR TURN • TRY IT';

  @override
  String tutorialActionProgress(int current, int total) {
    return 'Action $current/$total';
  }

  @override
  String get tutorialGotItBtn => 'Got It, Try Now!';

  @override
  String get tutorialReadTipFirst =>
      'Read the coach tip first, then press \"Got It, Try Now!\"';

  @override
  String get tutorialTapBlinking => 'Tap the blinking button or tile!';

  @override
  String get tutorialCompleteTitle => 'Tutorial Complete! 🎉';

  @override
  String tutorialCompleteBody(String game) {
    return 'You practiced the core rules of $game. Ready for a real match?';
  }

  @override
  String get tutorialDoneBtn => 'Done';

  @override
  String get tutorialPlayNowBtn => 'Play Now!';

  @override
  String get tutorialHudLabel => 'Tutorial';

  @override
  String get tutSudokuS1Title => 'Step 1/3: Select a Cell, Then Press a Digit';

  @override
  String get tutSudokuS1Exp =>
      'The highlighted center 3×3 box already holds 1, 2, 3, 4, 6, 7, 8, 9 — only 5 is missing! To fill in Sudoku: tap the cell first, then press a digit on the number pad below.';

  @override
  String get tutSudokuS1A1 =>
      'Tap the blinking empty cell in the middle of the board.';

  @override
  String get tutSudokuS1A2 => 'Great! Now press 5 on the number pad below.';

  @override
  String get tutSudokuS2Title => 'Step 2/3: Pencil Candidates with Notes (✏️)';

  @override
  String get tutSudokuS2Exp =>
      'The highlighted top row is missing 3 and 4. Not sure which goes where? Don’t guess! Turn on Notes to jot small candidates — notes never cost a heart ♥.';

  @override
  String get tutSudokuS2A1 => 'Press the blinking Notes button.';

  @override
  String get tutSudokuS2A2 => 'Tap the first empty cell in the top row.';

  @override
  String get tutSudokuS2A3 => 'Press 3 to note the first candidate.';

  @override
  String get tutSudokuS2A4 => 'Press 4 to note the second candidate.';

  @override
  String get tutSudokuS3Title => 'Step 3/3: Eliminate & Finish!';

  @override
  String get tutSudokuS3Exp =>
      'Check that cells column (highlighted): a 4 already sits at the bottom (yellow). Columns cant repeat, so the 3·4 cell must be 3 and its neighbor must be 4! Turn Notes off first so digits are placed for real.';

  @override
  String get tutSudokuS3A1 => 'Turn Notes off first.';

  @override
  String get tutSudokuS3A2 => 'Tap the cell holding the 3·4 notes.';

  @override
  String get tutSudokuS3A3 => 'Press 3.';

  @override
  String get tutSudokuS3A4 => 'One empty cell left beside it. Tap it.';

  @override
  String get tutSudokuS3A5 => 'Press 4 to complete the board!';

  @override
  String get tutSudokuWrongCellFirst =>
      'Select the cell first, then press a digit.';

  @override
  String get tutSudokuWrongPressDigit =>
      'The cell is selected — now press the blinking digit below.';

  @override
  String get tutMineS1Title => 'Step 1/5: The First Dig Is Always Safe';

  @override
  String get tutMineS1Exp =>
      'Dig mode (⛏️) is active. In Zetzy your first dig is always safe and opens an empty area with clue numbers. A number = how many mines touch that tile (all 8 neighbors).';

  @override
  String get tutMineS1A1 => 'Tap the blinking center tile to dig.';

  @override
  String get tutMineS2Title => 'Step 2/5: Plant a Flag (🚩)';

  @override
  String get tutMineS2Exp =>
      'Look at the highlighted 1 in the top row. Only ONE of its neighbors is still hidden — so that tile MUST be a mine. Switch to Flag mode, then mark it.';

  @override
  String get tutMineS2A1 => 'Press the blinking Flag button.';

  @override
  String get tutMineS2A2 =>
      'Tap the hidden tile next to the 1 to plant a Flag.';

  @override
  String get tutMineS3Title => 'Step 3/5: Unsure? Mark It with (?)';

  @override
  String get tutMineS3Exp =>
      'The highlighted 2 needs 2 mines. One is flagged, so the other hides in one of the 2 corner tiles. Not sure which? Use the (?) tool as a reminder — (?) tiles can’t be dug by accident.';

  @override
  String get tutMineS3A1 => 'Press the blinking (?) button.';

  @override
  String get tutMineS3A2 => 'Tap the top-left corner tile to mark it (?).';

  @override
  String get tutMineS4Title => 'Step 4/5: Find the Second Mine';

  @override
  String get tutMineS4Exp =>
      'Now check the highlighted 1 in the left column. Only one neighbor is hidden — the tile above it. That’s the second mine! Switch back to Flag.';

  @override
  String get tutMineS4A1 => 'Press the Flag button.';

  @override
  String get tutMineS4A2 => 'Tap the tile above that 1 to plant a Flag.';

  @override
  String get tutMineS5Title => 'Step 5/5: Dig the Last Safe Tile!';

  @override
  String get tutMineS5Exp =>
      'The highlighted 2 now touches 2 flags — its mine count is complete. So the (?) corner is 100% SAFE. Switch back to Dig and open it to win!';

  @override
  String get tutMineS5A1 => 'Press the Dig button.';

  @override
  String get tutMineS5A2 =>
      'Tap the (?) tile in the top-left corner to dig it.';

  @override
  String get tutMineWrongSwitchTool =>
      'Switch tools first using the blinking button below.';

  @override
  String get tutChessS1Title => 'Step 1/4: The Knight (♘) Jumps in an L';

  @override
  String get tutChessS1Exp =>
      'In chess, tap your piece first to see where it can go. Dots = empty squares it can reach, RED = an enemy piece it can capture. The Knight moves in an L shape and can jump over pieces.';

  @override
  String get tutChessS1A1 => 'Tap the blinking white Knight.';

  @override
  String get tutChessS1A2 =>
      'See every highlighted Knight move. The RED square holds the enemy Queen — tap it to capture!';

  @override
  String get tutChessS2Title => 'Step 2/4: Castling (♔⇄♖)';

  @override
  String get tutChessS2Exp =>
      'Castling = the King slides 2 squares toward a Rook, and the Rook hops to its other side. Rules: neither piece has moved, the squares between are empty, and the King is not in or passing through check.';

  @override
  String get tutChessS2A1 => 'Tap the blinking white King first.';

  @override
  String get tutChessS2A2 =>
      'The ⇄ square is the castling move. Tap it to castle!';

  @override
  String get tutChessS3Title => 'Step 3/4: En Passant (♙↗)';

  @override
  String get tutChessS3Exp =>
      'Black’s pawn just advanced 2 squares (d7 → d5, yellow) and landed right beside your pawn. On this turn only, your pawn may capture it diagonally as if it had moved 1 square — that’s En Passant.';

  @override
  String get tutChessS3A1 => 'Tap the white pawn on e5.';

  @override
  String get tutChessS3A2 =>
      'Tap the RED square behind the black pawn for En Passant!';

  @override
  String get tutChessS4Title => 'Step 4/4: Pawn Promotion → Checkmate!';

  @override
  String get tutChessS4Exp =>
      'A pawn reaching the last rank MUST promote to a Queen, Rook, Bishop, or Knight. Black’s King is boxed in by its own pawns — promoting to a Queen on a8 is Checkmate!';

  @override
  String get tutChessS4A1 => 'Tap the white pawn on a7.';

  @override
  String get tutChessS4A2 => 'Tap a8 on the last rank.';

  @override
  String get tutChessS4A3 => 'Choose the Queen (♕) — the strongest piece!';

  @override
  String get tutChessWrongOtherLegal =>
      'That’s a legal move, but pick the blinking square for this lesson.';

  @override
  String get tutChessWrongTapPieceFirst =>
      'Tap the blinking piece first to reveal its moves.';

  @override
  String get tutChessPromoLabel => 'Promote pawn to:';

  @override
  String get tutChessCheckmateStatus => '♛ CHECKMATE! White wins.';

  @override
  String get tutChessWhiteToMove => 'White to move';

  @override
  String get tutSnakeS1Title => 'Step 1/3: Turn 90° Toward the Apple 🍎';

  @override
  String get tutSnakeS1Exp =>
      'Your snake keeps moving right — straight toward POISON ☠️! A red apple (+10) sits above its head. Steer upward. Snakes turn 90° only, never a 180° U-turn.';

  @override
  String get tutSnakeS2Title => 'Step 2/3: Grab the Scissors ✂️ to Trim';

  @override
  String get tutSnakeS2Exp =>
      'Yum! +10 and the snake grew longer. The arena edge is ahead (up). The Scissors ✂️ on the right trim your tail for more room. Avoid the brick wall 🧱!';

  @override
  String get tutSnakeS3Title => 'Step 3/3: Golden Apple 🌟 (+30)';

  @override
  String get tutSnakeS3Exp =>
      'Tail trimmed! The arena edge is ahead (right). The Golden Apple (+30) is below on a path clear of poison ☠️. Turn down to grab it!';

  @override
  String tutSnakePromptDpad(String dir) {
    return 'Press the blinking $dir button on the D-Pad.';
  }

  @override
  String get tutSnakePromptSplitLeft =>
      'Tap the blinking LEFT side (turn counter-clockwise).';

  @override
  String get tutSnakePromptSplitRight =>
      'Tap the blinking RIGHT side (turn clockwise).';

  @override
  String tutSnakePromptSwipe(String dir) {
    return 'Swipe the arena $dir (or tap the blinking arrow).';
  }

  @override
  String get tutSnakeDirUp => 'UP';

  @override
  String get tutSnakeDirDown => 'DOWN';

  @override
  String get tutSnakeDirLeft => 'LEFT';

  @override
  String get tutSnakeDirRight => 'RIGHT';

  @override
  String get tutSnakeWrongUTurn =>
      'Snakes can’t make a 180° U-turn — they’d bite their own body!';

  @override
  String get tutSnakeCtrlLeftSide => 'Left Side';

  @override
  String get tutSnakeCtrlRightSide => 'Right Side';

  @override
  String get tutSnakeSwipeHint =>
      'Swipe controls (from Profile): swipe the arena toward your target.';
}
