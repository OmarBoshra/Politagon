import '../bloc/grid_game_event.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../utilities/grid_generator.dart';

class GameStateBuilder {
  static GameState onCellTapGameState(GameState state, GridGameEvent event, Position pos) {
    String? playerId;
    if (event is UserMoveEvent) playerId = event.playerId;
    if (event is AiMoveEvent) playerId = event.playerId;

    if (playerId != null) {
      final cellValue = state.grid[pos.x][pos.y];
      final playerIndex = state.players.indexWhere((p) => p.id == playerId);
      if (playerIndex == -1) return state;
      final currentPlayer = state.players[playerIndex];

      final centerIdx = state.gridSize ~/ 2;
      final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
      final maxDist = centerIdx * 2; 
      
      final targetQuality = (maxDist + 1 - distance) / (maxDist + 1).toDouble(); 
      final extremeQuality = targetQuality * targetQuality;

      final eliteCaptureNeed = extremeQuality;
      final grassrootsCaptureNeed = 1.0 - extremeQuality;
      
      final captureRate = (currentPlayer.popularity * eliteCaptureNeed + 
                           currentPlayer.influence * grassrootsCaptureNeed).clamp(0.05, 1.0);
      
      final pointsGained = (cellValue * captureRate).ceil();

      // No frustration penalty - stats grow normally even during tax events
      double newInfluence;
      double newPopularity;
      
      if (currentPlayer.score == 0 && pointsGained == 0) {
        newInfluence = currentPlayer.influence;
        newPopularity = currentPlayer.popularity;
      } else {
        const double baseWeight = 1.0; 
        final double currentWeight = currentPlayer.score.toDouble();
        final double totalWeight = currentWeight + pointsGained + baseWeight;
        
        final double infContributionWeight = 0.15 + (0.70 * extremeQuality);
        final double popContributionWeight = 0.15 + (0.70 * (1.0 - extremeQuality));

        final double infWeightedSum = (currentPlayer.influence * currentWeight) + 
                                      (pointsGained * infContributionWeight) + 
                                      (0.1 * baseWeight); 
        newInfluence = (infWeightedSum / totalWeight).clamp(0.05, 1.0);

        final double popWeightedSum = (currentPlayer.popularity * currentWeight) + 
                                      (pointsGained * popContributionWeight) + 
                                      (0.1 * baseWeight);
        newPopularity = (popWeightedSum / totalWeight).clamp(0.05, 1.0);
      }

      var newPlayers = _updatePlayerState(
        players: state.players,
        currentPlayerId: playerId,
        pointsGained: pointsGained,
        gainedDistance: distance,
        newPos: pos,
        newInfluence: newInfluence,
        newPopularity: newPopularity,
      );

      // Apply tax if total score exceeds threshold
      final totalScore = newPlayers.fold(0, (sum, p) => sum + p.score);
      if (totalScore > state.winThreshold) {
        final excess = totalScore - state.winThreshold;

        final nonMovingPlayers = newPlayers.where((p) => p.id != playerId).toList();
        final nonMovingTotal = nonMovingPlayers.fold(0, (sum, player) => sum + player.score);

        if (nonMovingTotal > 0) {
          int distributed = 0;
          newPlayers = newPlayers.map((p) {
            if (p.id == playerId) return p;
            int penalty = (excess * p.score ~/ nonMovingTotal);
            final actualPenalty = penalty.clamp(0, p.score);
            distributed += actualPenalty;
            
            final newVotes = _applyTaxToVotes(p.votesByDistance, actualPenalty);
            return p.copyWith(votesByDistance: newVotes);
          }).toList();

          final remainingPenalty = excess - distributed;
          if (remainingPenalty > 0) {
             newPlayers = newPlayers.map((p) {
               if (p.id == playerId) {
                 final newVotes = _applyTaxToVotes(p.votesByDistance, remainingPenalty);
                 return p.copyWith(votesByDistance: newVotes);
               }
               return p;
             }).toList();
          }
        } else {
          newPlayers = newPlayers.map((p) {
            if (p.id == playerId) {
              final newVotes = _applyTaxToVotes(p.votesByDistance, excess);
              return p.copyWith(votesByDistance: newVotes);
            }
            return p;
          }).toList();
        }
      }

      final nextTurn = _getNextTurn(newPlayers, playerId);

      return state.copyWith(
        players: newPlayers,
        grid: GridGenerator.generate(state.gridSize, state.gridSize, state.maxNationalPool),
        turn: nextTurn,
      );
    }
    return state;
  }

  static String _getNextTurn(List<GamePlayerState> players, String currentPlayerId) {
    final currentIndex = players.indexWhere((p) => p.id == currentPlayerId);
    if (currentIndex == -1) return players.first.id;
    final nextIndex = (currentIndex + 1) % players.length;
    return players[nextIndex].id;
  }

  static List<GamePlayerState> _updatePlayerState({
    required List<GamePlayerState> players,
    required String currentPlayerId,
    required int pointsGained,
    required int gainedDistance,
    required Position newPos,
    required double newInfluence,
    required double newPopularity,
  }) {
    return players.map((p) {
      if (p.id == currentPlayerId) {
        final newVotes = Map<int, int>.from(p.votesByDistance);
        newVotes[gainedDistance] = (newVotes[gainedDistance] ?? 0) + pointsGained;
        return p.copyWith(
          pos: newPos,
          votesByDistance: newVotes,
          influence: newInfluence,
          popularity: newPopularity,
        );
      }
      return p;
    }).toList();
  }

  static Map<int, int> _applyTaxToVotes(Map<int, int> votes, int totalTax) {
    final newVotes = Map<int, int>.from(votes);
    int currentScore = votes.values.fold(0, (s, v) => s + v);
    if (currentScore <= 0) return newVotes;

    int remainingTax = totalTax;
    final distances = votes.keys.toList()..sort();
    
    for (var d in distances) {
      if (remainingTax <= 0) break;
      int v = newVotes[d] ?? 0;
      if (v <= 0) continue;
      
      int tax = (totalTax * v ~/ currentScore).clamp(0, v);
      newVotes[d] = v - tax;
      remainingTax -= tax;
    }
    
    if (remainingTax > 0) {
      for (var d in distances) {
        if (remainingTax <= 0) break;
        int v = newVotes[d] ?? 0;
        int cleanup = remainingTax.clamp(0, v);
        newVotes[d] = v - cleanup;
        remainingTax -= cleanup;
      }
    }
    return newVotes;
  }
}
