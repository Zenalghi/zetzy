/// Formats millisecond durations into monospace-friendly strings (PRD 3.2).
abstract final class TimeFormatter {
  /// Returns `MM:SS.ms` (centiseconds), e.g., `02:14.85`.
  static String formatMs(int durationMs) {
    final safeMs = durationMs < 0 ? 0 : durationMs;
    final totalSeconds = safeMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final centiseconds = (safeMs % 1000) ~/ 10;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    final cs = centiseconds.toString().padLeft(2, '0');
    return '$mm:$ss.$cs';
  }

  /// Returns `MM:SS` for chess countdown clocks.
  static String formatClock(int durationMs) {
    final safeMs = durationMs < 0 ? 0 : durationMs;
    final totalSeconds = (safeMs / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns human-readable total hours/minutes for Statistics screen.
  static String formatTotalDuration(int durationMs) {
    final totalMinutes = durationMs ~/ 60000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    final seconds = (durationMs % 60000) ~/ 1000;
    return '${minutes}m ${seconds}s';
  }
}
