import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/models/position.dart';
import 'package:politagon/utilities/adjacent_positions.dart';

void main() {
  group('AdjacentPositions', () {
    test('should return 4 adjacent positions for center position in 5x5 grid', () {
      final pos = Position(2, 2);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 4);
      expect(adjacent.any((p) => p.x == 1 && p.y == 2), true); // up
      expect(adjacent.any((p) => p.x == 3 && p.y == 2), true); // down
      expect(adjacent.any((p) => p.x == 2 && p.y == 1), true); // left
      expect(adjacent.any((p) => p.x == 2 && p.y == 3), true); // right
    });

    test('should return 2 adjacent positions for top-left corner', () {
      final pos = Position(0, 0);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 2);
      expect(adjacent.any((p) => p.x == 1 && p.y == 0), true); // down
      expect(adjacent.any((p) => p.x == 0 && p.y == 1), true); // right
    });

    test('should return 2 adjacent positions for top-right corner', () {
      final pos = Position(0, 4);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 2);
      expect(adjacent.any((p) => p.x == 1 && p.y == 4), true); // down
      expect(adjacent.any((p) => p.x == 0 && p.y == 3), true); // left
    });

    test('should return 2 adjacent positions for bottom-left corner', () {
      final pos = Position(4, 0);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 2);
      expect(adjacent.any((p) => p.x == 3 && p.y == 0), true); // up
      expect(adjacent.any((p) => p.x == 4 && p.y == 1), true); // right
    });

    test('should return 2 adjacent positions for bottom-right corner', () {
      final pos = Position(4, 4);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 2);
      expect(adjacent.any((p) => p.x == 3 && p.y == 4), true); // up
      expect(adjacent.any((p) => p.x == 4 && p.y == 3), true); // left
    });

    test('should return 3 adjacent positions for top edge (not corner)', () {
      final pos = Position(0, 2);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 3);
      expect(adjacent.any((p) => p.x == 1 && p.y == 2), true); // down
      expect(adjacent.any((p) => p.x == 0 && p.y == 1), true); // left
      expect(adjacent.any((p) => p.x == 0 && p.y == 3), true); // right
    });

    test('should return 3 adjacent positions for bottom edge (not corner)', () {
      final pos = Position(4, 2);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 3);
      expect(adjacent.any((p) => p.x == 3 && p.y == 2), true); // up
      expect(adjacent.any((p) => p.x == 4 && p.y == 1), true); // left
      expect(adjacent.any((p) => p.x == 4 && p.y == 3), true); // right
    });

    test('should return 3 adjacent positions for left edge (not corner)', () {
      final pos = Position(2, 0);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 3);
      expect(adjacent.any((p) => p.x == 1 && p.y == 0), true); // up
      expect(adjacent.any((p) => p.x == 3 && p.y == 0), true); // down
      expect(adjacent.any((p) => p.x == 2 && p.y == 1), true); // right
    });

    test('should return 3 adjacent positions for right edge (not corner)', () {
      final pos = Position(2, 4);
      final adjacent = AdjacentPositions.get(pos, 5, 5);
      
      expect(adjacent.length, 3);
      expect(adjacent.any((p) => p.x == 1 && p.y == 4), true); // up
      expect(adjacent.any((p) => p.x == 3 && p.y == 4), true); // down
      expect(adjacent.any((p) => p.x == 2 && p.y == 3), true); // left
    });

    test('should work with different grid sizes - 3x3', () {
      final pos = Position(1, 1);
      final adjacent = AdjacentPositions.get(pos, 3, 3);
      
      expect(adjacent.length, 4);
      expect(adjacent.any((p) => p.x == 0 && p.y == 1), true); // up
      expect(adjacent.any((p) => p.x == 2 && p.y == 1), true); // down
      expect(adjacent.any((p) => p.x == 1 && p.y == 0), true); // left
      expect(adjacent.any((p) => p.x == 1 && p.y == 2), true); // right
    });

    test('should work with rectangular grids - 3x5', () {
      final pos = Position(1, 2);
      final adjacent = AdjacentPositions.get(pos, 3, 5);
      
      expect(adjacent.length, 4);
      expect(adjacent.any((p) => p.x == 0 && p.y == 2), true); // up
      expect(adjacent.any((p) => p.x == 2 && p.y == 2), true); // down
      expect(adjacent.any((p) => p.x == 1 && p.y == 1), true); // left
      expect(adjacent.any((p) => p.x == 1 && p.y == 3), true); // right
    });

    test('should handle single cell grid', () {
      final pos = Position(0, 0);
      final adjacent = AdjacentPositions.get(pos, 1, 1);
      
      expect(adjacent.length, 0);
    });

    test('should handle 1x2 grid', () {
      final pos = Position(0, 0);
      final adjacent = AdjacentPositions.get(pos, 1, 2);
      
      expect(adjacent.length, 1);
      expect(adjacent.any((p) => p.x == 0 && p.y == 1), true); // right
    });

    test('should handle 2x1 grid', () {
      final pos = Position(0, 0);
      final adjacent = AdjacentPositions.get(pos, 2, 1);
      
      expect(adjacent.length, 1);
      expect(adjacent.any((p) => p.x == 1 && p.y == 0), true); // down
    });
  });
}