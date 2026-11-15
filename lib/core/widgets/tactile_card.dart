import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';

/// Tactile Modern Minimalist card combining flat cleanliness with subtle depth.
class TactileCard extends StatelessWidget {
  const TactileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = backgroundColor ?? p.surface;
    final br = BorderRadius.circular(borderRadius);

    final container = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        border: Border.all(color: borderColor ?? p.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color:
                glowColor?.withValues(alpha: 0.16) ??
                Colors.black.withValues(alpha: 0.18),
            blurRadius: glowColor != null ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: br,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: container,
      ),
    );
  }
}
