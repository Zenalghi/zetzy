import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zetzy/core/constants/app_constants.dart';

/// Semantic sound effect prefixes bundled in `assets/audio/`.
///
/// Any numbered variations (e.g. `sfx_sudoku_tap1.mp3` .. `sfx_sudoku_tap4.mp3`
/// or `sfx_sudoku_tap.wav`) are automatically discovered at startup and played
/// in non-repeating random order so interactions stay fresh.
enum ZetzySfx {
  uiClick('sfx_ui_click'),
  sudokuTap('sfx_sudoku_tap'),
  sudokuLineComplete('sfx_sudoku_line'),
  sudokuAutoFinish('sfx_sudoku_autofill'),
  errorBuzz('sfx_error_buzz'),
  chessMove('sfx_chess_move'),
  chessCapture('sfx_chess_capture'),
  chessCheck('sfx_chess_check'),
  chessMatchFound('sfx_match_found'),
  mineDig('sfx_mine_dig'),
  mineChord('sfx_mine_chord'),
  mineFlag('sfx_mine_flag'),
  mineShield('sfx_mine_shield'),
  mineExplode('sfx_mine_explode'),
  snakeEat('sfx_snake_eat'),
  snakePowerup('sfx_snake_powerup'),
  snakeWarning('sfx_snake_warning'),
  undoRewind('sfx_undo_rewind'),
  gameWin('sfx_game_win'),
  gameLose('sfx_game_lose');

  const ZetzySfx(this.prefix);
  final String prefix;
}

/// Manages randomized multi-variant SFX and Auto/Manual BGM playback gracefully.
class AudioService {
  AudioService({Random? random}) : _rng = random ?? Random();

  static const String favoriteBgmFilename = '5.mp3';
  static const int favoriteBgmWeight = 3;
  static final RegExp _audioExtRegex = RegExp(
    r'\.(mp3|wav|ogg|m4a)$',
    caseSensitive: false,
  );

  final Random _rng;
  AudioPlayer? _sfxPlayer;
  AudioPlayer? _bgmPlayer;
  StreamSubscription<void>? _bgmCompleteSub;

  Set<String> _availableAssets = const {};
  Map<ZetzySfx, List<String>> _sfxVariants = const {};
  final Map<ZetzySfx, String> _lastPlayedSfx = {};
  List<String> _bgmTracks = const [];

  bool _initialized = false;
  bool _sfxEnabled = true;
  BgmMode _bgmMode = BgmMode.auto;
  String _manualBgmTrack = favoriteBgmFilename;
  String? _currentBgmAsset;
  bool _isBgmPlaying = false;
  bool _pausedByLifecycle = false;

  /// Reactive notifier emitting the currently selected/playing BGM relative asset path.
  final ValueNotifier<String?> currentBgmNotifier = ValueNotifier<String?>(
    null,
  );

  bool get hasAudioAssets =>
      _sfxVariants.values.any((list) => list.isNotEmpty) ||
      _bgmTracks.isNotEmpty;

  List<String> get bgmTracks => _bgmTracks;
  String? get currentBgmAsset => _currentBgmAsset;
  BgmMode get bgmMode => _bgmMode;

  Future<void> init({
    required bool sfxEnabled,
    required BgmMode bgmMode,
    String manualBgmTrack = favoriteBgmFilename,
  }) async {
    _sfxEnabled = sfxEnabled;
    _bgmMode = bgmMode;
    _manualBgmTrack = manualBgmTrack;
    if (_initialized) return;
    _initialized = true;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _availableAssets = manifest.listAssets().toSet();
    } catch (_) {
      _availableAssets = const {};
    }
    _rebuildAudioIndex();

