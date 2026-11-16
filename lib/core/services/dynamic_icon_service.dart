import 'package:flutter/foundation.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';

/// Manages the mobile-only (Android & iOS) dynamic launcher icon easter egg:
/// - Between 23:00 and 05:30 local time, switches silently to `abyssal_cyan0`.
/// - Outside that window, mirrors the user's active theme (and Abyssal alter
///   ego), falling back to the default `warm_parchment` launcher icon.
/// - No-op on Web, macOS, Windows, and Linux where static icons are used.
class DynamicIconService {
  DynamicIconService._();

  static final DynamicIconService instance = DynamicIconService._();

  bool _syncing = false;
  String? _lastAppliedKey;
  bool _hasAppliedOnce = false;

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Returns true when [now] falls inside the 23:00..05:30 local night window.
  static bool isNightEasterEggWindow(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    return minutes >= 23 * 60 || minutes < 5 * 60 + 30;
  }

  /// Resolves the native alternate icon name (`null` = default warm_parchment).
  static String? resolveLauncherIconName({
    required ZetzyThemeMode themeMode,
    required bool abyssalAlterEgo,
    required DateTime now,
  }) {
    if (isNightEasterEggWindow(now)) {
      return 'abyssal_cyan0';
    }
    return switch (themeMode) {
      ZetzyThemeMode.oledMidnight => 'oled_midnight',
      ZetzyThemeMode.classicWood => 'classic_wood',
      ZetzyThemeMode.nordicFrost => 'nordic_frost',
      ZetzyThemeMode.draculaNeon => 'dracula_neon',
      ZetzyThemeMode.abyssalCyan =>
        abyssalAlterEgo ? 'abyssal_cyan1' : 'abyssal_cyan0',
      ZetzyThemeMode.warmParchment => null,
    };
  }

  static String? _normalizeIconName(String? raw) {
    if (raw == null || raw.isEmpty || raw == '.DEFAULT' || raw == 'DEFAULT') {
      return null;
    }
    return raw.startsWith('.') ? raw.substring(1) : raw;
  }

  /// Silently aligns the Android/iOS launcher icon with the active rule.
  Future<void> syncLauncherIcon({
    required ZetzyThemeMode themeMode,
    required bool abyssalAlterEgo,
    DateTime? now,
  }) async {
    if (!isSupportedPlatform || _syncing) return;

    final target = resolveLauncherIconName(
      themeMode: themeMode,
      abyssalAlterEgo: abyssalAlterEgo,
      now: now ?? DateTime.now(),
    );
    if (_hasAppliedOnce && _lastAppliedKey == target) return;

    _syncing = true;
    try {
      final supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
      if (!supported) return;

      final currentRaw = await FlutterDynamicIconPlus.alternateIconName;
      final current = _normalizeIconName(currentRaw);
      if (current == target) {
        _lastAppliedKey = target;
        _hasAppliedOnce = true;
        return;
      }

      await FlutterDynamicIconPlus.setAlternateIconName(iconName: target);
      _lastAppliedKey = target;
      _hasAppliedOnce = true;
    } catch (e) {
      debugPrint('Dynamic icon sync skipped: $e');
    } finally {
      _syncing = false;
    }
  }
}
