import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Semantic sound effects defined in PRD Section 5B.
enum ZetzySfx {
  uiClick('audio/sfx_ui_click.wav'),
  sudokuTap('audio/sfx_sudoku_tap.wav'),
  errorBuzz('audio/sfx_error_buzz.wav'),
  chessMove('audio/sfx_chess_move.wav'),
  chessCapture('audio/sfx_chess_capture.wav'),
  chessCheck('audio/sfx_chess_check.wav'),
  mineDig('audio/sfx_mine_dig.wav'),
  mineFlag('audio/sfx_mine_flag.wav'),
  mineShield('audio/sfx_mine_shield.wav'),
  mineExplode('audio/sfx_mine_explode.wav'),
  snakeEat('audio/sfx_snake_eat.wav'),
  snakePowerup('audio/sfx_snake_powerup.wav'),
  gameWin('audio/sfx_game_win.wav');

  const ZetzySfx(this.assetPath);
  final String assetPath;
}

/// Manages SFX and BGM playback gracefully even before audio assets are added.
class AudioService {
  static const String bgmPath = 'audio/bgm_chill_loop.mp3';

  AudioPlayer? _sfxPlayer;
  AudioPlayer? _bgmPlayer;
  Set<String> _availableAssets = const {};
  bool _initialized = false;
  bool _sfxEnabled = true;
  bool _bgmEnabled = false;

  bool get hasAudioAssets =>
      _availableAssets.any((path) => path.startsWith('assets/audio/'));

  Future<void> init({
    required bool sfxEnabled,
    required bool bgmEnabled,
  }) async {
    _sfxEnabled = sfxEnabled;
    _bgmEnabled = bgmEnabled;
    if (_initialized) return;
    _initialized = true;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _availableAssets = manifest.listAssets().toSet();
    } catch (_) {
      _availableAssets = const {};
    }

    if (hasAudioAssets) {
      _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _bgmPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      if (_bgmEnabled) {
        await startBgm();
      }
    }
  }

  void updatePreferences({required bool sfxEnabled, required bool bgmEnabled}) {
    _sfxEnabled = sfxEnabled;
    final bgmChanged = _bgmEnabled != bgmEnabled;
    _bgmEnabled = bgmEnabled;

    if (bgmChanged) {
      if (_bgmEnabled) {
        startBgm();
      } else {
        stopBgm();
      }
    }
  }

  Future<void> playSfx(ZetzySfx sfx) async {
    if (!_sfxEnabled) return;
    final fullKey = 'assets/${sfx.assetPath}';
    if (!_availableAssets.contains(fullKey)) return;

    try {
      _sfxPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer!.play(AssetSource(sfx.assetPath));
    } catch (e) {
      debugPrint('AudioService SFX skipped (${sfx.assetPath}): $e');
    }
  }

  Future<void> startBgm() async {
    if (!_bgmEnabled) return;
    const fullKey = 'assets/$bgmPath';
    if (!_availableAssets.contains(fullKey)) return;

    try {
      _bgmPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(0.35);
      await _bgmPlayer!.play(AssetSource(bgmPath));
    } catch (e) {
      debugPrint('AudioService BGM skipped: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _sfxPlayer?.dispose();
      await _bgmPlayer?.dispose();
    } catch (_) {}
  }
}
