import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/models/game_state.dart';
import 'package:politagon/models/position.dart';

void main() {
  group('GameState', () {
    late GameState gameState;
    late List<List<int>> testGrid;
    late Position userPos;
    late Position ai1Pos;
    late Position ai2Pos;
    late Map<String, int> scores;

    setUp(() {
      testGrid = [
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9, 10],
        [11, 12, 13, 14, 15],
        [16, 17, 18, 19, 20],
        [21, 22, 23, 24, 25]
      ];
      userPos = Position(0, 0);
      ai1Pos = Position(1, 1);
      ai2Pos = Position(2, 2);
      scores = {'user': 10, 'ai1': 20, 'ai2': 30};

      gameState = GameState(
        grid: testGrid,
        userPos: userPos,
        ai1Pos: ai1Pos,
        ai2Pos: ai2Pos,
        scores: scores,
        turn: 'user',
        winner: null,
        couldReachCenter: false,
      );
    });

    test('should create GameState with all required properties', () {
      expect(gameState.grid, testGrid);
      expect(gameState.userPos, userPos);
      expect(gameState.ai1Pos, ai1Pos);
      expect(gameState.ai2Pos, ai2Pos);
      expect(gameState.scores, scores);
      expect(gameState.turn, 'user');
      expect(gameState.winner, null);
      expect(gameState.couldReachCenter, false);
    });

    test('copyWith should create new instance with updated grid', () {
      final newGrid = [[1, 2], [3, 4]];
      final newState = gameState.copyWith(grid: newGrid);
      
      expect(newState.grid, newGrid);
      expect(newState.userPos, userPos);
      expect(newState.ai1Pos, ai1Pos);
      expect(newState.ai2Pos, ai2Pos);
      expect(newState.scores, scores);
      expect(newState.turn, 'user');
    });

    test('copyWith should create new instance with updated userPos', () {
      final newUserPos = Position(3, 3);
      final newState = gameState.copyWith(userPos: newUserPos);
      
      expect(newState.userPos, newUserPos);
      expect(newState.grid, testGrid);
      expect(newState.ai1Pos, ai1Pos);
      expect(newState.ai2Pos, ai2Pos);
    });

    test('copyWith should create new instance with updated ai1Pos', () {
      final newAi1Pos = Position(4, 4);
      final newState = gameState.copyWith(ai1Pos: newAi1Pos);
      
      expect(newState.ai1Pos, newAi1Pos);
      expect(newState.userPos, userPos);
      expect(newState.ai2Pos, ai2Pos);
    });

    test('copyWith should create new instance with updated ai2Pos', () {
      final newAi2Pos = Position(1, 4);
      final newState = gameState.copyWith(ai2Pos: newAi2Pos);
      
      expect(newState.ai2Pos, newAi2Pos);
      expect(newState.userPos, userPos);
      expect(newState.ai1Pos, ai1Pos);
    });

    test('copyWith should create new instance with updated scores', () {
      final newScores = {'user': 50, 'ai1': 60, 'ai2': 70};
      final newState = gameState.copyWith(scores: newScores);
      
      expect(newState.scores, newScores);
      expect(newState.turn, 'user');
    });

    test('copyWith should create new instance with updated turn', () {
      final newState = gameState.copyWith(turn: 'ai1');
      
      expect(newState.turn, 'ai1');
      expect(newState.scores, scores);
    });

    test('copyWith should create new instance with updated winner', () {
      final newState = gameState.copyWith(winner: 'user');
      
      expect(newState.winner, 'user');
      expect(newState.turn, 'user');
    });

    test('copyWith should create new instance with updated couldReachCenter', () {
      final newState = gameState.copyWith(couldReachCenter: true);
      
      expect(newState.couldReachCenter, true);
      expect(newState.winner, null);
    });

    test('copyWith should preserve original values when no parameters provided', () {
      final newState = gameState.copyWith();
      
      expect(newState.grid, testGrid);
      expect(newState.userPos, userPos);
      expect(newState.ai1Pos, ai1Pos);
      expect(newState.ai2Pos, ai2Pos);
      expect(newState.scores, scores);
      expect(newState.turn, 'user');
      expect(newState.winner, null);
      expect(newState.couldReachCenter, false);
    });

    test('initial should create GameState with default values', () {
      final initialState = GameState.initial();
      
      expect(initialState.grid.length, 5);
      expect(initialState.grid[0].length, 5);
      expect(initialState.userPos.x, 2);
      expect(initialState.userPos.y, 2);
      expect(initialState.ai1Pos.x, 2);
      expect(initialState.ai1Pos.y, 2);
      expect(initialState.ai2Pos.x, 2);
      expect(initialState.ai2Pos.y, 2);
      expect(initialState.scores['user'], 0);
      expect(initialState.scores['ai1'], 0);
      expect(initialState.scores['ai2'], 0);
      expect(initialState.turn, 'user');
      expect(initialState.winner, null);
      expect(initialState.couldReachCenter, false);
    });

    test('initial should generate grid with sum of 100', () {
      final initialState = GameState.initial();
      final sum = initialState.grid.expand((row) => row).reduce((a, b) => a + b);
      expect(sum, 100);
    });
  });
}