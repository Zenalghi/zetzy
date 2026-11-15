import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';

/// Circular user avatar displaying [avatarUrl] with graceful initial-letter fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.radius = 16,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackIcon,
    this.fontSize,
  });

  final String username;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? fallbackIcon;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final diameter = radius * 2;
    final trimmed = username.trim();
    final initial = trimmed.isEmpty ? 'G' : trimmed.substring(0, 1).toUpperCase();
    final bg = backgroundColor ?? p.surfaceElevated;
    final fg = foregroundColor ?? p.textPrimary;
    final url = avatarUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    final fallback = Center(
      child: fallbackIcon != null && !hasImage
          ? Icon(fallbackIcon, size: radius * 1.15, color: fg)
          : Text(
              initial,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: fontSize ?? radius * 0.85,
                height: 1,
              ),
            ),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.border.withValues(alpha: 0.7)),
        ),
        child: ClipOval(
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    fallback,
                    Image.network(
                      url,
                      width: diameter,
                      height: diameter,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ],
                )
              : fallback,
        ),
      ),
    );
  }
}
