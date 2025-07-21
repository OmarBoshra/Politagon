import 'dart:math';

class GridGenerator {
  static List<List<int>> generate(int rows, int cols) {
    final centerX = rows ~/ 2;
    final centerY = cols ~/ 2;
    final random = Random();

    // Calculate distances and group cells by distance
    final ringMap = <int, List<List<int>>>{};
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final d = (i - centerX).abs() + (j - centerY).abs();
        ringMap.putIfAbsent(d, () => []);
        ringMap[d]!.add([i, j]);
      }
    }

    // Extract unique distances and sort
    final distances = ringMap.keys.toList()..sort();
    final counts = distances.map((d) => ringMap[d]!.length).toList();

    // Calculate weights and target totals for each distance
    final weights = distances.map((d) => (d + 1) * counts[distances.indexOf(d)]).toList();
    final totalWeight = weights.reduce((a, b) => a + b);
    final targets = weights.map((w) => (w * 100) ~/ totalWeight).toList();

    // Adjust targets to sum to 100
    int currentTotal = targets.reduce((a, b) => a + b);
    int remainder = 100 - currentTotal;
    int index = distances.length - 1; // Start from farthest distance

    while (remainder > 0) {
      targets[index] += 1;
      remainder -= 1;
      index = (index - 1 + distances.length) % distances.length; // Move to next farthest
    }

    // Initialize grid with zeros
    final grid = List.generate(rows, (_) => List.filled(cols, 0));

    // Randomly distribute targets within each distance level
    for (int idx = 0; idx < distances.length; idx++) {
      final d = distances[idx];
      final cells = ringMap[d]!;
      final n = cells.length;
      final total = targets[idx];

      if (n == 0) continue;

      // Distribute total randomly across cells
      final values = List.filled(n, 0);
      for (int i = 0; i < total; i++) {
        values[random.nextInt(n)]++;
      }

      // Assign values to grid cells
      for (int i = 0; i < n; i++) {
        final cell = cells[i];
        grid[cell[0]][cell[1]] = values[i];
      }
    }

    return grid;
  }
}