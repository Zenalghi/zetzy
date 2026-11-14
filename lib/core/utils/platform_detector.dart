import 'package:flutter/foundation.dart';

/// Detects the current runtime OS/platform for leaderboard records (PRD 3.2).
abstract final class PlatformDetector {
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.fuchsia => 'linux',
    };
  }

  static bool get isDesktopOrWeb =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
