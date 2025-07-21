import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/utilities/commons.dart';

void main() {
  group('sumWithFold', () {
    test('should return 0 for empty list', () {
      expect(sumWithFold([]), 0);
    });

    test('should return single element for list with one element', () {
      expect(sumWithFold([5]), 5);
    });

    test('should return correct sum for positive numbers', () {
      expect(sumWithFold([1, 2, 3, 4, 5]), 15);
    });

    test('should return correct sum for negative numbers', () {
      expect(sumWithFold([-1, -2, -3]), -6);
    });

    test('should return correct sum for mixed positive and negative numbers', () {
      expect(sumWithFold([10, -5, 3, -2]), 6);
    });

    test('should return 0 for list with zeros', () {
      expect(sumWithFold([0, 0, 0]), 0);
    });

    test('should handle large numbers', () {
      expect(sumWithFold([1000000, 2000000, 3000000]), 6000000);
    });

    test('should handle list with duplicate values', () {
      expect(sumWithFold([5, 5, 5, 5]), 20);
    });

    test('should handle single zero', () {
      expect(sumWithFold([0]), 0);
    });

    test('should handle mixed zeros and positive numbers', () {
      expect(sumWithFold([0, 5, 0, 10, 0]), 15);
    });
  });
}