import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/models/position.dart';

void main() {
  group('Position', () {
    test('should create position with correct coordinates', () {
      final position = Position(2, 3);
      expect(position.x, 2);
      expect(position.y, 3);
    });

    test('equals should return true for same coordinates', () {
      final pos1 = Position(1, 2);
      final pos2 = Position(1, 2);
      expect(pos1.equals(pos2), true);
    });

    test('equals should return false for different x coordinates', () {
      final pos1 = Position(1, 2);
      final pos2 = Position(2, 2);
      expect(pos1.equals(pos2), false);
    });

    test('equals should return false for different y coordinates', () {
      final pos1 = Position(1, 2);
      final pos2 = Position(1, 3);
      expect(pos1.equals(pos2), false);
    });

    test('equals should return false for both different coordinates', () {
      final pos1 = Position(1, 2);
      final pos2 = Position(3, 4);
      expect(pos1.equals(pos2), false);
    });

    test('equals should handle zero coordinates', () {
      final pos1 = Position(0, 0);
      final pos2 = Position(0, 0);
      expect(pos1.equals(pos2), true);
    });

    test('equals should handle negative coordinates', () {
      final pos1 = Position(-1, -2);
      final pos2 = Position(-1, -2);
      expect(pos1.equals(pos2), true);
    });
  });
}