import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/time_formatter.dart';

/// Monospace millisecond timer pill (`MM:SS.ms`).
class GameTimerBadge extends StatelessWidget {
  const GameTimerBadge({
    super.key,
    required this.elapsedMs,
    this.isPaused = false,
  });

  final int elapsedMs;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPaused ? p.warning : p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaused ? Icons.pause_circle_filled_rounded : Icons.timer_outlined,
            size: 16,
            color: isPaused ? p.warning : p.accent,
          ),
          const SizedBox(width: 6),
          Text(
            TimeFormatter.formatMs(elapsedMs),
            style: ZetzyThemes.monoStyle(
              fontSize: 14,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
