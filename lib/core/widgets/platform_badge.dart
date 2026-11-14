import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';

/// Renders the platform SVG icon (`android`, `web`, `windows`, `linux`, `ios`, `macos`).
class PlatformBadge extends StatelessWidget {
  const PlatformBadge({
    super.key,
    required this.platform,
    this.size = 18,
    this.showLabel = false,
  });

  final String platform;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: platform.toUpperCase(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AssetPaths.platformIcon(platform),
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(p.textSecondary, BlendMode.srcIn),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              platform.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
