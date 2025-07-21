import '../bloc/grid_game_event.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../utilities/grid_generator.dart';

class GameStateBuilder {
  static GameState onCellTapGameState(GameState state, GridGameEvent event, Position pos) {
    if (event is UserMoveEvent || event is Ai1MoveEvent || event is Ai2MoveEvent) {
      final cellValue = state.grid[pos.x][pos.y];
      final currentPlayer = _getCurrentPlayerKey(event);
      final newScores = _computeNewScores(
        scores: state.scores,
        currentPlayer: currentPlayer,
        cellValue: cellValue,
      );

      final nextTurn = _getNextTurn(currentPlayer);

      return _buildNewState(
        state: state,
        pos: pos,
        player: currentPlayer,
        newScores: newScores,
        nextTurn: nextTurn,
      );
    } else {
      return _buildResetState(state, pos);
    }
  }

  static String _getCurrentPlayerKey(GridGameEvent event) {
    if (event is UserMoveEvent) return 'user';
    if (event is Ai1MoveEvent) return 'ai1';
    if (event is Ai2MoveEvent) return 'ai2';
    throw UnimplementedError('Unhandled event type');
  }

  static String _getNextTurn(String currentPlayer) {
    switch (currentPlayer) {
      case 'user': return 'ai1';
      case 'ai1': return 'ai2';
      case 'ai2': return 'user';
      default: throw UnimplementedError('Unhandled player: $currentPlayer');
    }
  }

  static Map<String, int> _computeNewScores({
    required Map<String, int> scores,
    required String currentPlayer,
    required int cellValue,
  }) {
    final newScores = Map<String, int>.from(scores);
    final currentPlayerOldScore = scores[currentPlayer]!;

    // Calculate new score for current player
    final currentPlayerNewScore = currentPlayerOldScore + cellValue;
    newScores[currentPlayer] = currentPlayerNewScore;

    // Calculate total score including the new move
    final totalScore = newScores.values.reduce((a, b) => a + b);

    // Apply penalty only if total exceeds 100
    if (totalScore > 100) {
      final excess = totalScore - 100;

      // Identify non-moving players
      final nonMovingPlayers = scores.keys.where((p) => p != currentPlayer).toList();

      // Calculate total score of non-moving players
      final nonMovingTotal = nonMovingPlayers.fold(0, (sum, player) => sum + scores[player]!);

      if (nonMovingTotal > 0) {
        // Distribute penalty proportionally to non-moving players
        int distributed = 0;
        for (int i = 0; i < nonMovingPlayers.length; i++) {
          final player = nonMovingPlayers[i];
          final playerScore = scores[player]!;

          // Calculate proportional penalty (percentage of total non-moving score)
          int penalty = (excess * playerScore ~/ nonMovingTotal);

          // If last player, assign remaining penalty to ensure full distribution
          if (i == nonMovingPlayers.length - 1) {
            penalty = excess - distributed;
          }

          // Only subtract if player has points to lose
          if (playerScore > 0) {
            final actualPenalty = penalty.clamp(0, playerScore);
            newScores[player] = playerScore - actualPenalty;
            distributed += actualPenalty;
          }
        }

        // Handle any remaining penalty (if non-moving players couldn't absorb all)
        final remainingPenalty = excess - distributed;
        if (remainingPenalty > 0) {
          newScores[currentPlayer] = currentPlayerNewScore - remainingPenalty;
        }
      } else {
        // If non-moving players have 0 points, apply full penalty to moving player
        newScores[currentPlayer] = currentPlayerNewScore - excess;
      }
    }

    return newScores;
  }

  static GameState _buildNewState({
    required GameState state,
    required Position pos,
    required String player,
    required Map<String, int> newScores,
    required String nextTurn,
  }) {
    return state.copyWith(
      userPos: player == 'user' ? pos : state.userPos,
      ai1Pos: player == 'ai1' ? pos : state.ai1Pos,
      ai2Pos: player == 'ai2' ? pos : state.ai2Pos,
      scores: newScores,
      grid: GridGenerator.generate(5, 5),
      turn: nextTurn,
    );
  }

  static GameState _buildResetState(GameState state, Position pos) {
    return state.copyWith(
      userPos: pos,
      scores: {'user': 0, 'ai1': 0, 'ai2': 0},
      grid: GridGenerator.generate(5, 5),
      turn: 'ai1',
    );
  }
}