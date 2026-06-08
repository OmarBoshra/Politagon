import 'package:flutter/material.dart';
import 'grid_game.dart';
import '../models/game_player_state.dart';

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
    
    // Using a standard Icon with reduced opacity so grid numbers remain visible
    Widget icon = Opacity(
      opacity: 0.7,
      child: Icon(
        Icons.person,
        color: color,
        size: size,
      ),
    );

    if (isCurrentTurn && glowAnimation != null) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: glowAnimation!,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Inner prominent glow layer
                BoxShadow(
                  color: color.withOpacity(0.3 + (glowAnimation!.value * 0.2)),
                  blurRadius: size * 0.3 * (0.8 + glowAnimation!.value * 0.4),
                  spreadRadius: size * 0.1 + (size * 0.15 * glowAnimation!.value),
                ),
                // Outer softer glow layer for depth
                BoxShadow(
                  color: color.withOpacity(0.15 + (glowAnimation!.value * 0.15)),
                  blurRadius: size * 0.6 * (1.0 + glowAnimation!.value * 0.5),
                  spreadRadius: size * 0.05 + (size * 0.1 * glowAnimation!.value),
                ),
              ],
            ),
            child: icon,
          ),
        ),
      );
    }
    return icon;
  }
}
