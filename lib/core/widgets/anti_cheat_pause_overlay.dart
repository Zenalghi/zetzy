import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/l10n/app_localizations.dart';

/// Glassmorphism blur overlay triggered on manual pause or app focus loss (PRD 21A).
class AntiCheatPauseOverlay extends StatelessWidget {
  const AntiCheatPauseOverlay({
    super.key,
    required this.isPaused,
    required this.onResume,
    this.onRestart,
    this.onQuit,
  });

  final bool isPaused;
  final VoidCallback onResume;
  final VoidCallback? onRestart;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    if (!isPaused) return const SizedBox.shrink();
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: p.glassTint,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: p.border, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 42, color: p.accent),
                    const SizedBox(height: 12),
                    Text(
                      l10n.pausedTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.pausedSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onResume,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.resume),
                      ),
                    ),
                    if (onRestart != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onRestart,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.restart),
                        ),
                      ),
                    ],
                    if (onQuit != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: onQuit,
                          icon: const Icon(Icons.exit_to_app_rounded),
                          label: Text(l10n.quit),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
