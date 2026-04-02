import '../../models/game_player_state.dart';
import '../../models/game_state.dart';
import '../../models/position.dart';
import '../ai_strategy.dart';
import '../ai_strategy_utils.dart';

class VisionaryStrategy implements AiStrategy {
  @override
  Position getNextMove(GamePlayerState player, GameState state, List<Position> validMoves) {
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    
    Position target;
    bool centerUnlocked = state.couldReachCenter == true;

    // Decide whether to find a new target or stick to the current one
    if (player.targetPos == null || 
        player.pos.equals(player.targetPos!) || 
        state.grid[player.targetPos!.x][player.targetPos!.y] == 0 || 
        centerUnlocked) {
      target = _findBestStrategicTarget(player, state, centerUnlocked: centerUnlocked, center: center);
    } else { 
      target = player.targetPos!; 
    }

    // Move towards the chosen target
    return validMoves.reduce((a, b) {
      final distA = (a.x - target.x).abs() + (a.y - target.y).abs();
      final distB = (b.x - target.x).abs() + (b.y - target.y).abs();
      return distA < distB ? a : b;
    });
  }

  Position _findBestStrategicTarget(GamePlayerState player, GameState state, {bool centerUnlocked = false, Position? center}) {
    final centerIdx = state.gridSize ~/ 2;
    final maxDist = centerIdx * 2;
    Position bestPos = Position(0, 0); 
    double bestRegionScore = -1.0;

    for (int i = 0; i < state.gridSize; i++) {
      for (int j = 0; j < state.gridSize; j++) {
        double regionScore = _calculateRegionStrategicValue(player, state, i, j);
        
        final dist = (i - centerIdx).abs() + (j - centerIdx).abs();
        
        // Weighting based on player stats
        if (player.popularity < 0.3) regionScore *= (dist + 1);
        if (player.influence < 0.3) regionScore *= (state.gridSize - dist);
        
        // Rush center if unlocked
        if (centerUnlocked && center != null) {
          final distToCenter = (i - center.x).abs() + (j - center.y).abs();
          regionScore += (maxDist - distToCenter) * 3;
        }
        
        if (regionScore > bestRegionScore) { 
          bestRegionScore = regionScore; 
          bestPos = Position(i, j); 
        }
      }
    }
    return bestPos;
  }

  double _calculateRegionStrategicValue(GamePlayerState player, GameState state, int x, int y) {
    double score = 0;
    // Look at the immediate neighborhood for combined value
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int nx = x + dx; 
        int ny = y + dy;
        if (nx >= 0 && nx < state.gridSize && ny >= 0 && ny < state.gridSize) {
          score += AiStrategyUtils.calculateExpectedGain(player, Position(nx, ny), state);
        }
      }
    }
    return score;
  }
}
