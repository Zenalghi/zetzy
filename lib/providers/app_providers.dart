import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/avatar_picker_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/core/services/wakelock_service.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/platform_detector.dart';
import 'package:zetzy/data/local/local_storage_service.dart';
import 'package:zetzy/data/local/settings_repository.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/stats_summary.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/data/remote/supabase_service.dart';

// ── Core Service Providers (overridden in main.dart) ───────────────────────

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => throw UnimplementedError('localStorageProvider must be overridden'),
);

final settingsRepoProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('settingsRepoProvider must be overridden'),
);

final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
final avatarPickerServiceProvider = Provider<AvatarPickerService>(
  (ref) => AvatarPickerService(),
);
final hapticServiceProvider = Provider<HapticService>((ref) => HapticService());
final wakelockServiceProvider = Provider<WakelockService>(
  (ref) => WakelockService(),
);

/// App version string read from compiled `pubspec.yaml` metadata (clean semantic version without build number).
final appVersionProvider = FutureProvider<String?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isEmpty) return null;
    return info.version;
  } catch (_) {
    return null;
  }
});

// ── Settings Notifier ──────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repo = ref.watch(settingsRepoProvider);
    final loaded = repo.load();
    _syncServices(loaded, fromUserAction: false);
    return loaded;
  }

  void _syncServices(AppSettings s, {bool fromUserAction = false}) {
    ref.read(audioServiceProvider).updatePreferences(
      sfxEnabled: s.sfxEnabled,
      bgmMode: s.bgmMode,
      manualBgmTrack: s.bgmTrack,
      favoriteBgmTrack: s.favoriteBgmTrack,
      uiClickTheme: s.uiClickTheme,
      fromUserAction: fromUserAction,
    );
    ref.read(hapticServiceProvider)
      ..enabled = s.hapticsEnabled
      ..intensity = s.hapticIntensity;
    ref.read(wakelockServiceProvider).updateSetting(s.wakelockEnabled);
  }

  Future<void> _commit(AppSettings next) async {
    state = next;
    _syncServices(next, fromUserAction: true);
    await ref.read(settingsRepoProvider).save(next);
    unawaited(_syncSettingsToCloud(next));
  }

  /// Applies cloud-saved profile settings when signing in on a device without
  /// triggering an infinite re-upload loop.
  Future<void> applyCloudSettings(Map<String, dynamic>? rawSettings) async {
    if (rawSettings == null || rawSettings.isEmpty) return;
    final merged = state.mergeCloudJson(rawSettings);
    state = merged;
    _syncServices(merged, fromUserAction: false);
    await ref.read(settingsRepoProvider).save(merged);
  }

  Future<void> _syncSettingsToCloud(AppSettings next) async {
    final supa = ref.read(supabaseServiceProvider);
    final auth = ref.read(authProvider);
    if (!supa.isAvailable || auth.isGuest) return;
    try {
      final updatedData = await supa.updateAccountData(
        settingsJson: next.toCloudJson(),
        baseAccountData: auth.accountData,
      );
      if (updatedData != null && ref.mounted) {
        ref.read(authProvider.notifier).setAccountDataSnapshot(updatedData);
      }
    } catch (e) {
      debugPrint('Settings cloud sync deferred: $e');
    }
  }

  Future<void> setTheme(ZetzyThemeMode mode) async {
    final sameTheme = state.themeMode == mode;
    final nextClickTheme = sameTheme
        ? (state.uiClickTheme % 4) + 1
        : state.uiClickTheme;

    if (mode == ZetzyThemeMode.abyssalCyan) {
      final nextAlter = sameTheme ? !state.abyssalCyanAlterEgo : false;
      await _commit(
        state.copyWith(
          themeMode: ZetzyThemeMode.abyssalCyan,
          abyssalCyanAlterEgo: nextAlter,
          uiClickTheme: nextClickTheme,
        ),
      );
    } else {
      await _commit(
        state.copyWith(
          themeMode: mode,
          abyssalCyanAlterEgo: false,
          uiClickTheme: nextClickTheme,
        ),
      );
    }

    if (sameTheme) {
      unawaited(ref.read(audioServiceProvider).playSfx(ZetzySfx.uiClick));
    }
  }

  Future<void> setLocale(String code) =>
      _commit(state.copyWith(localeCode: code));

  Future<void> setSfx(bool enabled) =>
      _commit(state.copyWith(sfxEnabled: enabled));

  Future<void> setBgm(bool enabled) =>
      setBgmMode(enabled ? BgmMode.auto : BgmMode.off);

  Future<void> setBgmMode(BgmMode mode) =>
      _commit(state.copyWith(bgmMode: mode));

  Future<void> setBgmTrack(String track) => _commit(
    state.copyWith(
      bgmMode: BgmMode.manual,
      bgmTrack: track,
    ),
  );

  Future<void> setFavoriteBgmTrack(String track) =>
      _commit(state.copyWith(favoriteBgmTrack: track));

  Future<void> skipNextBgm() =>
      ref.read(audioServiceProvider).skipToNextAutoBgm();

  Future<void> setHaptics(bool enabled) async {
    await _commit(state.copyWith(hapticsEnabled: enabled));
    if (enabled) {
      ref.read(hapticServiceProvider).medium();
    }
  }

  Future<void> setHapticIntensity(HapticIntensity intensity) async {
    await _commit(state.copyWith(hapticIntensity: intensity));
    if (state.hapticsEnabled) {
      ref.read(hapticServiceProvider).medium();
    }
  }

  Future<void> setWakelock(bool enabled) =>
      _commit(state.copyWith(wakelockEnabled: enabled));

  Future<void> setSnakeControl(SnakeControlMode mode) =>
      _commit(state.copyWith(snakeControlMode: mode));

  Future<void> setSnakeShowGridLines(bool enabled) =>
      _commit(state.copyWith(snakeShowGridLines: enabled));

  Future<void> setSnakeAssistOverlay(bool enabled) =>
      _commit(state.copyWith(snakeAssistOverlay: enabled));

  Future<void> setChessPieceSet(ChessPieceSet pieceSet) =>
      _commit(state.copyWith(chessPieceSet: pieceSet));

  Future<void> setChessAutoQueen(bool autoQueen) =>
      _commit(state.copyWith(chessAutoQueen: autoQueen));

  Future<void> setChessShowLegalMoves(bool enabled) =>
      _commit(state.copyWith(chessShowLegalMoves: enabled));

  Future<void> setChessShowCoordinates(bool enabled) =>
      _commit(state.copyWith(chessShowCoordinates: enabled));

  Future<void> setChessMoveConfirmMode(ChessMoveConfirmMode mode) =>
      _commit(state.copyWith(chessMoveConfirmMode: mode));

  Future<void> setChessAutoFlipPassPlay(bool enabled) =>
      _commit(state.copyWith(chessAutoFlipPassPlay: enabled));

  Future<void> setSudokuAutoFinish(bool enabled) =>
      _commit(state.copyWith(sudokuAutoFinish: enabled));

  Future<void> setSudokuAutoFinishThreshold(int cells) =>
      _commit(state.copyWith(sudokuAutoFinishThreshold: cells >= 7 ? 7 : 5));

  Future<void> setSudokuHighlightSameDigits(bool enabled) =>
      _commit(state.copyWith(sudokuHighlightSameDigits: enabled));

  Future<void> setSudokuAutoClearNotes(bool enabled) =>
      _commit(state.copyWith(sudokuAutoClearNotes: enabled));

  Future<void> setSudokuShowStreakStats(bool enabled) =>
      _commit(state.copyWith(sudokuShowStreakStats: enabled));

  Future<void> setSudokuSmartCandidateNotes(bool enabled) =>
      _commit(state.copyWith(sudokuSmartCandidateNotes: enabled));

  Future<void> setMinesweeperQuickChord(bool enabled) =>
      _commit(state.copyWith(minesweeperQuickChord: enabled));

  Future<void> setMinesweeperSwapTapFlag(bool enabled) =>
      _commit(state.copyWith(minesweeperSwapTapFlag: enabled));

  Future<void> setPracticeRewindOnLoss(bool enabled) =>
      _commit(state.copyWith(practiceRewindOnLoss: enabled));

  Future<void> setPracticeRewindSteps(int steps) =>
      _commit(state.copyWith(practiceRewindSteps: steps.clamp(1, 3)));

  Future<void> updateGuestProgression({
    Map<GameType, int>? unlockedLevels,
    int? chessElo,
  }) => _commit(
    state.copyWith(
      guestUnlockedLevels: unlockedLevels,
      guestChessElo: chessElo,
    ),
  );
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ── Auth & Profile Notifier ────────────────────────────────────────────────

class AuthNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final settings = ref.read(settingsProvider);
    final guest = UserProfile.guest(
      unlockedLevels: settings.guestUnlockedLevels,
      chessElo: settings.guestChessElo,
    );
    Future.microtask(_restoreRemoteSession);
    return guest;
  }

  Future<void> _restoreRemoteSession() async {
    final supa = ref.read(supabaseServiceProvider);
    if (!supa.isAvailable) return;
    try {
      final profile = await supa.fetchCurrentProfile();
      if (profile != null) {
        state = profile;
        await _applyRemoteAccountData(profile);
        await ref.read(scoreSyncControllerProvider).flushQueue();
      }
    } catch (e) {
      debugPrint('Profile restore failed: $e');
    }
  }

  Future<void> signIn(String username, String password) async {
    final supa = ref.read(supabaseServiceProvider);
    final profile = await supa.signIn(username: username, password: password);
    state = profile;
    await _applyRemoteAccountData(profile);
    await ref.read(scoreSyncControllerProvider).flushQueue();
  }

  Future<void> register({
    required String username,
    required String password,
    String? recoveryPhrase,
  }) async {
    final supa = ref.read(supabaseServiceProvider);
    final profile = await supa.register(
      username: username,
      password: password,
      recoveryPhrase: recoveryPhrase,
    );
    state = profile;
    await syncAccountSnapshotToCloud();
    await ref.read(scoreSyncControllerProvider).flushQueue();
  }

  Future<void> _applyRemoteAccountData(UserProfile profile) async {
    final cloudSettings = profile.syncedSettingsJson;
    if (cloudSettings != null && cloudSettings.isNotEmpty) {
      await ref.read(settingsProvider.notifier).applyCloudSettings(cloudSettings);
    } else {
      await syncAccountSnapshotToCloud();
    }
  }

  void setAccountDataSnapshot(Map<String, dynamic> accountData) {
    if (state.isGuest) return;
    state = state.copyWith(accountData: accountData);
  }

  /// Syncs full local settings + computed Stats snapshot to `profiles.account_data`.
  Future<void> syncAccountSnapshotToCloud() async {
    final supa = ref.read(supabaseServiceProvider);
    if (!supa.isAvailable || state.isGuest) return;
    try {
      final localRecords = await ref.read(localStorageProvider).fetchLocalRecords();
      final localSummary = StatsSummary.fromRecords(localRecords);
      final remoteSummary = state.syncedStats;
      final summaryToPush = (remoteSummary != null &&
              remoteSummary.totalPlayed > localSummary.totalPlayed)
          ? remoteSummary
          : localSummary;
      final updated = await supa.updateAccountData(
        settingsJson: ref.read(settingsProvider).toCloudJson(),
        statsSummary: summaryToPush,
        baseAccountData: state.accountData,
      );
      if (updated != null && ref.mounted) {
        state = state.copyWith(accountData: updated);
      }
    } catch (e) {
      debugPrint('Account data snapshot sync deferred: $e');
    }
  }

  Future<void> signOut() async {
    await ref.read(supabaseServiceProvider).signOut();
    final settings = ref.read(settingsProvider);
    state = UserProfile.guest(
      unlockedLevels: settings.guestUnlockedLevels,
      chessElo: settings.guestChessElo,
    );
  }

  Future<void> updateUsername(String newUsername) async {
    await ref.read(supabaseServiceProvider).updateUsername(newUsername);
    state = state.copyWith(username: newUsername);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await ref
        .read(supabaseServiceProvider)
        .changePassword(oldPassword: oldPassword, newPassword: newPassword);
  }

  Future<void> setRecoveryPhrase(String? phrase) async {
    await ref.read(supabaseServiceProvider).setRecoveryPhrase(phrase);
    state = state.copyWith(hasRecoveryCode: phrase != null && phrase.isNotEmpty);
  }

  Future<void> uploadAvatar(Uint8List bytes) async {
    final url = await ref.read(supabaseServiceProvider).uploadAvatar(bytes);
    state = state.copyWith(avatarUrl: url);
  }

  Future<void> recordUnlockIfEarned(GameType game, int wonDifficulty) async {
    final currentUnlocked = state.unlockedFor(game);
    var nextUnlocked = currentUnlocked;
    if (wonDifficulty == 5 && currentUnlocked < 6) nextUnlocked = 6;
    if (wonDifficulty == 6 && currentUnlocked < 7) nextUnlocked = 7;

    if (nextUnlocked == currentUnlocked) return;
    final updatedMap = Map<GameType, int>.from(state.unlockedLevels)
      ..[game] = nextUnlocked;
    state = state.copyWith(unlockedLevels: updatedMap);

    if (state.isGuest) {
      await ref
          .read(settingsProvider.notifier)
          .updateGuestProgression(unlockedLevels: updatedMap);
    } else {
      await ref
          .read(supabaseServiceProvider)
          .updateProgression(unlockedLevels: updatedMap);
    }
  }

  Future<void> updateChessElo(int newElo) async {
    final clamped = newElo.clamp(400, 3500);
    state = state.copyWith(chessElo: clamped);
    if (state.isGuest) {
      await ref
          .read(settingsProvider.notifier)
          .updateGuestProgression(chessElo: clamped);
    } else {
      await ref
          .read(supabaseServiceProvider)
          .updateProgression(
            unlockedLevels: state.unlockedLevels,
            chessElo: clamped,
          );
    }
  }

  Future<void> resetAllStats() async {
    await ref.read(localStorageProvider).clearAllLocalRecords();
    final defaultLevels = {
      for (final g in GameType.values) g: DifficultyLevel.defaultUnlockedLevel,
    };
    final nextData = Map<String, dynamic>.from(state.accountData)
      ..['stats'] = StatsSummary.empty.toJson();
    state = state.copyWith(
      chessElo: 1000,
      unlockedLevels: defaultLevels,
      accountData: nextData,
    );
    await ref
        .read(settingsProvider.notifier)
        .updateGuestProgression(unlockedLevels: defaultLevels, chessElo: 1000);
    if (!state.isGuest) {
      await ref.read(supabaseServiceProvider).resetRemoteStats();
    }
    ref.invalidate(localRecordsProvider);
    ref.invalidate(pendingQueueCountProvider);
  }

  Future<void> deleteAccount() async {
    await ref.read(supabaseServiceProvider).deleteAccount();
    await ref.read(localStorageProvider).clearAllLocalRecords();
    final defaultLevels = {
      for (final g in GameType.values) g: DifficultyLevel.defaultUnlockedLevel,
    };
    await ref
        .read(settingsProvider.notifier)
        .updateGuestProgression(unlockedLevels: defaultLevels, chessElo: 1000);
    state = UserProfile.guest();
    ref.invalidate(localRecordsProvider);
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserProfile>(
  AuthNotifier.new,
);

// ── Auto-Save Slots (4 Independent Slots) ──────────────────────────────────

class AutoSaveSlotsNotifier extends Notifier<Map<GameType, AutoSaveSlot>> {
  @override
  Map<GameType, AutoSaveSlot> build() {
    Future.microtask(refresh);
    return const {};
  }

  Future<void> refresh() async {
    final slots = await ref.read(localStorageProvider).loadAllGameSlots();
    if (!ref.mounted) return;
    state = slots;
  }

  Future<void> saveSlot(AutoSaveSlot slot) async {
    await ref.read(localStorageProvider).saveGameSlot(slot);
    if (!ref.mounted) return;
    state = {...state, slot.gameType: slot};
  }

  Future<void> clearSlot(GameType gameType) async {
    await ref.read(localStorageProvider).clearGameSlot(gameType);
    if (!ref.mounted) return;
    final next = Map<GameType, AutoSaveSlot>.from(state)..remove(gameType);
    state = next;
  }
}

final autoSaveSlotsProvider =
    NotifierProvider<AutoSaveSlotsNotifier, Map<GameType, AutoSaveSlot>>(
      AutoSaveSlotsNotifier.new,
    );

// ── Score Recording & Offline Sync Queue ───────────────────────────────────

class ScoreSyncController {
  ScoreSyncController(this._ref);
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  void startListening() {
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        flushQueue();
      }
    });
  }

  Future<bool> recordGameResult({
    required GameType gameType,
    required int difficulty,
    required bool isWon,
    required int score,
    required int durationMs,
    bool isPractice = false,
    bool allowUnlock = true,
    bool syncRemote = true,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (isPractice) return false;

    final user = _ref.read(authProvider);
    final storage = _ref.read(localStorageProvider);

    // Check if this is a new personal best BEFORE inserting.
    final existing = await storage.fetchLocalRecords(
      gameType: gameType,
      difficulty: difficulty,
    );
    bool isNewRecord = false;
    if (syncRemote && (isWon || gameType == GameType.snake)) {
      if (existing.isEmpty) {
        isNewRecord = true;
      } else if (gameType == GameType.snake || gameType == GameType.chess) {
        final bestScore = existing.map((e) => e.score).reduce(max);
        isNewRecord = score > bestScore;
      } else {
        final wonRecords = existing.where((e) => e.isWon).toList();
        if (wonRecords.isEmpty) {
          isNewRecord = isWon;
        } else {
          final fastest = wonRecords.map((e) => e.durationMs).reduce(min);
          isNewRecord = isWon && durationMs < fastest;
        }
      }
    }

    final record = GameRecord(
      id: _generateUuidV4(),
      userId: user.id,
      username: user.username,
      avatarUrl: user.avatarUrl,
      gameType: gameType,
      difficulty: difficulty,
      isWon: isWon,
      score: score,
      durationMs: durationMs < 3000 ? 3000 : durationMs,
      platform: PlatformDetector.currentPlatform,
      playedAt: DateTime.now().toUtc(),
      metadata: metadata,
    );

    await storage.saveLocalRecord(record);
    if (isWon && allowUnlock) {
      await _ref
          .read(authProvider.notifier)
          .recordUnlockIfEarned(gameType, difficulty);
    }

    if (syncRemote) {
      await storage.enqueueScore(record);
      _ref.invalidate(pendingQueueCountProvider);
    }
    _ref.invalidate(localRecordsProvider);
    await _ref.read(authProvider.notifier).syncAccountSnapshotToCloud();

    if (syncRemote) {
      await flushQueue();
    }
    return isNewRecord;
  }

  Future<void> flushQueue() async {
    final supa = _ref.read(supabaseServiceProvider);
    final user = _ref.read(authProvider);
    if (!supa.isAvailable || user.isGuest) return;

    final storage = _ref.read(localStorageProvider);
    final queued = await storage.getQueuedScores();
    for (final item in queued) {
      try {
        await supa.uploadGameRecord(item);
        await storage.removeQueuedScore(item.id);
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          await storage.removeQueuedScore(item.id);
          continue;
        }
        debugPrint('Offline score flush deferred: $e');
        break;
      } catch (e) {
        debugPrint('Offline score flush deferred: $e');
        break;
      }
    }
    _ref.invalidate(pendingQueueCountProvider);
  }

  void dispose() {
    _connSub?.cancel();
  }

  String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}

final scoreSyncControllerProvider = Provider<ScoreSyncController>((ref) {
  final controller = ScoreSyncController(ref);
  controller.startListening();
  ref.onDispose(controller.dispose);
  return controller;
});

final localRecordsProvider = FutureProvider<List<GameRecord>>((ref) async {
  return ref.watch(localStorageProvider).fetchLocalRecords();
});

/// Combines local match records with synced cloud [UserProfile.syncedStats] so
/// signing in on a new device immediately restores Statistics page widgets.
final statsSummaryProvider = FutureProvider<StatsSummary>((ref) async {
  final records = await ref.watch(localRecordsProvider.future);
  final localSummary = StatsSummary.fromRecords(records);
  final user = ref.watch(authProvider);
  final remoteSummary = user.isGuest ? null : user.syncedStats;
  if (remoteSummary != null &&
      remoteSummary.totalPlayed > localSummary.totalPlayed) {
    return remoteSummary;
  }
  return localSummary;
});

final pendingQueueCountProvider = FutureProvider<int>((ref) async {
  final queue = await ref.watch(localStorageProvider).getQueuedScores();
  return queue.length;
});
