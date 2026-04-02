import '../../models/game_player_state.dart';
import '../../models/game_state.dart';
import '../../models/position.dart';
import '../ai_strategy.dart';
import '../ai_strategy_utils.dart';

class TechnocratStrategy implements AiStrategy {
  @override
  Position getNextMove(GamePlayerState player, GameState state, List<Position> validMoves) {
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    final maxDist = centerIdx * 2;

    return validMoves.reduce((a, b) {
      final gainA = AiStrategyUtils.calculateExpectedGain(player, a, state);
      final gainB = AiStrategyUtils.calculateExpectedGain(player, b, state);
      
      double scoreA = gainA;
      double scoreB = gainB;

      if (state.couldReachCenter == true) {
        final distA = (a.x - center.x).abs() + (a.y - center.y).abs();
        final distB = (b.x - center.x).abs() + (b.y - center.y).abs();
        scoreA += (maxDist - distA) * 2;
        scoreB += (maxDist - distB) * 2;
      }
      return scoreA > scoreB ? a : b;
    });
  }
}
