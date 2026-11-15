import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ── Settings Notifier ──────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repo = ref.watch(settingsRepoProvider);
    final loaded = repo.load();
    _syncServices(loaded);
    return loaded;
  }

  void _syncServices(AppSettings s) {
    ref.read(audioServiceProvider).updatePreferences(
      sfxEnabled: s.sfxEnabled,
      bgmEnabled: s.bgmEnabled,
    );
    ref.read(hapticServiceProvider).enabled = s.hapticsEnabled;
    ref.read(wakelockServiceProvider).updateSetting(s.wakelockEnabled);
  }

  Future<void> _commit(AppSettings next) async {
    state = next;
    _syncServices(next);
    await ref.read(settingsRepoProvider).save(next);
  }

  Future<void> setTheme(ZetzyThemeMode mode) =>
      _commit(state.copyWith(themeMode: mode));

  Future<void> setLocale(String code) =>
      _commit(state.copyWith(localeCode: code));

  Future<void> setSfx(bool enabled) =>
      _commit(state.copyWith(sfxEnabled: enabled));

  Future<void> setBgm(bool enabled) =>
      _commit(state.copyWith(bgmEnabled: enabled));

  Future<void> setHaptics(bool enabled) =>
      _commit(state.copyWith(hapticsEnabled: enabled));

  Future<void> setWakelock(bool enabled) =>
      _commit(state.copyWith(wakelockEnabled: enabled));

  Future<void> setSnakeControl(SnakeControlMode mode) =>
      _commit(state.copyWith(snakeControlMode: mode));

  Future<void> setChessPieceSet(ChessPieceSet pieceSet) =>
      _commit(state.copyWith(chessPieceSet: pieceSet));

  Future<void> setChessAutoQueen(bool autoQueen) =>
      _commit(state.copyWith(chessAutoQueen: autoQueen));

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
    await ref.read(scoreSyncControllerProvider).flushQueue();
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
    state = state.copyWith(chessElo: 1000, unlockedLevels: defaultLevels);
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
    if (isWon || gameType == GameType.snake) {
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
    if (isWon) {
      await _ref
          .read(authProvider.notifier)
          .recordUnlockIfEarned(gameType, difficulty);
    }

    await storage.enqueueScore(record);
    _ref.invalidate(localRecordsProvider);
    _ref.invalidate(pendingQueueCountProvider);

    await flushQueue();
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

final pendingQueueCountProvider = FutureProvider<int>((ref) async {
  final queue = await ref.watch(localStorageProvider).getQueuedScores();
  return queue.length;
});
