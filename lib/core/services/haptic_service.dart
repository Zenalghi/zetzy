import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zetzy/core/constants/app_constants.dart';

enum HapticPulseKind { selection, light, medium, heavy }

/// Drives configurable haptic feedback via native Android `Vibrator` duration/
/// amplitude control (for crisp, noticeable vibration on Android hardware) and
/// platform-appropriate `HapticFeedback` on iOS/Web/Desktop (PRD 69A).
class HapticService {
  static const MethodChannel _channel = MethodChannel('zetzy/haptics');

  bool enabled = true;
  HapticIntensity intensity = HapticIntensity.medium;

  /// Returns the duration (ms) and amplitude (1..255) for a given pulse.
  static ({int durationMs, int amplitude}) specFor(
    HapticIntensity intensity,
    HapticPulseKind kind,
  ) {
    return switch ((intensity, kind)) {
      (HapticIntensity.light, HapticPulseKind.selection) => (
        durationMs: 12,
        amplitude: 80,
      ),
      (HapticIntensity.light, HapticPulseKind.light) => (
        durationMs: 20,
        amplitude: 110,
      ),
      (HapticIntensity.light, HapticPulseKind.medium) => (
        durationMs: 32,
        amplitude: 155,
      ),
      (HapticIntensity.light, HapticPulseKind.heavy) => (
        durationMs: 58,
        amplitude: 210,
      ),
      (HapticIntensity.medium, HapticPulseKind.selection) => (
        durationMs: 20,
        amplitude: 125,
      ),
      (HapticIntensity.medium, HapticPulseKind.light) => (
        durationMs: 32,
        amplitude: 175,
      ),
      (HapticIntensity.medium, HapticPulseKind.medium) => (
        durationMs: 52,
        amplitude: 220,
      ),
      (HapticIntensity.medium, HapticPulseKind.heavy) => (
        durationMs: 95,
        amplitude: 255,
      ),
      (HapticIntensity.strong, HapticPulseKind.selection) => (
        durationMs: 30,
        amplitude: 190,
      ),
      (HapticIntensity.strong, HapticPulseKind.light) => (
        durationMs: 48,
        amplitude: 235,
      ),
      (HapticIntensity.strong, HapticPulseKind.medium) => (
        durationMs: 80,
        amplitude: 255,
      ),
      (HapticIntensity.strong, HapticPulseKind.heavy) => (
        durationMs: 145,
        amplitude: 255,
      ),
    };
  }

  void light() => _trigger(HapticPulseKind.light);

  void medium() => _trigger(HapticPulseKind.medium);

  void heavy() => _trigger(HapticPulseKind.heavy);

  void selection() => _trigger(HapticPulseKind.selection);

  void _trigger(HapticPulseKind kind) {
    if (!enabled) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_triggerAndroid(kind));
      return;
    }
    _triggerFallback(kind);
  }

  Future<void> _triggerAndroid(HapticPulseKind kind) async {
    final spec = specFor(intensity, kind);
    try {
      final ok = await _channel.invokeMethod<bool>('vibrate', {
        'durationMs': spec.durationMs,
        'amplitude': spec.amplitude,
      });
      if (ok == true) return;
    } on MissingPluginException {
      // Running in unit/widget tests or desktop without Android runner.
      return;
    } catch (_) {}
    _triggerFallback(kind);
  }

  void _triggerFallback(HapticPulseKind kind) {
    switch ((intensity, kind)) {
      case (HapticIntensity.light, HapticPulseKind.selection):
        HapticFeedback.selectionClick();
      case (HapticIntensity.light, HapticPulseKind.light):
        HapticFeedback.lightImpact();
      case (HapticIntensity.light, HapticPulseKind.medium):
        HapticFeedback.mediumImpact();
      case (HapticIntensity.light, HapticPulseKind.heavy):
        HapticFeedback.heavyImpact();
      case (HapticIntensity.medium, HapticPulseKind.selection):
        HapticFeedback.lightImpact();
      case (HapticIntensity.medium, HapticPulseKind.light):
        HapticFeedback.mediumImpact();
      case (HapticIntensity.medium, HapticPulseKind.medium):
        HapticFeedback.heavyImpact();
      case (HapticIntensity.medium, HapticPulseKind.heavy):
        HapticFeedback.vibrate();
      case (HapticIntensity.strong, HapticPulseKind.selection):
        HapticFeedback.mediumImpact();
      case (HapticIntensity.strong, HapticPulseKind.light):
        HapticFeedback.heavyImpact();
      case (HapticIntensity.strong, HapticPulseKind.medium):
      case (HapticIntensity.strong, HapticPulseKind.heavy):
        HapticFeedback.vibrate();
    }
  }
}
