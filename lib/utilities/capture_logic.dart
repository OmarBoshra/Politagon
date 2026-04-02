import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import 'score_calculator.dart';

class CaptureLogic {
  static double calculateCaptureRate(GamePlayerState player, Position pos, int gridSize) {
    final centerIdx = gridSize ~/ 2;
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;

    final targetQuality = (maxDist + 1 - distance) / (maxDist + 1).toDouble();
    final extremeQuality = targetQuality * targetQuality;

    final eliteCaptureNeed = extremeQuality;
    final grassrootsCaptureNeed = 1.0 - extremeQuality;

    return (player.influence * eliteCaptureNeed +
            player.popularity * grassrootsCaptureNeed).clamp(0.05, 1.0);
  }

  static ({List<List<Map<String, int>>> gridOwnership, int actualCaptured}) captureOwnership({
    required GameState state,
    required Position pos,
    required String playerId,
    required int pointsToCapture,
  }) {
    final newGridOwnership = List.generate(state.gridOwnership.length, (i) =>
      List.generate(state.gridOwnership[i].length, (j) => Map<String, int>.from(state.gridOwnership[i][j]))
    );

    final cell = newGridOwnership[pos.x][pos.y];
    int remaining = pointsToCapture;
    int totalCaptured = 0;

    final undecided = cell['undecided'] ?? 0;
    if (undecided > 0) {
      final take = remaining.clamp(0, undecided);
      cell['undecided'] = undecided - take;
      cell[playerId] = (cell[playerId] ?? 0) + take;
      remaining -= take;
      totalCaptured += take;
    }

    if (remaining > 0) {
      final opponentIds = state.players.map((p) => p.id).where((id) => id != playerId).toList();
      opponentIds.sort((a, b) => ScoreCalculator.calculateScore(state, a).compareTo(ScoreCalculator.calculateScore(state, b)));

      for (var oppId in opponentIds) {
        if (remaining <= 0) break;
        final oppPoints = cell[oppId] ?? 0;
        if (oppPoints > 0) {
          final take = remaining.clamp(0, oppPoints);
          cell[oppId] = oppPoints - take;
          cell[playerId] = (cell[playerId] ?? 0) + take;
          remaining -= take;
          totalCaptured += take;
        }
      }
    }

    return (gridOwnership: newGridOwnership, actualCaptured: totalCaptured);
  }
}
