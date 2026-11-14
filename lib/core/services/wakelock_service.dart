import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps screen awake during active games when enabled (PRD 70A).
class WakelockService {
  bool _enabledSetting = true;

  void updateSetting(bool enabled) {
    _enabledSetting = enabled;
    if (!enabled) {
      disable();
    }
  }

  Future<void> enableIfAllowed() async {
    if (!_enabledSetting) return;
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Wakelock enable skipped: $e');
    }
  }

  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Wakelock disable skipped: $e');
    }
  }
}
