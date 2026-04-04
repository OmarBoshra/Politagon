import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../bloc/grid_game_bloc.dart';
import '../bloc/grid_game_event.dart';
import 'distribution_stroke_painter.dart';
import 'game_dialogs.dart';

class GridCell extends StatelessWidget {
  final GameState state;
  final Position pos;
  final GamePlayerState currentPlayer;
  final double cellWidth;
  final Animation<double> glowAnimation;

  const GridCell({
    super.key,
    required this.state,
    required this.pos,
    required this.currentPlayer,
    required this.cellWidth,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final centerIdx = state.gridSize ~/ 2;
    final isCenter = pos.x == centerIdx && pos.y == centerIdx;
    final bool isAdjacent = (pos.x - currentPlayer.pos.x).abs() + (pos.y - currentPlayer.pos.y).abs() == 1;
    final bool isTappable = !state.isSpectating && 
                            currentPlayer.type == PlayerType.human && 
                            state.winner == null && 
                            isAdjacent && 
                            (!isCenter || state.couldReachCenter == true);
    
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;

    final palette = GameState.getSocialClassPalette(distance, maxDist);
    final cellColor = palette[0];
    final double fontSize = (cellWidth * 0.3).clamp(10.0, 20.0);

    return GestureDetector(
      onTap: isTappable ? () => context.read<GridGameBloc>().add(UserMoveEvent(currentPlayer.id, pos)) : null,
      onSecondaryTap: () => GameDialogs.showSquareStatus(context, state, pos),
      onLongPress: () => GameDialogs.showSquareStatus(context, state, pos),
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          final showGlow = isCenter && state.couldReachCenter == true;
          return Container(
            margin: const EdgeInsets.all(1.0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cellColor.withOpacity(isTappable ? 0.9 : 0.6),
              border: Border.all(color: Colors.transparent),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: DistributionStrokePainter(
                      state: state, 
                      pos: pos,
                      strokeWidth: isTappable ? 3.0 : 1.5,
                      isActive: isTappable,
                      isCenter: isCenter,
                      showGlow: showGlow,
                      glowValue: glowAnimation.value,
                    ),
                  ),
                ),
                Center(
                  child: isCenter 
                    ? Icon(Icons.chair, color: const Color(0xFFC5A059), size: cellWidth * 0.5) 
                    : Text('${state.grid[pos.x][pos.y]}', 
                        style: TextStyle(
                          fontSize: fontSize, 
                          fontWeight: FontWeight.bold, 
                          color: isTappable ? Colors.white : Colors.white.withOpacity(0.4)
                        )
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
