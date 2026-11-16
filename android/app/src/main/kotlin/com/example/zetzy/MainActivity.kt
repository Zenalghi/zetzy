package com.example.zetzy

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "zetzy/haptics",
    ).setMethodCallHandler { call, result ->
      if (call.method == "vibrate") {
        val durationMs = (call.argument<Number>("durationMs")?.toLong() ?: 25L)
          .coerceIn(5L, 400L)
        val amplitude = (call.argument<Number>("amplitude")?.toInt() ?: 180)
          .coerceIn(1, 255)
        result.success(triggerVibration(durationMs, amplitude))
      } else {
        result.notImplemented()
      }
    }
  }

  private fun triggerVibration(durationMs: Long, amplitude: Int): Boolean {
    return try {
      val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val manager =
          getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
        manager?.defaultVibrator
      } else {
        @Suppress("DEPRECATION")
        getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
      } ?: return false

      if (!vibrator.hasVibrator()) return false

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val effAmp = if (vibrator.hasAmplitudeControl()) {
          amplitude
        } else {
          VibrationEffect.DEFAULT_AMPLITUDE
        }
        vibrator.vibrate(VibrationEffect.createOneShot(durationMs, effAmp))
      } else {
        @Suppress("DEPRECATION")
        vibrator.vibrate(durationMs)
      }
      true
    } catch (_: Throwable) {
      false
    }
  }
}
