import 'dart:math';
import '../models/position.dart';

class GridManager {
  static List<List<String?>> updateMajorityFlags(List<List<Map<String, int>>> gridOwnership, int gridSize) {
    return List.generate(gridSize, (i) => List.generate(gridSize, (j) {
      final cell = gridOwnership[i][j];
      if (cell.isEmpty) return null;
      String? majorityOwner;
      int maxPoints = -1;
      cell.forEach((owner, points) {
        if (points > maxPoints) {
          maxPoints = points;
          majorityOwner = owner;
        } else if (points == maxPoints) {
          majorityOwner = null;
        }
      });
      return majorityOwner;
    }));
  }

  static List<List<Map<String, int>>> shuffleOwnershipWithinLevels(List<List<Map<String, int>>> gridOwnership, int gridSize) {
    final random = Random();
    final centerIdx = gridSize ~/ 2;
    final posByLevel = <int, List<Position>>{};
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final dist = (i - centerIdx).abs() + (j - centerIdx).abs();
        posByLevel.putIfAbsent(dist, () => []).add(Position(i, j));
      }
    }
    
    final newGridOwnership = List.generate(gridSize, (i) => List.generate(gridSize, (j) => <String, int>{}));
    for (var entry in posByLevel.entries) {
      final positions = entry.value;
      final data = positions.map((p) => Map<String, int>.from(gridOwnership[p.x][p.y])).toList()..shuffle(random);
      for (int i = 0; i < positions.length; i++) {
        newGridOwnership[positions[i].x][positions[i].y] = data[i];
      }
    }
    return newGridOwnership;
  }

  static List<List<int>> regenerateGridFromOwnership(List<List<Map<String, int>>> gridOwnership, int gridSize) {
    return List.generate(gridSize, (i) => List.generate(gridSize, (j) =>
      gridOwnership[i][j].values.fold(0, (sum, val) => sum + val)
    ));
  }

  static List<List<Map<String, int>>> convertPlayerPointsToUndecided(
    List<List<Map<String, int>>> gridOwnership,
    String playerId,
  ) {
    final newGridOwnership = List.generate(gridOwnership.length, (i) =>
      List.generate(gridOwnership[i].length, (j) => Map<String, int>.from(gridOwnership[i][j]))
    );
    for (int i = 0; i < newGridOwnership.length; i++) {
      for (int j = 0; j < newGridOwnership[i].length; j++) {
        final cell = newGridOwnership[i][j];
        if (cell.containsKey(playerId)) {
          final playerPoints = cell[playerId]!;
          cell.remove(playerId);
          cell['undecided'] = (cell['undecided'] ?? 0) + playerPoints;
        }
      }
    }
    return newGridOwnership;
  }
}
