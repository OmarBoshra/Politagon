import '../../models/game_player_state.dart';
import '../../models/game_state.dart';
import '../../models/position.dart';
import '../ai_strategy.dart';

class PragmatistStrategy implements AiStrategy {
  @override
  Position getNextMove(GamePlayerState player, GameState state, List<Position> validMoves) {
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    
    if (state.couldReachCenter == true) {
      final maxDist = centerIdx * 2;
      return validMoves.reduce((a, b) {
        final valA = state.grid[a.x][a.y];
        final valB = state.grid[b.x][b.y];
        final distA = (a.x - center.x).abs() + (a.y - center.y).abs();
        final distB = (b.x - center.x).abs() + (b.y - center.y).abs();
        final scoreA = (valA * 1.5) + ((maxDist - distA) * 2);
        final scoreB = (valB * 1.5) + ((maxDist - distB) * 2);
        return scoreA > scoreB ? a : b;
      });
    }
    return validMoves.reduce((a, b) => state.grid[a.x][a.y] > state.grid[b.x][b.y] ? a : b);
  }
}
