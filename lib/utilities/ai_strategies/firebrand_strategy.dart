import 'dart:math';
import '../../models/game_player_state.dart';
import '../../models/game_state.dart';
import '../../models/position.dart';
import '../ai_strategy.dart';

class FirebrandStrategy implements AiStrategy {
  @override
  Position getNextMove(GamePlayerState player, GameState state, List<Position> validMoves) {
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    
    if (state.couldReachCenter == true) {
      final weights = validMoves.map((pos) {
        final dist = (pos.x - center.x).abs() + (pos.y - center.y).abs();
        return 1.0 / (dist + 1);
      }).toList();
      final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);
      var randomVal = Random().nextDouble() * totalWeight;
      for (int i = 0; i < weights.length; i++) {
        randomVal -= weights[i];
        if (randomVal <= 0) return validMoves[i];
      }
    }
    return validMoves[Random().nextInt(validMoves.length)];
  }
}
