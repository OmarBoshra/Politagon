import '../../models/game_player_state.dart';
import '../../models/game_state.dart';
import '../../models/position.dart';
import '../ai_strategy.dart';
import '../score_calculator.dart';
import 'dart:developer' as dev;

class SocialistStrategy implements AiStrategy {
  @override
  Position getNextMove(GamePlayerState player, GameState state, List<Position> validMoves) {
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    final maxDist = centerIdx * 2;

    dev.log('Socialist: center=$centerIdx, couldReachCenter=${state.couldReachCenter}, validMoves=${validMoves.length}');

    final result = validMoves.reduce((a, b) {
      final easeA = _calculateEase(player, a, state);
      final easeB = _calculateEase(player, b, state);
      
      double scoreA = easeA;
      double scoreB = easeB;

      if (state.couldReachCenter == true) {
        final distA = (a.x - center.x).abs() + (a.y - center.y).abs();
        final distB = (b.x - center.x).abs() + (b.y - center.y).abs();
        scoreA += (maxDist - distA) * 2;
        scoreB += (maxDist - distB) * 2;
      }
      return scoreA > scoreB ? a : b;
    });
    
    dev.log('Socialist chose: ${result.x},${result.y}');
    return result;
  }

  double _calculateEase(GamePlayerState player, Position pos, GameState state) {
    final cell = state.gridOwnership[pos.x][pos.y];
    double totalEase = (cell['undecided'] ?? 0) * 1.5;
    
    final opponentIds = state.players.where((p) => p.id != player.id).map((p) => p.id).toList();
    opponentIds.sort((a, b) => ScoreCalculator.calculateScore(state, a).compareTo(ScoreCalculator.calculateScore(state, b)));
    
    for (int i = 0; i < opponentIds.length; i++) {
      final oppId = opponentIds[i];
      final points = cell[oppId] ?? 0;
      final multiplier = 1.0 - (i / opponentIds.length) * 0.5;
      totalEase += points * multiplier;
    }
    return totalEase;
  }
}
