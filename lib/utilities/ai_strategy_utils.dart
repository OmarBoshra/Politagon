import 'dart:math';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';

class AiStrategyUtils {
  static bool isCenter(Position pos, int gridSize) {
    final centerIdx = gridSize ~/ 2;
    return pos.x == centerIdx && pos.y == centerIdx;
  }

  static Position rushCenter(List<Position> validMoves, Position center) {
    if (validMoves.any((m) => m.equals(center))) {
      return center;
    }
    return validMoves.reduce((a, b) {
      final distA = (a.x - center.x).abs() + (a.y - center.y).abs();
      final distB = (b.x - center.x).abs() + (b.y - center.y).abs();
      return distA < distB ? a : b;
    });
  }

  static double calculateExpectedGain(GamePlayerState player, Position pos, GameState state) {
    final cellValue = state.grid[pos.x][pos.y];
    final centerIdx = state.gridSize ~/ 2;
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;
    final targetQuality = (maxDist + 1 - distance) / (maxDist + 1).toDouble();
    final extremeQuality = targetQuality * targetQuality;
    final captureRate = (player.popularity * extremeQuality + player.influence * (1.0 - extremeQuality)).clamp(0.05, 1.0);
    return cellValue * captureRate;
  }

  static Position getRandomMove(List<Position> validMoves) {
    return validMoves[Random().nextInt(validMoves.length)];
  }
}
