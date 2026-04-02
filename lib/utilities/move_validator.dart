import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import 'score_calculator.dart';
import 'dart:math';

class MoveValidator {
  static bool isCenter(Position pos, int gridSize) {
    final centerIdx = gridSize ~/ 2;
    return pos.x == centerIdx && pos.y == centerIdx;
  }

  static bool isMoveBlockedByCenter(Position targetPos, GamePlayerState player, GameState state) {
    if (!isCenter(targetPos, state.gridSize)) return false;
    if (state.couldReachCenter != true) return true;
    
    final otherPlayers = state.players.where((p) => p.id != player.id);
    final playerScore = ScoreCalculator.calculateScore(state, player.id);
    final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((p) => ScoreCalculator.calculateScore(state, p.id)).reduce(max);
    
    return playerScore < maxOtherScore;
  }
}
