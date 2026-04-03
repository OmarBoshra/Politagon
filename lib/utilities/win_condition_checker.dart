import '../models/game_state.dart';
import '../models/position.dart';
import 'score_calculator.dart';

class WinConditionChecker {
  static bool hasMetDecidedThreshold(GameState state) {
    final totalPoints = state.maxNationalPool;
    final totalDecidedPoints = ScoreCalculator.calculateTotalPlayerScore(state);
    return totalDecidedPoints >= (totalPoints * state.decidedThresholdPercentage);
  }

  static GameState checkWin(GameState state, String lastMovePlayerId) {
    if (!state.players.any((p) => p.id == lastMovePlayerId)) return state;
    
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    
    // The conditions for the chair to be unlocked:
    // Enough points have been claimed (based on decidedThresholdPercentage)
    final bool currentlyMeetsCriteria = hasMetDecidedThreshold(state);
    
    // Update the unlock state dynamically. It can relock if criteria are no longer met.
    state = state.copyWith(couldReachCenter: currentlyMeetsCriteria);

    for (var p in state.players) {
      if (p.pos.equals(center)) {
        final otherPlayers = state.players.where((opp) => opp.id != p.id);
        final pScore = ScoreCalculator.calculateScore(state, p.id);
        final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((opp) => ScoreCalculator.calculateScore(state, opp.id)).reduce((a, b) => a > b ? a : b);
        
        // Winner must be at the center, the chair must be unlocked, and they must be the leader.
        if (state.couldReachCenter == true && pScore >= maxOtherScore) {
          return state.copyWith(
            winner: p.name, 
            turn: p.id, 
            couldReachCenter: true
          );
        }
      }
    }
    
    return state;
  }
}
