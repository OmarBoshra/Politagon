import '../bloc/grid_game_event.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../utilities/score_calculator.dart';
import '../utilities/capture_logic.dart';
import '../utilities/grid_manager.dart';
import '../utilities/stat_growth_logic.dart';

class GameStateBuilder {
  static GameState onCellTapGameState(GameState state, GridGameEvent event, Position pos) {
    String? playerId;
    if (event is UserMoveEvent) playerId = event.playerId;
    if (event is AiMoveEvent) playerId = event.playerId;

    if (playerId == null) return state;

    final playerIndex = state.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) return state;
    final currentPlayer = state.players[playerIndex];

    final cellValue = state.grid[pos.x][pos.y];
    final captureRate = CaptureLogic.calculateCaptureRate(currentPlayer, pos, state.gridSize);
    final pointsToCapture = (cellValue * captureRate).ceil();

    final captureResult = CaptureLogic.captureOwnership(
      state: state,
      pos: pos,
      playerId: playerId,
      pointsToCapture: pointsToCapture,
    );
    
    var newGridOwnership = captureResult.gridOwnership;
    final actualCaptured = captureResult.actualCaptured;

    final centerIdx = state.gridSize ~/ 2;
    final newDistance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final sameClass = newDistance == currentPlayer.lastDistance;
    final newTurnsInClass = sameClass ? (currentPlayer.turnsInCurrentClass + 1) : 1;

    final (newInfluence, newPopularity) = StatGrowthLogic.calculateNewStats(
      state: state,
      player: currentPlayer,
      pos: pos,
      actualCaptured: actualCaptured,
      currentScore: ScoreCalculator.calculateScore(state, playerId),
    );

    newGridOwnership = GridManager.shuffleOwnershipWithinLevels(newGridOwnership, state.gridSize);
    final newGridMajority = GridManager.updateMajorityFlags(newGridOwnership, state.gridSize);
    final newGrid = GridManager.regenerateGridFromOwnership(newGridOwnership, state.gridSize);

    final newPlayers = state.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(
          pos: pos, 
          influence: newInfluence, 
          popularity: newPopularity,
          lastDistance: newDistance,
          turnsInCurrentClass: newTurnsInClass,
        );
      }
      return p;
    }).toList();

    return state.copyWith(
      players: newPlayers,
      grid: newGrid,
      gridOwnership: newGridOwnership,
      gridMajority: newGridMajority,
      turn: _getNextTurn(newPlayers, playerId),
    );
  }

  static String _getNextTurn(List<GamePlayerState> players, String currentPlayerId) {
    final currentIndex = players.indexWhere((p) => p.id == currentPlayerId);
    if (currentIndex == -1) return players.first.id;
    return players[(currentIndex + 1) % players.length].id;
  }
}
