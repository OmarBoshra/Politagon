import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/game_player_state.dart';
import 'grid_game.dart';

class PlayerIcon extends StatelessWidget {
  final GamePlayerState player;
  final double size;
  final bool isCurrentTurn;
  final Animation<double>? glowAnimation;

  const PlayerIcon({
    super.key,
    required this.player,
    required this.size,
    this.isCurrentTurn = false,
    this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final color = GridGame.getGlobalPlayerColor(player);
    final hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    final svgString = '<svg viewBox="0 0 24 24"><path fill="#$hex" d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>';
    
    Widget icon = SvgPicture.string(svgString, width: size, height: size);

    if (isCurrentTurn && glowAnimation != null) {
      return AnimatedBuilder(
        animation: glowAnimation!,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15 + (glowAnimation!.value * 0.15)),
                blurRadius: 4 + (glowAnimation!.value * 4),
                spreadRadius: 1 + (glowAnimation!.value * 2),
              )
            ],
          ),
          child: icon,
        ),
      );
    }
    return icon;
  }
}
