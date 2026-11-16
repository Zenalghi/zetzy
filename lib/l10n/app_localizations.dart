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
  /// **'Smart shuffle across all tracks (Track 5 appears more often).'**
  String get bgmAutoDesc;

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
