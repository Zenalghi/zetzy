import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';

/// Renders the game icon for [game], using the themed SVG pawn (`bP`) for Chess.
class GameTypeIcon extends StatelessWidget {
  const GameTypeIcon({
    super.key,
    required this.game,
    this.size = 24,
    this.color,
  });

  final GameType game;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? IconTheme.of(context).color ?? context.palette.textPrimary;

    if (game == GameType.chess) {
      return SvgPicture.asset(
        AssetPaths.chessPawn,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      );
    }

    return Icon(game.icon, size: size, color: resolvedColor);
  }
}