    if (hasAudioAssets) {
      _ensurePlayers();
      if (_bgmMode != BgmMode.off) {
        await startBgm();
      }
    }
  }

  void _ensurePlayers() {
    final mixContext = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    if (_sfxPlayer == null) {
      _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      unawaited(_sfxPlayer!.setAudioContext(mixContext));
    }
    if (_bgmPlayer == null) {
      _bgmPlayer = AudioPlayer();
      unawaited(_bgmPlayer!.setAudioContext(mixContext));
      _bgmCompleteSub = _bgmPlayer!.onPlayerComplete.listen((_) {
        if (_bgmMode == BgmMode.auto && !_pausedByLifecycle) {
          unawaited(_playNextAutoTrack());
        }
      });
    }
  }

  void updatePreferences({
    required bool sfxEnabled,
    required BgmMode bgmMode,
    required String manualBgmTrack,
  }) {
    _sfxEnabled = sfxEnabled;
    final prevMode = _bgmMode;
    final prevTrack = _manualBgmTrack;
    _bgmMode = bgmMode;
    _manualBgmTrack = manualBgmTrack;

    if (bgmMode == BgmMode.off) {
      _pausedByLifecycle = false;
      unawaited(stopBgm());
      return;
    }

    final modeChanged = prevMode != bgmMode;
    final manualTrackChanged =
        bgmMode == BgmMode.manual && prevTrack != manualBgmTrack;

    if (modeChanged || manualTrackChanged || !_isBgmPlaying) {
      _pausedByLifecycle = false;
      unawaited(startBgm(forceRestart: modeChanged || manualTrackChanged));
    }
  }

  /// Pauses/resumes BGM politely when the app moves between foreground/background.
  void handleAppLifecycleState(bool isForeground) {
    if (_bgmTracks.isEmpty || _bgmMode == BgmMode.off) return;
    if (!isForeground) {
      if (_isBgmPlaying) {
        _pausedByLifecycle = true;
        unawaited(_bgmPlayer?.pause());
      }
    } else if (_pausedByLifecycle) {
      _pausedByLifecycle = false;
      unawaited(_bgmPlayer?.resume());
    }
  }

  @visibleForTesting
  void setAvailableAssetsForTest(Set<String> assets) {
    _availableAssets = assets;
    _lastPlayedSfx.clear();
    _rebuildAudioIndex();
  }

  void _rebuildAudioIndex() {
    final audioAssets = _availableAssets
        .where(
          (p) => p.startsWith('assets/audio/') && _audioExtRegex.hasMatch(p),
        )
        .toList();

    final sfxMap = <ZetzySfx, List<String>>{};
    for (final sfx in ZetzySfx.values) {
      final matcher = RegExp(
        '^${RegExp.escape(sfx.prefix)}\\d*\\.(mp3|wav|ogg|m4a)\$',
        caseSensitive: false,
      );
      final matches = <String>[];
      for (final fullPath in audioAssets) {
        final fileName = fullPath.split('/').last;
        if (matcher.hasMatch(fileName)) {
          matches.add(fullPath.substring('assets/'.length));
        }
      }
      matches.sort(_compareNaturalAssetPaths);
      sfxMap[sfx] = List.unmodifiable(matches);
    }
    _sfxVariants = Map.unmodifiable(sfxMap);

    final bgms = <String>[];
    for (final fullPath in audioAssets) {
      if (fullPath.startsWith('assets/audio/mp3/bgm/') ||
          fullPath.split('/').last.toLowerCase().startsWith('bgm')) {
        bgms.add(fullPath.substring('assets/'.length));
      }
    }
    bgms.sort(_compareNaturalAssetPaths);
    _bgmTracks = List.unmodifiable(bgms);
  }

  static int _compareNaturalAssetPaths(String a, String b) {
    final nameA = a.split('/').last;
    final nameB = b.split('/').last;
    final numMatchA = RegExp(r'(\d+)\.[^.]+$').firstMatch(nameA);
    final numMatchB = RegExp(r'(\d+)\.[^.]+$').firstMatch(nameB);
    if (numMatchA != null && numMatchB != null) {
      final stemA = nameA.substring(0, numMatchA.start);
      final stemB = nameB.substring(0, numMatchB.start);
      if (stemA == stemB) {
        return int.parse(numMatchA.group(1)!).compareTo(
          int.parse(numMatchB.group(1)!),
        );
      }
    }
    return a.compareTo(b);
  }

  /// Extracts a human-friendly track number/name (e.g. `5` from `audio/mp3/bgm/5.mp3`).
  static String trackDisplayNumber(String assetPath) {
    final fileName = assetPath.split('/').last;
    return fileName.replaceFirst(_audioExtRegex, '');
  }

  static bool isFavoriteBgm(String assetPath) =>
      assetPath.split('/').last.toLowerCase() == favoriteBgmFilename;

  @visibleForTesting
  List<String> variantsFor(ZetzySfx sfx) => _sfxVariants[sfx] ?? const [];

  /// Picks a random variation for [sfx] (or [fallback]), avoiding repeating the
  /// exact same file twice in a row whenever multiple variants exist.
  String? pickSfxAsset(ZetzySfx sfx, {ZetzySfx? fallback}) {
    var resolvedKey = sfx;
    var variants = _sfxVariants[sfx] ?? const <String>[];
    if (variants.isEmpty && fallback != null) {
      resolvedKey = fallback;
      variants = _sfxVariants[fallback] ?? const <String>[];
    }
    if (variants.isEmpty) return null;
    if (variants.length == 1) {
      _lastPlayedSfx[resolvedKey] = variants.first;
      return variants.first;
    }

    final last = _lastPlayedSfx[resolvedKey];
    final pool = last == null
        ? variants
        : variants.where((v) => v != last).toList(growable: false);
    final chosen = pool[_rng.nextInt(pool.length)];
    _lastPlayedSfx[resolvedKey] = chosen;
    return chosen;
  }

  /// Picks the next BGM track in Auto mode, boosting `5.mp3` ([favoriteBgmWeight]x)
  /// and avoiding immediate back-to-back repeats when multiple tracks exist.
  String? pickAutoBgmTrack({String? excludeCurrent}) {
    if (_bgmTracks.isEmpty) return null;
    if (_bgmTracks.length == 1) return _bgmTracks.first;

    final current = excludeCurrent ?? _currentBgmAsset;
    final candidates = current != null && _bgmTracks.length > 1
        ? _bgmTracks.where((t) => t != current).toList(growable: false)
        : _bgmTracks;

    final totalWeight = candidates.fold<int>(
      0,
      (sum, t) => sum + (isFavoriteBgm(t) ? favoriteBgmWeight : 1),
    );
    var roll = _rng.nextInt(totalWeight);
    for (final track in candidates) {
      roll -= isFavoriteBgm(track) ? favoriteBgmWeight : 1;
      if (roll < 0) return track;
    }
    return candidates.last;
  }

  /// Resolves a manual track selection (`'5.mp3'`, `'5'`, or full path) to a
  /// bundled relative asset path.
  String? resolveManualBgmTrack([String? requested]) {
    if (_bgmTracks.isEmpty) return null;
    final target = (requested ?? _manualBgmTrack).trim();
    if (target.isEmpty) return _bgmTracks.first;
    for (final track in _bgmTracks) {
      if (track == target ||
          track.split('/').last == target ||
          trackDisplayNumber(track) == target) {
        return track;
      }
    }
    return _bgmTracks.first;
  }

  Future<void> playSfx(ZetzySfx sfx, {ZetzySfx? fallback}) async {
    if (_bgmMode != BgmMode.off &&
        !_isBgmPlaying &&
        !_pausedByLifecycle &&
        _bgmTracks.isNotEmpty) {
      unawaited(startBgm());
    }
    if (!_sfxEnabled) return;
    final chosenPath = pickSfxAsset(sfx, fallback: fallback);
    if (chosenPath == null) return;

    try {
      _ensurePlayers();
      await _sfxPlayer!.play(AssetSource(chosenPath));
    } catch (e) {
      debugPrint('AudioService SFX skipped ($chosenPath): $e');
    }
  }

  Future<void> startBgm({bool forceRestart = false}) async {
    if (_bgmMode == BgmMode.off || _bgmTracks.isEmpty) return;
    final targetTrack = _bgmMode == BgmMode.manual
        ? resolveManualBgmTrack()
        : (forceRestart || _currentBgmAsset == null
              ? pickAutoBgmTrack()
              : _currentBgmAsset);
    if (targetTrack == null) return;
    await _playBgmTrack(
      targetTrack,
      loop: _bgmMode == BgmMode.manual,
    );
  }

  Future<void> skipToNextAutoBgm() async {
    if (_bgmMode != BgmMode.auto || _bgmTracks.isEmpty) return;
    await _playNextAutoTrack();
  }

  Future<void> _playNextAutoTrack() async {
    final next = pickAutoBgmTrack(excludeCurrent: _currentBgmAsset);
    if (next == null) return;
    await _playBgmTrack(next, loop: false);
  }

  Future<void> _playBgmTrack(String assetPath, {required bool loop}) async {
    _currentBgmAsset = assetPath;
    currentBgmNotifier.value = assetPath;
    try {
      _ensurePlayers();
      await _bgmPlayer!.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await _bgmPlayer!.setVolume(0.32);
      await _bgmPlayer!.stop();
      await _bgmPlayer!.play(AssetSource(assetPath));
      _isBgmPlaying = true;
    } catch (e) {
      _isBgmPlaying = false;
      debugPrint('AudioService BGM skipped ($assetPath): $e');
    }
  }

  Future<void> stopBgm() async {
    _isBgmPlaying = false;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _bgmCompleteSub?.cancel();
    _bgmCompleteSub = null;
    currentBgmNotifier.dispose();
    try {
      await _sfxPlayer?.dispose();
      await _bgmPlayer?.dispose();
    } catch (_) {}
  }
}
