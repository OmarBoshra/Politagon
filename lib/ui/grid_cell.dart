import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../bloc/grid_game_bloc.dart';
import '../bloc/grid_game_event.dart';
import 'distribution_stroke_painter.dart';
import 'game_dialogs.dart';
import 'grid_game.dart';

class GridCell extends StatelessWidget {
  final Map<String, int> ownership;
  final int cellValue;
  final List<(String id, Color color)> playerInfo;
  final Position pos;
  final Position currentPlayerPos;
  final String currentPlayerId;
  final bool isHumanTurn;
  final bool isSpectating;
  final String? winner;
  final bool couldReachCenter;
  final int gridSize;
  final double cellWidth;
  final Animation<double> glowAnimation;

  const GridCell({
    super.key,
    required this.ownership,
    required this.cellValue,
    required this.playerInfo,
    required this.pos,
    required this.currentPlayerPos,
    required this.currentPlayerId,
    required this.isHumanTurn,
    required this.isSpectating,
    required this.winner,
    required this.couldReachCenter,
    required this.gridSize,
    required this.cellWidth,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final centerIdx = gridSize ~/ 2;
    final isCenter = pos.x == centerIdx && pos.y == centerIdx;
    final bool isAdjacent = (pos.x - currentPlayerPos.x).abs() + (pos.y - currentPlayerPos.y).abs() == 1;
    final bool isTappable = !isSpectating && 
                            isHumanTurn && 
                            winner == null && 
                            isAdjacent && 
                            (!isCenter || couldReachCenter == true);
    
    final double fontSize = (cellWidth * 0.3).clamp(10.0, 20.0);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: isTappable ? () => context.read<GridGameBloc>().add(UserMoveEvent(currentPlayerId, pos)) : null,
        onSecondaryTap: () => _showStatus(context),
        onLongPress: () => _showStatus(context),
        child: Container(
          margin: const EdgeInsets.all(1.0),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.transparent, 
          ),
          child: Stack(
            children: [
              if (isCenter && couldReachCenter == true)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: glowAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: CellGlowPainter(
                          glowValue: glowAnimation.value,
                          color: const Color(0xFFC5A059),
                        ),
                      );
                    },
                  ),
                ),
              Center(
                child: isCenter 
                  ? Icon(Icons.chair, color: const Color(0xFFC5A059), size: cellWidth * 0.5) 
                  : Text('$cellValue', 
                      style: TextStyle(
                        fontSize: fontSize, 
                        fontWeight: FontWeight.bold, 
                        color: isTappable ? Colors.white : Colors.white.withOpacity(0.4)
                      )
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatus(BuildContext context) {
    final state = context.read<GridGameBloc>().state;
    GameDialogs.showSquareStatus(context, state, pos);
  }
}
