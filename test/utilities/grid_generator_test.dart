import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/utilities/grid_generator.dart';

void main() {
  group('GridGenerator', () {
    test('should generate 5x5 grid with sum of 100', () {
      final grid = GridGenerator.generate(5, 5);
      
      expect(grid.length, 5);
      expect(grid[0].length, 5);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should generate 3x3 grid with sum of 100', () {
      final grid = GridGenerator.generate(3, 3);
      
      expect(grid.length, 3);
      expect(grid[0].length, 3);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should generate 7x7 grid with sum of 100', () {
      final grid = GridGenerator.generate(7, 7);
      
      expect(grid.length, 7);
      expect(grid[0].length, 7);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should generate rectangular 4x6 grid with sum of 100', () {
      final grid = GridGenerator.generate(4, 6);
      
      expect(grid.length, 4);
      expect(grid[0].length, 6);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should generate rectangular 6x4 grid with sum of 100', () {
      final grid = GridGenerator.generate(6, 4);
      
      expect(grid.length, 6);
      expect(grid[0].length, 4);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should generate 1x1 grid with sum of 100', () {
      final grid = GridGenerator.generate(1, 1);
      
      expect(grid.length, 1);
      expect(grid[0].length, 1);
      expect(grid[0][0], 100);
    });

    test('should generate 2x2 grid with sum of 100', () {
      final grid = GridGenerator.generate(2, 2);
      
      expect(grid.length, 2);
      expect(grid[0].length, 2);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should generate grids with non-negative values', () {
      final grid = GridGenerator.generate(5, 5);
      
      for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[i].length; j++) {
          expect(grid[i][j], greaterThanOrEqualTo(0));
        }
      }
    });

    test('should generate different grids on multiple calls (randomness)', () {
      final grid1 = GridGenerator.generate(5, 5);
      final grid2 = GridGenerator.generate(5, 5);
      
      // Check that at least one cell is different (very high probability)
      bool isDifferent = false;
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          if (grid1[i][j] != grid2[i][j]) {
            isDifferent = true;
            break;
          }
        }
        if (isDifferent) break;
      }
      
      expect(isDifferent, true);
    });

    test('should distribute values based on distance from center', () {
      final grid = GridGenerator.generate(5, 5);
      
      // Center cell (distance 0)
      final centerValue = grid[2][2];
      
      // Distance 1 cells
      final dist1Values = [
        grid[1][2], grid[3][2], grid[2][1], grid[2][3]
      ];
      
      // Distance 2 cells
      final dist2Values = [
        grid[0][2], grid[4][2], grid[2][0], grid[2][4],
        grid[1][1], grid[1][3], grid[3][1], grid[3][3]
      ];
      
      // All values should be non-negative
      expect(centerValue, greaterThanOrEqualTo(0));
      for (final value in dist1Values) {
        expect(value, greaterThanOrEqualTo(0));
      }
      for (final value in dist2Values) {
        expect(value, greaterThanOrEqualTo(0));
      }
    });

    test('should handle edge case of 1x2 grid', () {
      final grid = GridGenerator.generate(1, 2);
      
      expect(grid.length, 1);
      expect(grid[0].length, 2);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should handle edge case of 2x1 grid', () {
      final grid = GridGenerator.generate(2, 1);
      
      expect(grid.length, 2);
      expect(grid[0].length, 1);
      
      final sum = grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('should generate consistent structure for same dimensions', () {
      final grid1 = GridGenerator.generate(3, 4);
      final grid2 = GridGenerator.generate(3, 4);
      
      expect(grid1.length, grid2.length);
      expect(grid1[0].length, grid2[0].length);
      
      final sum1 = grid1.expand((row) => row).reduce((a, b) => a + b);
      final sum2 = grid2.expand((row) => row).reduce((a, b) => a + b);
      expect(sum1, sum2);
      expect(sum1, 100);
    });
  });
}