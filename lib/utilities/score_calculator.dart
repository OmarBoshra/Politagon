import '../models/game_state.dart';
import 'dart:math';

class ScoreCalculator {
  static int calculateScore(GameState state, String playerId) {
    int score = 0;
    for (var row in state.gridOwnership) {
      for (var cell in row) {
        score += cell[playerId] ?? 0;
      }
    }
    return score;
  }

  static int calculateTotalScore(GameState state) {
    int total = 0;
    for (var row in state.gridOwnership) {
      for (var cell in row) {
        total += cell.values.fold(0, (sum, val) => sum + val);
      }
    }
    return total;
  }

  static int calculateTotalPlayerScore(GameState state) {
    int total = 0;
    for (var row in state.gridOwnership) {
      for (var cell in row) {
        for (var entry in cell.entries) {
          if (entry.key != 'undecided') {
            total += entry.value;
          }
        }
      }
    }
    return total;
  }

  static bool isLeadingOrTied(GameState state, String playerId) {
    final playerScore = calculateScore(state, playerId);
    final otherPlayers = state.players.where((p) => p.id != playerId);
    if (otherPlayers.isEmpty) return true;
    
    final maxOtherScore = otherPlayers
        .map((p) => calculateScore(state, p.id))
        .reduce(max);
        
    return playerScore >= maxOtherScore;
  }

  static Map<int, int> calculateScoreByLevel(GameState state, String playerId) {
    final centerIdx = state.gridSize ~/ 2;
    final pointsByLevel = <int, int>{};
    
    for (int i = 0; i < state.gridSize; i++) {
      for (int j = 0; j < state.gridSize; j++) {
        final points = state.gridOwnership[i][j][playerId] ?? 0;
        if (points > 0) {
          final distance = (i - centerIdx).abs() + (j - centerIdx).abs();
          pointsByLevel[distance] = (pointsByLevel[distance] ?? 0) + points;
        }
      }
    }
    
    return pointsByLevel;
  }
}
