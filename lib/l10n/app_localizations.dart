// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Zetzy'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navHome;

  /// No description provided for @navLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get navLeaderboard;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStatistics;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tactile Arcade & Strategy Suite'**
  String get homeSubtitle;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @practiceMode.
  ///
  /// In en, this message translates to:
  /// **'Practice Mode'**
  String get practiceMode;

  /// No description provided for @practiceModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Undo anytime & rewind 1–3 steps on loss. Scores stay off leaderboard.'**
  String get practiceModeDesc;

  /// No description provided for @practiceUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get practiceUndo;

  /// No description provided for @practiceRewindContinue.
  ///
  /// In en, this message translates to:
  /// **'Rewind {count} & Continue'**
  String practiceRewindContinue(int count);

  /// No description provided for @selectDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Select Difficulty'**
  String get selectDifficulty;

  /// No description provided for @lockedLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Win {prevLevel} once to unlock'**
  String lockedLevelHint(String prevLevel);

  /// No description provided for @guestModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Playing Offline (Guest Mode)'**
  String get guestModeBanner;

  /// No description provided for @syncQueuePending.
  ///
  /// In en, this message translates to:
  /// **'{count} score(s) queued for cloud sync'**
  String syncQueuePending(int count);

  /// No description provided for @gameSudoku.
  ///
  /// In en, this message translates to:
  /// **'Sudoku'**
  String get gameSudoku;

  /// No description provided for @gameSudokuDesc.
  ///
  /// In en, this message translates to:
  /// **'9×9 logic puzzle with smart notes & 17-clue mastery'**
  String get gameSudokuDesc;

  /// No description provided for @gameChess.
  ///
  /// In en, this message translates to:
  /// **'Chess'**
  String get gameChess;

  /// No description provided for @gameChessDesc.
  ///
  /// In en, this message translates to:
  /// **'Vs AI, Pass & Play, or Online Room with ELO rating'**
  String get gameChessDesc;

  /// No description provided for @gameMinesweeper.
  ///
  /// In en, this message translates to:
  /// **'Minesweeper'**
  String get gameMinesweeper;

  /// No description provided for @gameMinesweeperDesc.
  ///
  /// In en, this message translates to:
  /// **'Chording, Defuse shield & 3BV speedrun metrics'**
  String get gameMinesweeperDesc;

  /// No description provided for @gameSnake.
  ///
  /// In en, this message translates to:
  /// **'Snake'**
  String get gameSnake;

  /// No description provided for @gameSnakeDesc.
  ///
  /// In en, this message translates to:
  /// **'Smooth arcade with mazes, power-ups & starvation mode'**
  String get gameSnakeDesc;

  /// No description provided for @diffChill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get diffChill;

  /// No description provided for @diffEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get diffEasy;

  /// No description provided for @diffNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get diffNormal;

  /// No description provided for @diffHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get diffHigh;

  /// No description provided for @diffPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get diffPro;

  /// No description provided for @diffNightmare.
  ///
  /// In en, this message translates to:
  /// **'Nightmare'**
  String get diffNightmare;

  /// No description provided for @diffGod.
  ///
  /// In en, this message translates to:
  /// **'Are U a God?'**
  String get diffGod;

  /// No description provided for @pausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Paused'**
  String get pausedTitle;

  /// No description provided for @pausedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anti-cheat blur active. Timer stopped.'**
  String get pausedSubtitle;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get quit;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victory;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New Personal Best!'**
  String get newRecord;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @mistakesLabel.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get mistakesLabel;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @shareScore.
  ///
  /// In en, this message translates to:
  /// **'Share Score'**
  String get shareScore;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get backToHome;

  /// No description provided for @sudokuLives.
  ///
  /// In en, this message translates to:
  /// **'Lives'**
  String get sudokuLives;

  /// No description provided for @sudokuUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get sudokuUnlimited;

  /// No description provided for @sudokuNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get sudokuNotes;

  /// No description provided for @sudokuErase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get sudokuErase;

  /// No description provided for @sudokuHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get sudokuHint;

  /// No description provided for @sudokuUndoNotes.
  ///
  /// In en, this message translates to:
  /// **'Undo Note'**
  String get sudokuUndoNotes;

  /// No description provided for @sudokuDigitLockHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a digit to lock rapid input'**
  String get sudokuDigitLockHint;

  /// No description provided for @sudokuConflictOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'PRO+ mode: Conflict check only'**
  String get sudokuConflictOnlyNote;

  /// No description provided for @sudokuConflictGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'PRO+ Conflict Check Mode'**
  String get sudokuConflictGuideTitle;

  /// No description provided for @sudokuConflictGuideBody.
  ///
  /// In en, this message translates to:
  /// **'• Chill – High (Levels 1–4): Digits are checked immediately against the solution key. Any wrong entry costs 1 life, and correct cells lock.\n• PRO – God (Levels 5–7): The hidden solution is not spoiled, so you can test and change guesses freely.\n• How Lives Decrease in PRO+: Placing a duplicate conflict in the same row, column, or 3×3 box costs 1 life (PRO: 3, Nightmare: 2, God: 1 Sudden Death).\n• Win / Lose: Running out of lives ends the game. Completing all 81 cells with zero conflicts wins.'**
  String get sudokuConflictGuideBody;

  /// No description provided for @chessModeVsAi.
  ///
  /// In en, this message translates to:
  /// **'Vs AI'**
  String get chessModeVsAi;

  /// No description provided for @chessModePassPlay.
  ///
  /// In en, this message translates to:
  /// **'Pass & Play'**
  String get chessModePassPlay;

  /// No description provided for @chessModeFindMatch.
  ///
  /// In en, this message translates to:
  /// **'Find Match'**
  String get chessModeFindMatch;

  /// No description provided for @chessModeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online Room'**
  String get chessModeOnline;

  /// No description provided for @chessPlayAs.
  ///
  /// In en, this message translates to:
  /// **'Play As'**
  String get chessPlayAs;

  /// No description provided for @chessWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get chessWhite;

  /// No description provided for @chessBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get chessBlack;

  /// No description provided for @chessRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get chessRandom;

  /// No description provided for @chessTimeControl.
  ///
  /// In en, this message translates to:
  /// **'Time Control'**
  String get chessTimeControl;

  /// No description provided for @chessUntimed.
  ///
  /// In en, this message translates to:
  /// **'Untimed'**
  String get chessUntimed;

  /// No description provided for @chessBullet.
  ///
  /// In en, this message translates to:
  /// **'Bullet (1m)'**
  String get chessBullet;

  /// No description provided for @chessBlitz3.
  ///
  /// In en, this message translates to:
  /// **'Blitz (3m)'**
  String get chessBlitz3;

  /// No description provided for @chessBlitz5.
  ///
  /// In en, this message translates to:
  /// **'Blitz (5m)'**
  String get chessBlitz5;

  /// No description provided for @chessRapid.
  ///
  /// In en, this message translates to:
  /// **'Rapid (10m)'**
  String get chessRapid;

  /// No description provided for @chessUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get chessUndo;

  /// No description provided for @chessUndoLocked.
  ///
  /// In en, this message translates to:
  /// **'Undo locked on PRO+'**
  String get chessUndoLocked;

  /// No description provided for @chessResign.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get chessResign;

  /// No description provided for @chessFlipBoard.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get chessFlipBoard;

  /// No description provided for @chessMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves (PGN)'**
  String get chessMoves;

  /// No description provided for @chessCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get chessCaptured;

  /// No description provided for @chessPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promote Pawn'**
  String get chessPromotion;

  /// No description provided for @chessAiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI thinking...'**
  String get chessAiThinking;

  /// No description provided for @chessCheck.
  ///
  /// In en, this message translates to:
  /// **'Check!'**
  String get chessCheck;

  /// No description provided for @chessCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get chessCreateRoom;

  /// No description provided for @chessJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get chessJoinRoom;

  /// No description provided for @chessRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Room Code'**
  String get chessRoomCode;

  /// No description provided for @chessWaitingOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent...'**
  String get chessWaitingOpponent;

  /// No description provided for @chessOnlineRequiresAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to play Online Multiplayer.'**
  String get chessOnlineRequiresAuth;

  /// No description provided for @chessFindMatchStart.
  ///
  /// In en, this message translates to:
  /// **'Find Match'**
  String get chessFindMatchStart;

  /// No description provided for @chessFindingMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding Ranked Opponent...'**
  String get chessFindingMatchTitle;

  /// No description provided for @chessSearchingEloRange.
  ///
  /// In en, this message translates to:
  /// **'Searching ELO: {minElo} – {maxElo} (±{radius})'**
  String chessSearchingEloRange(int minElo, int maxElo, int radius);

  /// No description provided for @chessSearchingNearestElo.
  ///
  /// In en, this message translates to:
  /// **'Searching ELO: {minElo} – {maxElo} (Nearest Available)'**
  String chessSearchingNearestElo(int minElo, int maxElo);

  /// No description provided for @chessExpandingRangeHint.
  ///
  /// In en, this message translates to:
  /// **'No equal ELO found yet? Range widens automatically to the nearest online player.'**
  String get chessExpandingRangeHint;

  /// No description provided for @chessFindMatchStage.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage}/{total} • {seconds}s'**
  String chessFindMatchStage(int stage, int total, int seconds);

  /// No description provided for @chessMatchTimedOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Find Match requires a timed clock (Untimed disabled to prevent AFK stalling).'**
  String get chessMatchTimedOnlyNote;

  /// No description provided for @chessAutoColorFair.
  ///
  /// In en, this message translates to:
  /// **'Colors are assigned randomly and fairly upon match.'**
  String get chessAutoColorFair;

  /// No description provided for @chessOnlineUnratedNote.
  ///
  /// In en, this message translates to:
  /// **'Private Friend Rooms are Unrated (Casual) to prevent ELO/PRO+ score boosting.'**
  String get chessOnlineUnratedNote;

  /// No description provided for @chessAbortedTooShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Aborted'**
  String get chessAbortedTooShortTitle;

  /// No description provided for @chessAbortedTooShortNote.
  ///
  /// In en, this message translates to:
  /// **'Ended before 4 half-moves — marked Unrated (0 ELO change) under Fair Play rules.'**
  String get chessAbortedTooShortNote;

  /// No description provided for @chessOpponentLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get chessOpponentLabel;

  /// No description provided for @chessYourElo.
  ///
  /// In en, this message translates to:
  /// **'Your ELO: {elo}'**
  String chessYourElo(int elo);

  /// No description provided for @chessMatchFoundBanner.
  ///
  /// In en, this message translates to:
  /// **'Matched vs @{username} (ELO {elo})'**
  String chessMatchFoundBanner(String username, int elo);

  /// No description provided for @chessTapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap for ELO, scoring & setup guide'**
  String get chessTapForDetails;

  /// No description provided for @chessModeGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Rules & Scoring'**
  String get chessModeGuideTitle;

  /// No description provided for @chessPracticeDisabledNote.
  ///
  /// In en, this message translates to:
  /// **'Practice Mode is active: ELO, Leaderboard, XP, and level unlocks are turned off for this match.'**
  String get chessPracticeDisabledNote;

  /// No description provided for @chessTimeControlRule.
  ///
  /// In en, this message translates to:
  /// **'Time Control ({timeLabel}) sets the countdown clock for each player only. Bullet, Blitz, Rapid, and Untimed all give the same ELO and XP (faster wins only break Leaderboard ties).'**
  String chessTimeControlRule(String timeLabel);

  /// No description provided for @chessInfoSummaryVsAi.
  ///
  /// In en, this message translates to:
  /// **'Ranked • ELO vs AI & Leaderboard'**
  String get chessInfoSummaryVsAi;

  /// No description provided for @chessInfoSummaryPassPlay.
  ///
  /// In en, this message translates to:
  /// **'Local 2-Player • Unrated (No ELO/Score)'**
  String get chessInfoSummaryPassPlay;

  /// No description provided for @chessInfoSummaryFindMatch.
  ///
  /// In en, this message translates to:
  /// **'Ranked Random 1v1 • Dynamic ELO Matchmaking'**
  String get chessInfoSummaryFindMatch;

  /// No description provided for @chessInfoSummaryOnline.
  ///
  /// In en, this message translates to:
  /// **'Friend Room 1v1 • Unrated (Anti-Cheat)'**
  String get chessInfoSummaryOnline;

  /// No description provided for @chessInfoSummaryPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice Mode • Unrated (No ELO/Score)'**
  String get chessInfoSummaryPractice;

  /// No description provided for @chessInfoDetailVsAi.
  ///
  /// In en, this message translates to:
  /// **'• Opponent Strength: AI Level {level} (Rating {rating}).\n• Chess ELO & Leaderboard: Wins, draws, and losses update your Chess ELO (K=32 formula). Your ELO delta is saved as score, and wins appear on the Leaderboard plus grant +{xp} XP.\n• Level Unlocks: Winning PRO unlocks Nightmare, and winning Nightmare unlocks Are U a God?.'**
  String chessInfoDetailVsAi(String level, String rating, String xp);

  /// No description provided for @chessInfoDetailPassPlay.
  ///
  /// In en, this message translates to:
  /// **'• How to Play: Take turns playing White and Black on this same device — hand the device over after each move.\n• Score & ELO: Treated as a casual local match (same as Practice Mode). It does NOT change Chess ELO, does NOT save to Leaderboard, and does NOT award XP or unlock levels.'**
  String get chessInfoDetailPassPlay;

  /// No description provided for @chessInfoDetailFindMatch.
  ///
  /// In en, this message translates to:
  /// **'• Fair Random Matchmaking: Matches you against another live player queued in the same Timed control (Bullet, Blitz, or Rapid).\n• Expanding ELO Window: Starts searching near your ELO (±50) and widens automatically over time (±120 → ±250 → ±500 → ±1000). After 45s, it opens to the nearest online player (400–3500) even if the ELO gap is hundreds or thousands of points.\n• Anti-Cheat Protection: Colors are assigned randomly, self-matching is blocked, resigns/abandons before 4 half-moves are Aborted (0 ELO), ELO updates use the matched opponent rating (K=32), and AI Nightmare/God levels only unlock in Vs AI.'**
  String get chessInfoDetailFindMatch;

  /// No description provided for @chessInfoDetailOnline.
  ///
  /// In en, this message translates to:
  /// **'• Concept: Private 1v1 room via Supabase Realtime for playing with friends.\n• Host & Join: Sign in first. Host picks side & Time Control then shares the 6-character code; friend enters the code to join.\n• Anti-Cheat & Unrated Rule: Private Room matches are strictly Unrated — no Chess ELO change, no PRO+ Leaderboard entry, no XP, and no Nightmare/God level unlock so private rooms cannot be used for win-trading.'**
  String get chessInfoDetailOnline;

  /// No description provided for @chessCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chessCopyCode;

  /// No description provided for @chessRoomCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Room code copied: {code}'**
  String chessRoomCodeCopied(String code);

  /// No description provided for @mineRemaining.
  ///
  /// In en, this message translates to:
  /// **'Mines'**
  String get mineRemaining;

  /// No description provided for @mineModeDig.
  ///
  /// In en, this message translates to:
  /// **'Dig'**
  String get mineModeDig;

  /// No description provided for @mineModeFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get mineModeFlag;

  /// No description provided for @mineModeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mark (?)'**
  String get mineModeQuestion;

  /// No description provided for @mineShieldActive.
  ///
  /// In en, this message translates to:
  /// **'Defuse Shield Ready'**
  String get mineShieldActive;

  /// No description provided for @mineShieldUsed.
  ///
  /// In en, this message translates to:
  /// **'Shield Used!'**
  String get mineShieldUsed;

  /// No description provided for @mine3bv.
  ///
  /// In en, this message translates to:
  /// **'3BV'**
  String get mine3bv;

  /// No description provided for @mine3bvSec.
  ///
  /// In en, this message translates to:
  /// **'3BV/s'**
  String get mine3bvSec;

  /// No description provided for @mineDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll: Zoom • Right-click: Flag • Middle/Space+Drag: Pan'**
  String get mineDesktopHint;

  /// No description provided for @snakeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get snakeSpeed;

  /// No description provided for @snakeLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get snakeLength;

  /// No description provided for @snakeStarvation.
  ///
  /// In en, this message translates to:
  /// **'Hunger'**
  String get snakeStarvation;

  /// No description provided for @snakeDebuffReversed.
  ///
  /// In en, this message translates to:
  /// **'POISONED! Controls Reversed'**
  String get snakeDebuffReversed;

  /// No description provided for @snakeObstacleWarning.
  ///
  /// In en, this message translates to:
  /// **'Shifting walls incoming!'**
  String get snakeObstacleWarning;

  /// No description provided for @snakeDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'Use WASD or Arrow Keys'**
  String get snakeDesktopHint;

  /// No description provided for @snakeTapLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn Left'**
  String get snakeTapLeft;

  /// No description provided for @snakeTapRight.
  ///
  /// In en, this message translates to:
  /// **'Turn Right'**
  String get snakeTapRight;

  /// No description provided for @leaderboardGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global Top 100'**
  String get leaderboardGlobal;

  /// No description provided for @leaderboardMyBest.
  ///
  /// In en, this message translates to:
  /// **'My Best'**
  String get leaderboardMyBest;

  /// No description provided for @leaderboardChessElo.
  ///
  /// In en, this message translates to:
  /// **'Chess ELO'**
  String get leaderboardChessElo;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet for this filter.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get leaderboardRank;

  /// No description provided for @leaderboardPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get leaderboardPlayer;

  /// No description provided for @leaderboardPlatform.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get leaderboardPlatform;

  /// No description provided for @leaderboardLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load {count} more'**
  String leaderboardLoadMore(int count);

  /// No description provided for @leaderboardRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get leaderboardRefresh;

  /// No description provided for @leaderboardShowingCount.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} entries • Refresh for newest'**
  String leaderboardShowingCount(int count);

  /// No description provided for @statsTotalGames.
  ///
  /// In en, this message translates to:
  /// **'Total Played'**
  String get statsTotalGames;

  /// No description provided for @statsTotalWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get statsTotalWins;

  /// No description provided for @statsWinRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get statsWinRate;

  /// No description provided for @statsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get statsBestStreak;

  /// No description provided for @statsTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Play Time'**
  String get statsTotalTime;

  /// No description provided for @statsAvgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Duration'**
  String get statsAvgTime;

  /// No description provided for @statsPlayerLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String statsPlayerLevel(int level);

  /// No description provided for @statsXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String statsXp(int xp);

  /// No description provided for @statsChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Performance & Win Trend'**
  String get statsChartTitle;

  /// No description provided for @profileGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest Player'**
  String get profileGuest;

  /// No description provided for @profileSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get profileSignIn;

  /// No description provided for @profileRegister.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get profileRegister;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsername;

  /// No description provided for @profilePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get profilePassword;

  /// No description provided for @profileConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get profileConfirmPassword;

  /// No description provided for @profileOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get profileOldPassword;

  /// No description provided for @profileNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get profileNewPassword;

  /// No description provided for @profileForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get profileForgotPassword;

  /// No description provided for @profileRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Recovery Code / Passphrase'**
  String get profileRecoveryPhrase;

  /// No description provided for @profileRecoveryToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable Recovery Code'**
  String get profileRecoveryToggle;

  /// No description provided for @profileRecoveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows password reset without email via hashed recovery phrase.'**
  String get profileRecoveryDesc;

  /// No description provided for @profileChangeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get profileChangeUsername;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profileConfigureAccount.
  ///
  /// In en, this message translates to:
  /// **'Configure Account'**
  String get profileConfigureAccount;

  /// No description provided for @profileUploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload Avatar'**
  String get profileUploadAvatar;

  /// No description provided for @profileAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get profileAvatarUpdated;

  /// No description provided for @profileAvatarSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to upload a profile photo.'**
  String get profileAvatarSignInRequired;

  /// No description provided for @profileAvatarSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery / Photos'**
  String get profileAvatarSourceGallery;

  /// No description provided for @profileAvatarSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo with Camera'**
  String get profileAvatarSourceCamera;

  /// No description provided for @profileResetStats.
  ///
  /// In en, this message translates to:
  /// **'Reset All Statistics'**
  String get profileResetStats;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Permanently'**
  String get profileDeleteAccount;

  /// No description provided for @profileDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Account & Data Management'**
  String get profileDangerZone;

  /// No description provided for @profileDangerZoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Destructive actions here erase your statistics or permanently delete your account and cannot be undone.'**
  String get profileDangerZoneDesc;

  /// No description provided for @profileAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Zetzy v{version}'**
  String profileAppVersion(String version);

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Language'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme Skin'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsGameplay.
  ///
  /// In en, this message translates to:
  /// **'Gameplay & Controls'**
  String get settingsGameplay;

  /// No description provided for @settingsAudioSfx.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects (SFX)'**
  String get settingsAudioSfx;

  /// No description provided for @settingsAudioBgm.
  ///
  /// In en, this message translates to:
  /// **'Background Music (BGM)'**
  String get settingsAudioBgm;

  /// No description provided for @settingsAudioPending.
  ///
  /// In en, this message translates to:
  /// **'Audio asset pack coming soon'**
  String get settingsAudioPending;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get settingsHaptics;

  /// No description provided for @settingsWakelock.
  ///
  /// In en, this message translates to:
  /// **'Keep Screen Awake in Game'**
  String get settingsWakelock;

  /// No description provided for @settingsSnakeControl.
  ///
  /// In en, this message translates to:
  /// **'Snake Touch Control'**
  String get settingsSnakeControl;

  /// No description provided for @settingsSnakeSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe Gesture'**
  String get settingsSnakeSwipe;

  /// No description provided for @settingsSnakeDpad.
  ///
  /// In en, this message translates to:
  /// **'Virtual D-Pad'**
  String get settingsSnakeDpad;

  /// No description provided for @settingsSnakeSplit.
  ///
  /// In en, this message translates to:
  /// **'Split-Screen Tap'**
  String get settingsSnakeSplit;

  /// No description provided for @settingsChessPieces.
  ///
  /// In en, this message translates to:
  /// **'Chess Piece Style'**
  String get settingsChessPieces;

  /// No description provided for @settingsChessAutoQueen.
  ///
  /// In en, this message translates to:
  /// **'Auto-Queen Promotion'**
  String get settingsChessAutoQueen;

  /// No description provided for @settingsPracticeRewind.
  ///
  /// In en, this message translates to:
  /// **'Practice Rewind on Loss'**
  String get settingsPracticeRewind;

  /// No description provided for @settingsPracticeRewindDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow rewinding 1–3 steps on loss instead of restarting in Practice Mode.'**
  String get settingsPracticeRewindDesc;

  /// No description provided for @settingsPracticeRewindSteps.
  ///
  /// In en, this message translates to:
  /// **'Rewind Steps on Loss'**
  String get settingsPracticeRewindSteps;

  /// No description provided for @practiceRewindStepOption.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Step} other{{count} Steps}}'**
  String practiceRewindStepOption(int count);

  /// No description provided for @settingsCloudStatus.
  ///
  /// In en, this message translates to:
  /// **'Cloud & Sync'**
  String get settingsCloudStatus;

  /// No description provided for @settingsSupabaseConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync Connected'**
  String get settingsSupabaseConfigured;

  /// No description provided for @settingsSupabaseLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode (Cloud sync unavailable)'**
  String get settingsSupabaseLocalOnly;

  /// No description provided for @themeOledMidnight.
  ///
  /// In en, this message translates to:
  /// **'OLED Midnight'**
  String get themeOledMidnight;

  /// No description provided for @themeClassicWood.
  ///
  /// In en, this message translates to:
  /// **'Classic Wood & Slate'**
  String get themeClassicWood;

  /// No description provided for @themeNordicFrost.
  ///
  /// In en, this message translates to:
  /// **'Nordic Frost'**
  String get themeNordicFrost;

  /// No description provided for @themeDraculaNeon.
  ///
  /// In en, this message translates to:
  /// **'Dracula Neon'**
  String get themeDraculaNeon;

  /// No description provided for @themeAbyssalCyan.
  ///
  /// In en, this message translates to:
  /// **'Abyssal Cyan'**
  String get themeAbyssalCyan;

  /// No description provided for @themeWarmParchment.
  ///
  /// In en, this message translates to:
  /// **'Warm Parchment'**
  String get themeWarmParchment;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @requiredHint.
  ///
  /// In en, this message translates to:
  /// **'* Required'**
  String get requiredHint;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// No description provided for @invalidUsername.
  ///
  /// In en, this message translates to:
  /// **'3–16 chars: lowercase letters, numbers, or _ only.'**
  String get invalidUsername;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters with both letters and numbers.'**
  String get invalidPassword;

  /// No description provided for @reviewBoard.
  ///
  /// In en, this message translates to:
  /// **'View Board'**
  String get reviewBoard;

  /// No description provided for @viewResult.
  ///
  /// In en, this message translates to:
  /// **'View Result'**
  String get viewResult;

  /// No description provided for @wrongFlagsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} wrong flag(s)'**
  String wrongFlagsCount(int count);

  /// No description provided for @minesRevealedHint.
  ///
  /// In en, this message translates to:
  /// **'All mines & flags revealed. Pinch or drag to inspect.'**
  String get minesRevealedHint;

  /// No description provided for @chessReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Review'**
  String get chessReviewTitle;

  /// No description provided for @chessMoveStep.
  ///
  /// In en, this message translates to:
  /// **'Ply {current}/{total}'**
  String chessMoveStep(int current, int total);

  /// No description provided for @sudokuShowSolution.
  ///
  /// In en, this message translates to:
  /// **'Show Answer'**
  String get sudokuShowSolution;

  /// No description provided for @sudokuHideSolution.
  ///
  /// In en, this message translates to:
  /// **'Hide Answer'**
  String get sudokuHideSolution;

  /// No description provided for @sudokuMistakeReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Incorrect entries are highlighted in red.'**
  String get sudokuMistakeReviewHint;

  /// No description provided for @snakeDeathWall.
  ///
  /// In en, this message translates to:
  /// **'Crashed into the arena wall.'**
  String get snakeDeathWall;

  /// No description provided for @snakeDeathObstacle.
  ///
  /// In en, this message translates to:
  /// **'Crashed into an obstacle block.'**
  String get snakeDeathObstacle;

  /// No description provided for @snakeDeathSelf.
  ///
  /// In en, this message translates to:
  /// **'Collided with your own body.'**
  String get snakeDeathSelf;

  /// No description provided for @snakeDeathStarvation.
  ///
  /// In en, this message translates to:
  /// **'Energy ran out before reaching food.'**
  String get snakeDeathStarvation;

  /// No description provided for @snakeAllCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared the arena!'**
  String get snakeAllCleared;

  /// No description provided for @settingsInGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings'**
  String get settingsInGameTitle;

  /// No description provided for @settingsInGameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Safe to adjust during an active match'**
  String get settingsInGameSubtitle;

  /// No description provided for @settingsSudokuAutoFinish.
  ///
  /// In en, this message translates to:
  /// **'Auto-Finish Endgame'**
  String get settingsSudokuAutoFinish;

  /// No description provided for @settingsSudokuAutoFinishDesc.
  ///
  /// In en, this message translates to:
  /// **'Show Auto-Finish button when only a few cells remain.'**
  String get settingsSudokuAutoFinishDesc;

  /// No description provided for @settingsSudokuAutoFinishThreshold.
  ///
  /// In en, this message translates to:
  /// **'Remaining Empty Cells'**
  String get settingsSudokuAutoFinishThreshold;

  /// No description provided for @sudokuRemainingCellsOption.
  ///
  /// In en, this message translates to:
  /// **'{count} Cells'**
  String sudokuRemainingCellsOption(int count);

  /// No description provided for @sudokuAutoFinishAction.
  ///
  /// In en, this message translates to:
  /// **'Auto-Finish ({count})'**
  String sudokuAutoFinishAction(int count);

  /// No description provided for @settingsSudokuHighlightSame.
  ///
  /// In en, this message translates to:
  /// **'Highlight Matching Digits'**
  String get settingsSudokuHighlightSame;

  /// No description provided for @settingsSudokuAutoClearNotes.
  ///
  /// In en, this message translates to:
  /// **'Auto-Clear Peer Notes'**
  String get settingsSudokuAutoClearNotes;

  /// No description provided for @settingsChessLegalMoves.
  ///
  /// In en, this message translates to:
  /// **'Show Legal Move Hints'**
  String get settingsChessLegalMoves;

  /// No description provided for @settingsChessCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Show Board Coordinates'**
  String get settingsChessCoordinates;

  /// No description provided for @settingsMinesweeperQuickChord.
  ///
  /// In en, this message translates to:
  /// **'Tap Number to Chord'**
  String get settingsMinesweeperQuickChord;

  /// No description provided for @settingsMinesweeperQuickChordDesc.
  ///
  /// In en, this message translates to:
  /// **'Open adjacent tiles when surrounding flags match.'**
  String get settingsMinesweeperQuickChordDesc;

  /// No description provided for @settingsSnakeGridLines.
  ///
  /// In en, this message translates to:
  /// **'Show Arena Grid Lines'**
  String get settingsSnakeGridLines;

  /// No description provided for @settingsPracticeSection.
  ///
  /// In en, this message translates to:
  /// **'Practice Mode'**
  String get settingsPracticeSection;

  /// No description provided for @settingsSudokuStreakStats.
  ///
  /// In en, this message translates to:
  /// **'Mistake-Free Streak & Accuracy'**
  String get settingsSudokuStreakStats;

  /// No description provided for @settingsSudokuStreakStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show live streak and accuracy percentage on board & summary.'**
  String get settingsSudokuStreakStatsDesc;

  /// No description provided for @settingsSudokuSmartNotes.
  ///
  /// In en, this message translates to:
  /// **'Smart Candidate Notes'**
  String get settingsSudokuSmartNotes;

  /// No description provided for @settingsSudokuSmartNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill valid candidates in Practice Mode or Beginner Lv 1–2.'**
  String get settingsSudokuSmartNotesDesc;

  /// No description provided for @sudokuFillCandidates.
  ///
  /// In en, this message translates to:
  /// **'Smart Notes'**
  String get sudokuFillCandidates;

  /// No description provided for @sudokuStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'Streak {count}'**
  String sudokuStreakBadge(int count);

  /// No description provided for @sudokuBestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get sudokuBestStreakLabel;

  /// No description provided for @sudokuAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get sudokuAccuracyLabel;

  /// No description provided for @settingsMinesweeperSwapTapFlag.
  ///
  /// In en, this message translates to:
  /// **'Swap Tap & Flag (One-Handed)'**
  String get settingsMinesweeperSwapTapFlag;

  /// No description provided for @settingsMinesweeperSwapTapFlagDesc.
  ///
  /// In en, this message translates to:
  /// **'Short tap places flags and long-press digs instead.'**
  String get settingsMinesweeperSwapTapFlagDesc;

  /// No description provided for @mineTapFlagActive.
  ///
  /// In en, this message translates to:
  /// **'1-Tap: Flag'**
  String get mineTapFlagActive;

  /// No description provided for @mineTapDigActive.
  ///
  /// In en, this message translates to:
  /// **'1-Tap: Dig'**
  String get mineTapDigActive;

  /// No description provided for @settingsChessMoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Touch Move Confirmation'**
  String get settingsChessMoveConfirm;

  /// No description provided for @settingsChessConfirmOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsChessConfirmOff;

  /// No description provided for @settingsChessConfirmFast.
  ///
  /// In en, this message translates to:
  /// **'Bullet/Blitz'**
  String get settingsChessConfirmFast;

  /// No description provided for @settingsChessConfirmAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get settingsChessConfirmAlways;

  /// No description provided for @settingsChessAutoFlipPassPlay.
  ///
  /// In en, this message translates to:
  /// **'Auto-Flip in Pass & Play'**
  String get settingsChessAutoFlipPassPlay;

  /// No description provided for @chessConfirmMovePrompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm {move}?'**
  String chessConfirmMovePrompt(String move);

  /// No description provided for @settingsSnakeAssistOverlay.
  ///
  /// In en, this message translates to:
  /// **'Ghost Wall & Turn Guide'**
  String get settingsSnakeAssistOverlay;

  /// No description provided for @settingsSnakeAssistOverlayDesc.
  ///
  /// In en, this message translates to:
  /// **'Show obstacle warning preview and swipe direction arrows.'**
  String get settingsSnakeAssistOverlayDesc;

  /// No description provided for @settingsHapticIntensity.
  ///
  /// In en, this message translates to:
  /// **'Vibration Strength'**
  String get settingsHapticIntensity;

  /// No description provided for @hapticLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get hapticLight;

  /// No description provided for @hapticMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get hapticMedium;

  /// No description provided for @hapticStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get hapticStrong;

  /// No description provided for @bgmModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get bgmModeOff;

  /// No description provided for @bgmModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get bgmModeAuto;

  /// No description provided for @bgmModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get bgmModeManual;

  /// No description provided for @bgmAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart shuffle across all tracks (★ Track {number} plays more often).'**
  String bgmAutoDesc(int number);

  /// No description provided for @bgmFavoriteTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite Track (3× Priority in Auto)'**
  String get bgmFavoriteTrackLabel;

  /// No description provided for @bgmTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String bgmTrackLabel(int number);

  /// No description provided for @bgmNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing: Track {number}'**
  String bgmNowPlaying(int number);

  /// No description provided for @bgmNextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next Track'**
  String get bgmNextTrack;

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rank Badges'**
  String get badgesTitle;

  /// No description provided for @badgesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap any crest to enlarge & inspect'**
  String get badgesSubtitle;

  /// No description provided for @badgesConqueredCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} Conquered'**
  String badgesConqueredCount(int count, int total);

  /// No description provided for @badgeWonCount.
  ///
  /// In en, this message translates to:
  /// **'{count}× Won'**
  String badgeWonCount(int count);

  /// No description provided for @badgeStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get badgeStatusOpen;

  /// No description provided for @badgeStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get badgeStatusLocked;

  /// No description provided for @badgeAvailableAllGames.
  ///
  /// In en, this message translates to:
  /// **'Open from start across all 4 games'**
  String get badgeAvailableAllGames;

  /// No description provided for @badgeUnlockedChallenge.
  ///
  /// In en, this message translates to:
  /// **'Unlocked tier — Master-level challenge'**
  String get badgeUnlockedChallenge;

  /// No description provided for @badgeSelectedPreview.
  ///
  /// In en, this message translates to:
  /// **'Selected Tier'**
  String get badgeSelectedPreview;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackAdminInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Inbox'**
  String get feedbackAdminInboxTitle;

  /// No description provided for @feedbackTabInbox.
  ///
  /// In en, this message translates to:
  /// **'Admin Inbox'**
  String get feedbackTabInbox;

  /// No description provided for @feedbackTabMine.
  ///
  /// In en, this message translates to:
  /// **'My Feedback'**
  String get feedbackTabMine;

  /// No description provided for @feedbackPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Feedback can only be seen by you and admins.'**
  String get feedbackPrivacyNote;

  /// No description provided for @feedbackSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to send feedback or view admin responses.'**
  String get feedbackSignInRequired;

  /// No description provided for @feedbackPendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending: {count}/{max}'**
  String feedbackPendingCount(int count, int max);

  /// No description provided for @feedbackPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Share a bug report, feature suggestion, or experience...'**
  String get feedbackPlaceholder;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackSubmit;

  /// No description provided for @feedbackLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Max {max} pending feedback items reached. Wait for admin review or delete an older one.'**
  String feedbackLimitReached(int max);

  /// No description provided for @feedbackStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get feedbackStatusPending;

  /// No description provided for @feedbackStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get feedbackStatusApproved;

  /// No description provided for @feedbackStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get feedbackStatusRejected;

  /// No description provided for @feedbackEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get feedbackEditAction;

  /// No description provided for @feedbackEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Feedback'**
  String get feedbackEditDialogTitle;

  /// No description provided for @feedbackEditWindow.
  ///
  /// In en, this message translates to:
  /// **'Editable ({time})'**
  String feedbackEditWindow(String time);

  /// No description provided for @feedbackEditLocked.
  ///
  /// In en, this message translates to:
  /// **'Edit locked (>6h)'**
  String get feedbackEditLocked;

  /// No description provided for @feedbackDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get feedbackDeleteAction;

  /// No description provided for @feedbackDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Feedback?'**
  String get feedbackDeleteConfirmTitle;

  /// No description provided for @feedbackDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This feedback item will be removed permanently.'**
  String get feedbackDeleteConfirmBody;

  /// No description provided for @feedbackAdminReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin Reply'**
  String get feedbackAdminReplyLabel;

  /// No description provided for @feedbackAutoDeleteNotice.
  ///
  /// In en, this message translates to:
  /// **'Deletes in {time}'**
  String feedbackAutoDeleteNotice(String time);

  /// No description provided for @feedbackReviewActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get feedbackReviewActionApprove;

  /// No description provided for @feedbackReviewActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get feedbackReviewActionReject;

  /// No description provided for @feedbackReviewDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Reply (1× Only)'**
  String get feedbackReviewDialogTitle;

  /// No description provided for @feedbackReviewReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Optional reply message for player...'**
  String get feedbackReviewReplyHint;

  /// No description provided for @feedbackEmptyMine.
  ///
  /// In en, this message translates to:
  /// **'No feedback sent yet.'**
  String get feedbackEmptyMine;

  /// No description provided for @feedbackEmptyInbox.
  ///
  /// In en, this message translates to:
  /// **'No player feedback yet.'**
  String get feedbackEmptyInbox;

  /// No description provided for @feedbackLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More (20)'**
  String get feedbackLoadMore;

  /// No description provided for @profileFeedbackButton.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get profileFeedbackButton;

  /// No description provided for @profileRoleAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get profileRoleAdminBadge;

  /// No description provided for @homeGuideTutorialButton.
  ///
  /// In en, this message translates to:
  /// **'Guide & Tutorial'**
  String get homeGuideTutorialButton;

  /// No description provided for @guideDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'{game} Visual Guide'**
  String guideDialogTitle(String game);

  /// No description provided for @guideDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe slides to explore visual rules & tips'**
  String get guideDialogSubtitle;

  /// No description provided for @guidePrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get guidePrev;

  /// No description provided for @guideNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guideNext;

  /// No description provided for @guideClose.
  ///
  /// In en, this message translates to:
  /// **'Close Guide'**
  String get guideClose;

  /// No description provided for @guideStartTutorial.
  ///
  /// In en, this message translates to:
  /// **'Start Tutorial'**
  String get guideStartTutorial;

  /// No description provided for @guideSudokuS1Badge.
  ///
  /// In en, this message translates to:
  /// **'1. CORE RULE'**
  String get guideSudokuS1Badge;

  /// No description provided for @guideSudokuS1Title.
  ///
  /// In en, this message translates to:
  /// **'Fill 1–9 Without Duplicates'**
  String get guideSudokuS1Title;

  /// No description provided for @guideSudokuS1Desc.
  ///
  /// In en, this message translates to:
  /// **'A 9×9 Sudoku board is divided into nine 3×3 boxes. Fill every empty cell with a digit from 1 to 9.'**
  String get guideSudokuS1Desc;

  /// No description provided for @guideSudokuS1Bullets.
  ///
  /// In en, this message translates to:
  /// **'Every horizontal ROW must contain 1–9 with no repeats.\nEvery vertical COLUMN must contain 1–9 with no repeats.\nEvery bold 3×3 BOX must contain 1–9 with no repeats.'**
  String get guideSudokuS1Bullets;

  /// No description provided for @guideSudokuS1VisualCaption.
  ///
  /// In en, this message translates to:
  /// **'Only 5 is missing in the center box!'**
  String get guideSudokuS1VisualCaption;

  /// No description provided for @guideSudokuS2Badge.
  ///
  /// In en, this message translates to:
  /// **'2. HOW TO PLAY'**
  String get guideSudokuS2Badge;

  /// No description provided for @guideSudokuS2Title.
  ///
  /// In en, this message translates to:
  /// **'Tap a Cell & Use Number Highlights'**
  String get guideSudokuS2Title;

  /// No description provided for @guideSudokuS2Desc.
  ///
  /// In en, this message translates to:
  /// **'Tapping any digit highlights all identical numbers across the board so you can quickly cross-check rows and columns.'**
  String get guideSudokuS2Desc;

  /// No description provided for @guideSudokuS2Bullets.
  ///
  /// In en, this message translates to:
  /// **'Select an empty cell, then tap 1–9 on the bottom keypad.\nOn Levels 1–4, correct placements lock automatically.\nTap the selected cell again to clear the highlight.'**
  String get guideSudokuS2Bullets;

  /// No description provided for @guideSudokuS3Badge.
  ///
  /// In en, this message translates to:
  /// **'3. SAFE STRATEGY'**
  String get guideSudokuS3Badge;

  /// No description provided for @guideSudokuS3Title.
  ///
  /// In en, this message translates to:
  /// **'Use Pencil Notes & Smart Notes'**
  String get guideSudokuS3Title;

  /// No description provided for @guideSudokuS3Desc.
  ///
  /// In en, this message translates to:
  /// **'Unsure between two numbers? Never guess blindly! Toggle Notes (✏️) to jot down mini candidate digits inside a cell.'**
  String get guideSudokuS3Desc;

  /// No description provided for @guideSudokuS3Bullets.
  ///
  /// In en, this message translates to:
  /// **'Entering Notes never costs a life (♥).\nSmart Notes automatically prunes impossible candidates.\nUse Erase to clear a cell or its pencil marks.'**
  String get guideSudokuS3Bullets;

  /// No description provided for @guideSudokuS3VisualBadge.
  ///
  /// In en, this message translates to:
  /// **'Notes ON (Safe)'**
  String get guideSudokuS3VisualBadge;

  /// No description provided for @guideSudokuS4Badge.
  ///
  /// In en, this message translates to:
  /// **'4. LIVES & ASSISTS'**
  String get guideSudokuS4Badge;

  /// No description provided for @guideSudokuS4Title.
  ///
  /// In en, this message translates to:
  /// **'3 Lives (♥), 3 Hints & ⚡ Auto-Finish'**
  String get guideSudokuS4Title;

  /// No description provided for @guideSudokuS4Desc.
  ///
  /// In en, this message translates to:
  /// **'You start with 3 lives and up to 3 Hints. When only a few empty cells remain, the lightning Auto-Finish button appears!'**
  String get guideSudokuS4Desc;

  /// No description provided for @guideSudokuS4Bullets.
  ///
  /// In en, this message translates to:
  /// **'Mistakes flash red and cost 1 heart (♥).\n⚡ Auto-Finish completes the board when ≤ 5–7 cells remain.\nIn Practice Mode, Undo and Rewind on Loss are freely available!'**
  String get guideSudokuS4Bullets;

  /// No description provided for @guideSudokuS4VisualBadge.
  ///
  /// In en, this message translates to:
  /// **'Auto-Finish (≤ 5 Left)'**
  String get guideSudokuS4VisualBadge;

  /// No description provided for @guideMineS1Badge.
  ///
  /// In en, this message translates to:
  /// **'1. NUMBER MEANING'**
  String get guideMineS1Badge;

  /// No description provided for @guideMineS1Title.
  ///
  /// In en, this message translates to:
  /// **'Numbers Show Adjacent Mines'**
  String get guideMineS1Title;

  /// No description provided for @guideMineS1Desc.
  ///
  /// In en, this message translates to:
  /// **'Every revealed number (1, 2, 3...) tells you exactly how many mines hide in the 8 surrounding tiles (including diagonals).'**
  String get guideMineS1Desc;

  /// No description provided for @guideMineS1Bullets.
  ///
  /// In en, this message translates to:
  /// **'Your first tap is ALWAYS 100% safe and opens a clear zone.\nA \"1\" means exactly 1 touching hidden tile contains a mine.\nBlank tiles (0) flood-fill open all safe neighbors automatically.'**
  String get guideMineS1Bullets;

  /// No description provided for @guideMineS1VisualCaption.
  ///
  /// In en, this message translates to:
  /// **'The center \"1\" touches exactly 1 mine in the top-right corner!'**
  String get guideMineS1VisualCaption;

  /// No description provided for @guideMineS2Badge.
  ///
  /// In en, this message translates to:
  /// **'2. DIG VS FLAG'**
  String get guideMineS2Badge;

  /// No description provided for @guideMineS2Title.
  ///
  /// In en, this message translates to:
  /// **'Plant Flags (🚩) on Suspected Mines'**
  String get guideMineS2Title;

  /// No description provided for @guideMineS2Desc.
  ///
  /// In en, this message translates to:
  /// **'Never dig a tile you suspect is a mine! Mark it with a Flag (🚩) so it cannot be accidentally tapped.'**
  String get guideMineS2Desc;

  /// No description provided for @guideMineS2Bullets.
  ///
  /// In en, this message translates to:
  /// **'Long-press any hidden tile to place or remove a Flag.\nOr toggle the 1-Tap Swap button between Dig ⛏️ and Flag 🚩.\nYou win as soon as all safe non-mine tiles are revealed!'**
  String get guideMineS2Bullets;

  /// No description provided for @guideMineS2VisualCaption.
  ///
  /// In en, this message translates to:
  /// **'Lock suspected mine tiles with a Flag (🚩)!'**
  String get guideMineS2VisualCaption;

  /// No description provided for @guideMineS3Badge.
  ///
  /// In en, this message translates to:
  /// **'3. PRO TECHNIQUE'**
  String get guideMineS3Badge;

  /// No description provided for @guideMineS3Title.
  ///
  /// In en, this message translates to:
  /// **'Chording: Fast-Open Safe Neighbors'**
  String get guideMineS3Title;

  /// No description provided for @guideMineS3Desc.
  ///
  /// In en, this message translates to:
  /// **'When an open number already touches the matching number of Flags (🚩), tap the number itself to open all remaining neighbors instantly!'**
  String get guideMineS3Desc;

  /// No description provided for @guideMineS3Bullets.
  ///
  /// In en, this message translates to:
  /// **'Example: A \"1\" already touches 1 Flag → tap that \"1\"!\nAll other hidden tiles touching that \"1\" open at once.\nMake sure your flag placement is accurate before chording!'**
  String get guideMineS3Bullets;

  /// No description provided for @guideMineS4Badge.
  ///
  /// In en, this message translates to:
  /// **'4. BEGINNER SHIELD'**
  String get guideMineS4Badge;

  /// No description provided for @guideMineS4Title.
  ///
  /// In en, this message translates to:
  /// **'Defuse Shield (🛡️) Saves You'**
  String get guideMineS4Title;

  /// No description provided for @guideMineS4Desc.
  ///
  /// In en, this message translates to:
  /// **'On Beginner Levels 1–2, you start with a Defuse Shield (🛡️) that automatically disarms a mine if you make a mistake!'**
  String get guideMineS4Desc;

  /// No description provided for @guideMineS4Bullets.
  ///
  /// In en, this message translates to:
  /// **'Defused mines appear safely disarmed on the board.\nPost-game review highlights all mines and any misplaced flags.\nTap View Board after a match to inspect the full mine layout.'**
  String get guideMineS4Bullets;

  /// No description provided for @guideMineS4VisualCaption.
  ///
  /// In en, this message translates to:
  /// **'Lv. 1–2 Shield automatically defuses a mine!'**
  String get guideMineS4VisualCaption;

  /// No description provided for @guideChessS1Badge.
  ///
  /// In en, this message translates to:
  /// **'1. PIECE MOVEMENTS'**
  String get guideChessS1Badge;

  /// No description provided for @guideChessS1Title.
  ///
  /// In en, this message translates to:
  /// **'How All 6 Chess Pieces Move'**
  String get guideChessS1Title;

  /// No description provided for @guideChessS1Desc.
  ///
  /// In en, this message translates to:
  /// **'Tap any of your pieces to see legal target dots on the board. Only the Knight (♘) can jump over other pieces!'**
  String get guideChessS1Desc;

  /// No description provided for @guideChessS1Bullets.
  ///
  /// In en, this message translates to:
  /// **'♔ King: 1 step any way • ♕ Queen: any distance straight or diagonal.\n♖ Rook: straight lines • ♗ Bishop: diagonals only.\n♘ Knight: L-shape jump (2+1) • ♙ Pawn: moves forward, captures diagonally.'**
  String get guideChessS1Bullets;

  /// No description provided for @guideChessS2Badge.
  ///
  /// In en, this message translates to:
  /// **'2. CHECKMATE VS STALEMATE'**
  String get guideChessS2Badge;

  /// No description provided for @guideChessS2Title.
  ///
  /// In en, this message translates to:
  /// **'Watch Out: Stalemate Is a Draw!'**
  String get guideChessS2Title;

  /// No description provided for @guideChessS2Desc.
  ///
  /// In en, this message translates to:
  /// **'Trapping the enemy King without putting it in Check leaves them with zero legal moves—resulting in a STALEMATE (Draw), not a win!'**
  String get guideChessS2Desc;

  /// No description provided for @guideChessS2Bullets.
  ///
  /// In en, this message translates to:
  /// **'Check: King is under attack and must escape immediately.\nCheckmate: King is in Check with no legal escape → YOU WIN!\nDraw: Stalemate, 3-fold repetition, 50-move rule, or insufficient material.'**
  String get guideChessS2Bullets;

  /// No description provided for @guideChessS2Checkmate.
  ///
  /// In en, this message translates to:
  /// **'CHECKMATE (Win)'**
  String get guideChessS2Checkmate;

  /// No description provided for @guideChessS2Stalemate.
  ///
  /// In en, this message translates to:
  /// **'STALEMATE (Draw!)'**
  String get guideChessS2Stalemate;

  /// No description provided for @guideChessS3Badge.
  ///
  /// In en, this message translates to:
  /// **'3. SPECIAL RULE #1'**
  String get guideChessS3Badge;

  /// No description provided for @guideChessS3Title.
  ///
  /// In en, this message translates to:
  /// **'Castling (♔⇄♖): King + Rook Double Move'**
  String get guideChessS3Title;

  /// No description provided for @guideChessS3Desc.
  ///
  /// In en, this message translates to:
  /// **'The only move where two pieces move at once! Move your King 2 squares toward your Rook, and the Rook jumps over to the other side.'**
  String get guideChessS3Desc;

  /// No description provided for @guideChessS3Bullets.
  ///
  /// In en, this message translates to:
  /// **'Rule 1: Neither the King nor that Rook has moved yet.\nRule 2: Every square between King and Rook must be empty.\nRule 3: The King cannot be in Check or pass through an attacked square.'**
  String get guideChessS3Bullets;

  /// No description provided for @guideChessS3VisualCaption.
  ///
  /// In en, this message translates to:
  /// **'Kingside Castling: King e1 → g1, Rook h1 → f1 jumps over!'**
  String get guideChessS3VisualCaption;

  /// No description provided for @guideChessS4Badge.
  ///
  /// In en, this message translates to:
  /// **'4. SPECIAL RULE #2'**
  String get guideChessS4Badge;

  /// No description provided for @guideChessS4Title.
  ///
  /// In en, this message translates to:
  /// **'En Passant & Pawn Promotion (♙ → ♕)'**
  String get guideChessS4Title;

  /// No description provided for @guideChessS4Desc.
  ///
  /// In en, this message translates to:
  /// **'Two crucial pawn rules that often surprise players: capturing \"in passing\" (En Passant) and promoting at the 8th rank!'**
  String get guideChessS4Desc;

  /// No description provided for @guideChessS4Bullets.
  ///
  /// In en, this message translates to:
  /// **'En Passant: When an enemy pawn advances 2 squares beside yours, you can capture it diagonally on the very next turn as if it moved 1 square.\nPromotion: Reaching the last rank transforms your pawn into a Queen (♕), Rook, Bishop, or Knight!'**
  String get guideChessS4Bullets;

  /// No description provided for @guideChessS4VisualPromo.
  ///
  /// In en, this message translates to:
  /// **'Promotion → Queen'**
  String get guideChessS4VisualPromo;

  /// No description provided for @guideChessS5Badge.
  ///
  /// In en, this message translates to:
  /// **'5. ZETZY CHESS FEATURES'**
  String get guideChessS5Badge;

  /// No description provided for @guideChessS5Title.
  ///
  /// In en, this message translates to:
  /// **'Touch Confirmation, Board Flip & Review'**
  String get guideChessS5Title;

  /// No description provided for @guideChessS5Desc.
  ///
  /// In en, this message translates to:
  /// **'Zetzy includes thoughtful touch safeguards and post-match analysis tools.'**
  String get guideChessS5Desc;

  /// No description provided for @guideChessS5Bullets.
  ///
  /// In en, this message translates to:
  /// **'Touch Move Confirmation previews your move before locking it in.\n4 Modes: Vs AI (Lv. 1–7), Pass & Play (2P), Friend Room, & Rated Matchmaking.\nUse the post-game move scrubber (⏮ ◀ ▶ ⏭) to replay every turn!'**
  String get guideChessS5Bullets;

  /// No description provided for @guideSnakeS1Badge.
  ///
  /// In en, this message translates to:
  /// **'1. CONTROLS & MOVEMENT'**
  String get guideSnakeS1Badge;

  /// No description provided for @guideSnakeS1Title.
  ///
  /// In en, this message translates to:
  /// **'Turn 90° & Never Bite Your Own Tail'**
  String get guideSnakeS1Title;

  /// No description provided for @guideSnakeS1Desc.
  ///
  /// In en, this message translates to:
  /// **'Your snake advances smoothly across the grid. Steer toward apples while avoiding walls and your own growing body.'**
  String get guideSnakeS1Desc;

  /// No description provided for @guideSnakeS1Bullets.
  ///
  /// In en, this message translates to:
  /// **'Choose Swipe, Virtual D-Pad, or Split-Screen Tap in Profile settings.\nYou can turn 90° perpendicular to your heading, never 180° backward.\nArrow keys and WASD are also supported on keyboard devices.'**
  String get guideSnakeS1Bullets;

  /// No description provided for @guideSnakeS2Badge.
  ///
  /// In en, this message translates to:
  /// **'2. APPLES & POWER-UPS'**
  String get guideSnakeS2Badge;

  /// No description provided for @guideSnakeS2Title.
  ///
  /// In en, this message translates to:
  /// **'Red Apples, Golden Bonus, Scissors & Poison'**
  String get guideSnakeS2Title;

  /// No description provided for @guideSnakeS2Desc.
  ///
  /// In en, this message translates to:
  /// **'Learn what each arena item does to maximize your score and manage tail length!'**
  String get guideSnakeS2Desc;

  /// No description provided for @guideSnakeS2Bullets.
  ///
  /// In en, this message translates to:
  /// **'🍎 Red Apple (+10 pts): core food needed to reach the level target.\n🌟 Golden Apple (+30 pts): timed bonus item for massive points!\n✂️ Scissors: trims your tail shorter to free up space on the board.\n☠️ Poison: avoid! Stepping on poison triggers a hazard penalty.'**
  String get guideSnakeS2Bullets;

  /// No description provided for @guideSnakeS2Trim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get guideSnakeS2Trim;

  /// No description provided for @guideSnakeS2Hazard.
  ///
  /// In en, this message translates to:
  /// **'Hazard'**
  String get guideSnakeS2Hazard;

  /// No description provided for @guideSnakeS3Badge.
  ///
  /// In en, this message translates to:
  /// **'3. WALLS & OBSTACLES'**
  String get guideSnakeS3Badge;

  /// No description provided for @guideSnakeS3Title.
  ///
  /// In en, this message translates to:
  /// **'Brick Walls & Dynamic Obstacles'**
  String get guideSnakeS3Title;

  /// No description provided for @guideSnakeS3Desc.
  ///
  /// In en, this message translates to:
  /// **'Higher difficulty tiers introduce brick wall obstacles inside the arena that require sharp turns.'**
  String get guideSnakeS3Desc;

  /// No description provided for @guideSnakeS3Bullets.
  ///
  /// In en, this message translates to:
  /// **'2-Step Input Queue lets you buffer quick zig-zag turns cleanly.\nEnable Assist Overlay in settings for helpful hazard indicators.'**
  String get guideSnakeS3Bullets;

  /// No description provided for @guideSnakeS3VisualCaption.
  ///
  /// In en, this message translates to:
  /// **'Dodge brick walls inside the arena!'**
  String get guideSnakeS3VisualCaption;

  /// No description provided for @guideSnakeS4Badge.
  ///
  /// In en, this message translates to:
  /// **'4. STARVATION BAR'**
  String get guideSnakeS4Badge;

  /// No description provided for @guideSnakeS4Title.
  ///
  /// In en, this message translates to:
  /// **'Watch the Starvation Bar on High Tiers!'**
  String get guideSnakeS4Title;

  /// No description provided for @guideSnakeS4Desc.
  ///
  /// In en, this message translates to:
  /// **'On Levels 6–7, a Starvation Bar drains over time. Eat apples promptly to refill your stamina before it runs out!'**
  String get guideSnakeS4Desc;

  /// No description provided for @guideSnakeS4Bullets.
  ///
  /// In en, this message translates to:
  /// **'Plan the shortest path toward the next Red Apple.\nIn Practice Mode, use Rewind 1–3 steps to recover from any crash!'**
  String get guideSnakeS4Bullets;

  /// No description provided for @guideSnakeS4VisualCaption.
  ///
  /// In en, this message translates to:
  /// **'Starvation Timer (Lv. 6–7)'**
  String get guideSnakeS4VisualCaption;

  /// No description provided for @tutorialExitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exit Tutorial'**
  String get tutorialExitTooltip;

  /// No description provided for @tutorialAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial • {game}'**
  String tutorialAppBarTitle(String game);

  /// No description provided for @tutorialPausedBadge.
  ///
  /// In en, this message translates to:
  /// **'⏸️ PAUSED • COACH GUIDE'**
  String get tutorialPausedBadge;

  /// No description provided for @tutorialTryItBadge.
  ///
  /// In en, this message translates to:
  /// **'👆 YOUR TURN • TRY IT'**
  String get tutorialTryItBadge;

  /// No description provided for @tutorialActionProgress.
  ///
  /// In en, this message translates to:
  /// **'Action {current}/{total}'**
  String tutorialActionProgress(int current, int total);

  /// No description provided for @tutorialGotItBtn.
  ///
  /// In en, this message translates to:
  /// **'Got It, Try Now!'**
  String get tutorialGotItBtn;

  /// No description provided for @tutorialReadTipFirst.
  ///
  /// In en, this message translates to:
  /// **'Read the coach tip first, then press \"Got It, Try Now!\"'**
  String get tutorialReadTipFirst;

  /// No description provided for @tutorialTapBlinking.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking button or tile!'**
  String get tutorialTapBlinking;

  /// No description provided for @tutorialCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Complete! 🎉'**
  String get tutorialCompleteTitle;

  /// No description provided for @tutorialCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You practiced the core rules of {game}. Ready for a real match?'**
  String tutorialCompleteBody(String game);

  /// No description provided for @tutorialDoneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tutorialDoneBtn;

  /// No description provided for @tutorialPlayNowBtn.
  ///
  /// In en, this message translates to:
  /// **'Play Now!'**
  String get tutorialPlayNowBtn;

  /// No description provided for @tutorialHudLabel.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorialHudLabel;

  /// No description provided for @tutSudokuS1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1/3: Select a Cell, Then Press a Digit'**
  String get tutSudokuS1Title;

  /// No description provided for @tutSudokuS1Exp.
  ///
  /// In en, this message translates to:
  /// **'The highlighted center 3×3 box already holds 1, 2, 3, 4, 6, 7, 8, 9 — only 5 is missing! To fill in Sudoku: tap the cell first, then press a digit on the number pad below.'**
  String get tutSudokuS1Exp;

  /// No description provided for @tutSudokuS1A1.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking empty cell in the middle of the board.'**
  String get tutSudokuS1A1;

  /// No description provided for @tutSudokuS1A2.
  ///
  /// In en, this message translates to:
  /// **'Great! Now press 5 on the number pad below.'**
  String get tutSudokuS1A2;

  /// No description provided for @tutSudokuS2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2/3: Pencil Candidates with Notes (✏️)'**
  String get tutSudokuS2Title;

  /// No description provided for @tutSudokuS2Exp.
  ///
  /// In en, this message translates to:
  /// **'The highlighted top row is missing 3 and 4. Not sure which goes where? Don’t guess! Turn on Notes to jot small candidates — notes never cost a heart ♥.'**
  String get tutSudokuS2Exp;

  /// No description provided for @tutSudokuS2A1.
  ///
  /// In en, this message translates to:
  /// **'Press the blinking Notes button.'**
  String get tutSudokuS2A1;

  /// No description provided for @tutSudokuS2A2.
  ///
  /// In en, this message translates to:
  /// **'Tap the first empty cell in the top row.'**
  String get tutSudokuS2A2;

  /// No description provided for @tutSudokuS2A3.
  ///
  /// In en, this message translates to:
  /// **'Press 3 to note the first candidate.'**
  String get tutSudokuS2A3;

  /// No description provided for @tutSudokuS2A4.
  ///
  /// In en, this message translates to:
  /// **'Press 4 to note the second candidate.'**
  String get tutSudokuS2A4;

  /// No description provided for @tutSudokuS3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3/3: Eliminate & Finish!'**
  String get tutSudokuS3Title;

  /// No description provided for @tutSudokuS3Exp.
  ///
  /// In en, this message translates to:
  /// **'Check that cell\'s column (highlighted): a 4 already sits at the bottom (yellow). Columns can\'t repeat, so the 3·4 cell must be 3 and its neighbor must be 4! Turn Notes off first so digits are placed for real.'**
  String get tutSudokuS3Exp;

  /// No description provided for @tutSudokuS3A1.
  ///
  /// In en, this message translates to:
  /// **'Turn Notes off first.'**
  String get tutSudokuS3A1;

  /// No description provided for @tutSudokuS3A2.
  ///
  /// In en, this message translates to:
  /// **'Tap the cell holding the 3·4 notes.'**
  String get tutSudokuS3A2;

  /// No description provided for @tutSudokuS3A3.
  ///
  /// In en, this message translates to:
  /// **'Press 3.'**
  String get tutSudokuS3A3;

  /// No description provided for @tutSudokuS3A4.
  ///
  /// In en, this message translates to:
  /// **'One empty cell left beside it. Tap it.'**
  String get tutSudokuS3A4;

  /// No description provided for @tutSudokuS3A5.
  ///
  /// In en, this message translates to:
  /// **'Press 4 to complete the board!'**
  String get tutSudokuS3A5;

  /// No description provided for @tutSudokuWrongCellFirst.
  ///
  /// In en, this message translates to:
  /// **'Select the cell first, then press a digit.'**
  String get tutSudokuWrongCellFirst;

  /// No description provided for @tutSudokuWrongPressDigit.
  ///
  /// In en, this message translates to:
  /// **'The cell is selected — now press the blinking digit below.'**
  String get tutSudokuWrongPressDigit;

  /// No description provided for @tutMineS1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1/5: The First Dig Is Always Safe'**
  String get tutMineS1Title;

  /// No description provided for @tutMineS1Exp.
  ///
  /// In en, this message translates to:
  /// **'Dig mode (⛏️) is active. In Zetzy your first dig is always safe and opens an empty area with clue numbers. A number = how many mines touch that tile (all 8 neighbors).'**
  String get tutMineS1Exp;

  /// No description provided for @tutMineS1A1.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking center tile to dig.'**
  String get tutMineS1A1;

  /// No description provided for @tutMineS2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2/5: Plant a Flag (🚩)'**
  String get tutMineS2Title;

  /// No description provided for @tutMineS2Exp.
  ///
  /// In en, this message translates to:
  /// **'Look at the highlighted 1 in the top row. Only ONE of its neighbors is still hidden — so that tile MUST be a mine. Switch to Flag mode, then mark it.'**
  String get tutMineS2Exp;

  /// No description provided for @tutMineS2A1.
  ///
  /// In en, this message translates to:
  /// **'Press the blinking Flag button.'**
  String get tutMineS2A1;

  /// No description provided for @tutMineS2A2.
  ///
  /// In en, this message translates to:
  /// **'Tap the hidden tile next to the 1 to plant a Flag.'**
  String get tutMineS2A2;

  /// No description provided for @tutMineS3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3/5: Unsure? Mark It with (?)'**
  String get tutMineS3Title;

  /// No description provided for @tutMineS3Exp.
  ///
  /// In en, this message translates to:
  /// **'The highlighted 2 needs 2 mines. One is flagged, so the other hides in one of the 2 corner tiles. Not sure which? Use the (?) tool as a reminder — (?) tiles can’t be dug by accident.'**
  String get tutMineS3Exp;

  /// No description provided for @tutMineS3A1.
  ///
  /// In en, this message translates to:
  /// **'Press the blinking (?) button.'**
  String get tutMineS3A1;

  /// No description provided for @tutMineS3A2.
  ///
  /// In en, this message translates to:
  /// **'Tap the top-left corner tile to mark it (?).'**
  String get tutMineS3A2;

  /// No description provided for @tutMineS4Title.
  ///
  /// In en, this message translates to:
  /// **'Step 4/5: Find the Second Mine'**
  String get tutMineS4Title;

  /// No description provided for @tutMineS4Exp.
  ///
  /// In en, this message translates to:
  /// **'Now check the highlighted 1 in the left column. Only one neighbor is hidden — the tile above it. That’s the second mine! Switch back to Flag.'**
  String get tutMineS4Exp;

  /// No description provided for @tutMineS4A1.
  ///
  /// In en, this message translates to:
  /// **'Press the Flag button.'**
  String get tutMineS4A1;

  /// No description provided for @tutMineS4A2.
  ///
  /// In en, this message translates to:
  /// **'Tap the tile above that 1 to plant a Flag.'**
  String get tutMineS4A2;

  /// No description provided for @tutMineS5Title.
  ///
  /// In en, this message translates to:
  /// **'Step 5/5: Dig the Last Safe Tile!'**
  String get tutMineS5Title;

  /// No description provided for @tutMineS5Exp.
  ///
  /// In en, this message translates to:
  /// **'The highlighted 2 now touches 2 flags — its mine count is complete. So the (?) corner is 100% SAFE. Switch back to Dig and open it to win!'**
  String get tutMineS5Exp;

  /// No description provided for @tutMineS5A1.
  ///
  /// In en, this message translates to:
  /// **'Press the Dig button.'**
  String get tutMineS5A1;

  /// No description provided for @tutMineS5A2.
  ///
  /// In en, this message translates to:
  /// **'Tap the (?) tile in the top-left corner to dig it.'**
  String get tutMineS5A2;

  /// No description provided for @tutMineWrongSwitchTool.
  ///
  /// In en, this message translates to:
  /// **'Switch tools first using the blinking button below.'**
  String get tutMineWrongSwitchTool;

  /// No description provided for @tutChessS1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1/4: The Knight (♘) Jumps in an L'**
  String get tutChessS1Title;

  /// No description provided for @tutChessS1Exp.
  ///
  /// In en, this message translates to:
  /// **'In chess, tap your piece first to see where it can go. Dots = empty squares it can reach, RED = an enemy piece it can capture. The Knight moves in an L shape and can jump over pieces.'**
  String get tutChessS1Exp;

  /// No description provided for @tutChessS1A1.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking white Knight.'**
  String get tutChessS1A1;

  /// No description provided for @tutChessS1A2.
  ///
  /// In en, this message translates to:
  /// **'See every highlighted Knight move. The RED square holds the enemy Queen — tap it to capture!'**
  String get tutChessS1A2;

  /// No description provided for @tutChessS2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2/4: Castling (♔⇄♖)'**
  String get tutChessS2Title;

  /// No description provided for @tutChessS2Exp.
  ///
  /// In en, this message translates to:
  /// **'Castling = the King slides 2 squares toward a Rook, and the Rook hops to its other side. Rules: neither piece has moved, the squares between are empty, and the King is not in or passing through check.'**
  String get tutChessS2Exp;

  /// No description provided for @tutChessS2A1.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking white King first.'**
  String get tutChessS2A1;

  /// No description provided for @tutChessS2A2.
  ///
  /// In en, this message translates to:
  /// **'The ⇄ square is the castling move. Tap it to castle!'**
  String get tutChessS2A2;

  /// No description provided for @tutChessS3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3/4: En Passant (♙↗)'**
  String get tutChessS3Title;

  /// No description provided for @tutChessS3Exp.
  ///
  /// In en, this message translates to:
  /// **'Black’s pawn just advanced 2 squares (d7 → d5, yellow) and landed right beside your pawn. On this turn only, your pawn may capture it diagonally as if it had moved 1 square — that’s En Passant.'**
  String get tutChessS3Exp;

  /// No description provided for @tutChessS3A1.
  ///
  /// In en, this message translates to:
  /// **'Tap the white pawn on e5.'**
  String get tutChessS3A1;

  /// No description provided for @tutChessS3A2.
  ///
  /// In en, this message translates to:
  /// **'Tap the RED square behind the black pawn for En Passant!'**
  String get tutChessS3A2;

  /// No description provided for @tutChessS4Title.
  ///
  /// In en, this message translates to:
  /// **'Step 4/4: Pawn Promotion → Checkmate!'**
  String get tutChessS4Title;

  /// No description provided for @tutChessS4Exp.
  ///
  /// In en, this message translates to:
  /// **'A pawn reaching the last rank MUST promote to a Queen, Rook, Bishop, or Knight. Black’s King is boxed in by its own pawns — promoting to a Queen on a8 is Checkmate!'**
  String get tutChessS4Exp;

  /// No description provided for @tutChessS4A1.
  ///
  /// In en, this message translates to:
  /// **'Tap the white pawn on a7.'**
  String get tutChessS4A1;

  /// No description provided for @tutChessS4A2.
  ///
  /// In en, this message translates to:
  /// **'Tap a8 on the last rank.'**
  String get tutChessS4A2;

  /// No description provided for @tutChessS4A3.
  ///
  /// In en, this message translates to:
  /// **'Choose the Queen (♕) — the strongest piece!'**
  String get tutChessS4A3;

  /// No description provided for @tutChessWrongOtherLegal.
  ///
  /// In en, this message translates to:
  /// **'That’s a legal move, but pick the blinking square for this lesson.'**
  String get tutChessWrongOtherLegal;

  /// No description provided for @tutChessWrongTapPieceFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking piece first to reveal its moves.'**
  String get tutChessWrongTapPieceFirst;

  /// No description provided for @tutChessPromoLabel.
  ///
  /// In en, this message translates to:
  /// **'Promote pawn to:'**
  String get tutChessPromoLabel;

  /// No description provided for @tutChessCheckmateStatus.
  ///
  /// In en, this message translates to:
  /// **'♛ CHECKMATE! White wins.'**
  String get tutChessCheckmateStatus;

  /// No description provided for @tutChessWhiteToMove.
  ///
  /// In en, this message translates to:
  /// **'White to move'**
  String get tutChessWhiteToMove;

  /// No description provided for @tutSnakeS1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1/3: Turn 90° Toward the Apple 🍎'**
  String get tutSnakeS1Title;

  /// No description provided for @tutSnakeS1Exp.
  ///
  /// In en, this message translates to:
  /// **'Your snake keeps moving right — straight toward POISON ☠️! A red apple (+10) sits above its head. Steer upward. Snakes turn 90° only, never a 180° U-turn.'**
  String get tutSnakeS1Exp;

  /// No description provided for @tutSnakeS2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2/3: Grab the Scissors ✂️ to Trim'**
  String get tutSnakeS2Title;

  /// No description provided for @tutSnakeS2Exp.
  ///
  /// In en, this message translates to:
  /// **'Yum! +10 and the snake grew longer. The arena edge is ahead (up). The Scissors ✂️ on the right trim your tail for more room. Avoid the brick wall 🧱!'**
  String get tutSnakeS2Exp;

  /// No description provided for @tutSnakeS3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3/3: Golden Apple 🌟 (+30)'**
  String get tutSnakeS3Title;

  /// No description provided for @tutSnakeS3Exp.
  ///
  /// In en, this message translates to:
  /// **'Tail trimmed! The arena edge is ahead (right). The Golden Apple (+30) is below on a path clear of poison ☠️. Turn down to grab it!'**
  String get tutSnakeS3Exp;

  /// No description provided for @tutSnakePromptDpad.
  ///
  /// In en, this message translates to:
  /// **'Press the blinking {dir} button on the D-Pad.'**
  String tutSnakePromptDpad(String dir);

  /// No description provided for @tutSnakePromptSplitLeft.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking LEFT side (turn counter-clockwise).'**
  String get tutSnakePromptSplitLeft;

  /// No description provided for @tutSnakePromptSplitRight.
  ///
  /// In en, this message translates to:
  /// **'Tap the blinking RIGHT side (turn clockwise).'**
  String get tutSnakePromptSplitRight;

  /// No description provided for @tutSnakePromptSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe the arena {dir} (or tap the blinking arrow).'**
  String tutSnakePromptSwipe(String dir);

  /// No description provided for @tutSnakeDirUp.
  ///
  /// In en, this message translates to:
  /// **'UP'**
  String get tutSnakeDirUp;

  /// No description provided for @tutSnakeDirDown.
  ///
  /// In en, this message translates to:
  /// **'DOWN'**
  String get tutSnakeDirDown;

  /// No description provided for @tutSnakeDirLeft.
  ///
  /// In en, this message translates to:
  /// **'LEFT'**
  String get tutSnakeDirLeft;

  /// No description provided for @tutSnakeDirRight.
  ///
  /// In en, this message translates to:
  /// **'RIGHT'**
  String get tutSnakeDirRight;

  /// No description provided for @tutSnakeWrongUTurn.
  ///
  /// In en, this message translates to:
  /// **'Snakes can’t make a 180° U-turn — they’d bite their own body!'**
  String get tutSnakeWrongUTurn;

  /// No description provided for @tutSnakeCtrlLeftSide.
  ///
  /// In en, this message translates to:
  /// **'Left Side'**
  String get tutSnakeCtrlLeftSide;

  /// No description provided for @tutSnakeCtrlRightSide.
  ///
  /// In en, this message translates to:
  /// **'Right Side'**
  String get tutSnakeCtrlRightSide;

  /// No description provided for @tutSnakeSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe controls (from Profile): swipe the arena toward your target.'**
  String get tutSnakeSwipeHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
