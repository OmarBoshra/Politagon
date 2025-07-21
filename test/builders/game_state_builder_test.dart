import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/builders/game_state_builder.dart';
import 'package:politagon/bloc/grid_game_event.dart';
import 'package:politagon/models/game_state.dart';
import 'package:politagon/models/position.dart';

void main() {
  group('GameStateBuilder', () {
    late GameState initialState;
    late List<List<int>> testGrid;

    setUp(() {
      testGrid = [
        [5, 10, 15, 20, 25],
        [4, 8, 12, 16, 24],
        [3, 6, 9, 18, 21],
        [2, 4, 6, 8, 10],
        [1, 2, 3, 4, 5]
      ];
      
      initialState = GameState(
        grid: testGrid,
        userPos: Position(2, 2),
        ai1Pos: Position(1, 1),
        ai2Pos: Position(3, 3),
        scores: {'user': 20, 'ai1': 30, 'ai2': 40},
        turn: 'user',
        winner: null,
        couldReachCenter: false,
      );
    });

    group('onCellTapGameState', () {
      test('should handle UserMoveEvent and update user position and score', () {
        final event = UserMoveEvent(Position(2, 3));
        final newState = GameStateBuilder.onCellTapGameState(initialState, event, Position(2, 3));
        
        expect(newState.userPos.x, 2);
        expect(newState.userPos.y, 3);
        expect(newState.scores['user'], 20 + testGrid[2][3]); // 20 + 18 = 38
        expect(newState.turn, 'ai1');
        expect(newState.ai1Pos, initialState.ai1Pos); // unchanged
        expect(newState.ai2Pos, initialState.ai2Pos); // unchanged
      });

      test('should handle Ai1MoveEvent and update ai1 position and score', () {
        final stateWithAi1Turn = initialState.copyWith(turn: 'ai1');
        final event = Ai1MoveEvent();
        final newState = GameStateBuilder.onCellTapGameState(stateWithAi1Turn, event, Position(1, 2));
        
        expect(newState.ai1Pos.x, 1);
        expect(newState.ai1Pos.y, 2);
        expect(newState.scores['ai1'], 30 + testGrid[1][2]); // 30 + 12 = 42
        expect(newState.turn, 'ai2');
        expect(newState.userPos, initialState.userPos); // unchanged
        expect(newState.ai2Pos, initialState.ai2Pos); // unchanged
      });

      test('should handle Ai2MoveEvent and update ai2 position and score', () {
        final stateWithAi2Turn = initialState.copyWith(turn: 'ai2');
        final event = Ai2MoveEvent();
        final newState = GameStateBuilder.onCellTapGameState(stateWithAi2Turn, event, Position(3, 2));
        
        expect(newState.ai2Pos.x, 3);
        expect(newState.ai2Pos.y, 2);
        expect(newState.scores['ai2'], 40 + testGrid[3][2]); // 40 + 6 = 46
        expect(newState.turn, 'user');
        expect(newState.userPos, initialState.userPos); // unchanged
        expect(newState.ai1Pos, initialState.ai1Pos); // unchanged
      });

      test('should apply penalty when total score exceeds 100', () {
        final highScoreState = initialState.copyWith(
          scores: {'user': 50, 'ai1': 40, 'ai2': 5}
        );
        final event = UserMoveEvent(Position(0, 4)); // cell value 25
        final newState = GameStateBuilder.onCellTapGameState(highScoreState, event, Position(0, 4));
        
        // Total would be 50 + 25 + 40 + 5 = 120, excess = 20
        // Non-moving players (ai1: 40, ai2: 5) total = 45
        // ai1 penalty: (20 * 40 / 45) = 17.77... = 17
        // ai2 penalty: (20 * 5 / 45) = 2.22... = 2
        // Remaining penalty: 20 - 17 - 2 = 1, goes to ai2 (last player)
        
        expect(newState.scores['user'], 75); // 50 + 25
        expect(newState.scores['ai1'], 23); // 40 - 17
        expect(newState.scores['ai2'], 2); // 5 - 2 - 1
        
        final totalScore = newState.scores.values.reduce((a, b) => a + b);
        expect(totalScore, 100);
      });

      test('should handle penalty when non-moving players have zero points', () {
        final zeroScoreState = initialState.copyWith(
          scores: {'user': 50, 'ai1': 0, 'ai2': 0}
        );
        final event = UserMoveEvent(Position(0, 4)); // cell value 25
        final newState = GameStateBuilder.onCellTapGameState(zeroScoreState, event, Position(0, 4));
        
        // Total would be 75, no penalty needed
        expect(newState.scores['user'], 75);
        expect(newState.scores['ai1'], 0);
        expect(newState.scores['ai2'], 0);
      });

      test('should handle penalty when moving player gets full penalty', () {
        final zeroOthersState = initialState.copyWith(
          scores: {'user': 80, 'ai1': 0, 'ai2': 0}
        );
        final event = UserMoveEvent(Position(0, 4)); // cell value 25
        final newState = GameStateBuilder.onCellTapGameState(zeroOthersState, event, Position(0, 4));
        
        // Total would be 105, excess = 5
        // Since other players have 0, user gets full penalty
        expect(newState.scores['user'], 100); // 80 + 25 - 5
        expect(newState.scores['ai1'], 0);
        expect(newState.scores['ai2'], 0);
      });

      test('should generate new grid after each move', () {
        final event = UserMoveEvent(Position(2, 3));
        final newState = GameStateBuilder.onCellTapGameState(initialState, event, Position(2, 3));
        
        // Grid should be regenerated (different from initial)
        expect(newState.grid.length, 5);
        expect(newState.grid[0].length, 5);
        
        // Sum should still be 100
        final sum = newState.grid.expand((row) => row).reduce((a, b) => a + b);
        expect(sum, 100);
      });

      test('should handle RestartGameEvent', () {
        final event = RestartGameEvent();
        final newState = GameStateBuilder.onCellTapGameState(initialState, event, Position(1, 1));
        
        expect(newState.userPos.x, 1);
        expect(newState.userPos.y, 1);
        expect(newState.scores['user'], 0);
        expect(newState.scores['ai1'], 0);
        expect(newState.scores['ai2'], 0);
        expect(newState.turn, 'ai1');
      });
    });

    group('_getCurrentPlayerKey', () {
      test('should return user for UserMoveEvent', () {
        final event = UserMoveEvent(Position(0, 0));
        final newState = GameStateBuilder.onCellTapGameState(initialState, event, Position(0, 0));
        expect(newState.turn, 'ai1'); // Next turn after user
      });

      test('should return ai1 for Ai1MoveEvent', () {
        final stateWithAi1Turn = initialState.copyWith(turn: 'ai1');
        final event = Ai1MoveEvent();
        final newState = GameStateBuilder.onCellTapGameState(stateWithAi1Turn, event, Position(0, 0));
        expect(newState.turn, 'ai2'); // Next turn after ai1
      });

      test('should return ai2 for Ai2MoveEvent', () {
        final stateWithAi2Turn = initialState.copyWith(turn: 'ai2');
        final event = Ai2MoveEvent();
        final newState = GameStateBuilder.onCellTapGameState(stateWithAi2Turn, event, Position(0, 0));
        expect(newState.turn, 'user'); // Next turn after ai2
      });
    });

    group('_getNextTurn', () {
      test('should cycle through turns correctly', () {
        // User -> AI1
        final userEvent = UserMoveEvent(Position(0, 0));
        final afterUser = GameStateBuilder.onCellTapGameState(initialState, userEvent, Position(0, 0));
        expect(afterUser.turn, 'ai1');

        // AI1 -> AI2
        final ai1Event = Ai1MoveEvent();
        final afterAi1 = GameStateBuilder.onCellTapGameState(afterUser, ai1Event, Position(0, 1));
        expect(afterAi1.turn, 'ai2');

        // AI2 -> User
        final ai2Event = Ai2MoveEvent();
        final afterAi2 = GameStateBuilder.onCellTapGameState(afterAi1, ai2Event, Position(0, 2));
        expect(afterAi2.turn, 'user');
      });
    });

    group('_computeNewScores', () {
      test('should handle proportional penalty distribution correctly', () {
        final highScoreState = initialState.copyWith(
          scores: {'user': 30, 'ai1': 60, 'ai2': 10}
        );
        final event = UserMoveEvent(Position(0, 0)); // Assuming cell value causes excess
        
        // This tests the internal penalty calculation logic
        // The exact values depend on the cell value at position (0,0)
        final newState = GameStateBuilder.onCellTapGameState(highScoreState, event, Position(0, 0));
        
        final totalScore = newState.scores.values.reduce((a, b) => a + b);
        expect(totalScore, lessThanOrEqualTo(100));
      });

      test('should not apply penalty when total is exactly 100', () {
        final exactState = initialState.copyWith(
          scores: {'user': 30, 'ai1': 40, 'ai2': 25}
        );
        final event = UserMoveEvent(Position(4, 4)); // cell value 5
        final newState = GameStateBuilder.onCellTapGameState(exactState, event, Position(4, 4));
        
        expect(newState.scores['user'], 35); // 30 + 5
        expect(newState.scores['ai1'], 40); // unchanged
        expect(newState.scores['ai2'], 25); // unchanged
        
        final totalScore = newState.scores.values.reduce((a, b) => a + b);
        expect(totalScore, 100);
      });

      test('should handle case where penalty exceeds player score', () {
        final state = initialState.copyWith(
          scores: {'user': 95, 'ai1': 2, 'ai2': 1}
        );
        final event = UserMoveEvent(Position(0, 4)); // cell value 25
        final newState = GameStateBuilder.onCellTapGameState(state, event, Position(0, 4));
        
        // Total would be 123, excess = 23
        // ai1 and ai2 can only lose their current scores (2 + 1 = 3)
        // Remaining penalty (20) goes to user
        expect(newState.scores['ai1'], 0);
        expect(newState.scores['ai2'], 0);
        expect(newState.scores['user'], 100); // 95 + 25 - 20
      });
    });
  });
}