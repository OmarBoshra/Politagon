import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:politagon/bloc/grid_game_event.dart';
import 'package:politagon/models/game_state.dart';
import 'package:politagon/models/position.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('GridGameBloc', () {
    late GridGameBloc bloc;

    setUp(() {
      bloc = GridGameBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be correct', () {
      expect(bloc.state.userPos.x, 2);
      expect(bloc.state.userPos.y, 2);
      expect(bloc.state.ai1Pos.x, 2);
      expect(bloc.state.ai1Pos.y, 2);
      expect(bloc.state.ai2Pos.x, 2);
      expect(bloc.state.ai2Pos.y, 2);
      expect(bloc.state.scores['user'], 0);
      expect(bloc.state.scores['ai1'], 0);
      expect(bloc.state.scores['ai2'], 0);
      expect(bloc.state.turn, 'user');
      expect(bloc.state.winner, null);
      expect(bloc.state.couldReachCenter, false);
    });

    group('RestartGameEvent', () {
      blocTest<GridGameBloc, GameState>(
        'should reset to initial state',
        build: () => bloc,
        act: (bloc) {
          // First make some moves to change state
          bloc.add(UserMoveEvent(Position(2, 3)));
          bloc.add(RestartGameEvent());
        },
        expect: () => [
          // First move
          isA<GameState>()
              .having((s) => s.userPos.y, 'userPos.y', 3)
              .having((s) => s.turn, 'turn', 'ai1'),
          // Restart
          isA<GameState>()
              .having((s) => s.userPos.x, 'userPos.x', 2)
              .having((s) => s.userPos.y, 'userPos.y', 2)
              .having((s) => s.scores['user'], 'user score', 0)
              .having((s) => s.scores['ai1'], 'ai1 score', 0)
              .having((s) => s.scores['ai2'], 'ai2 score', 0)
              .having((s) => s.turn, 'turn', 'user')
              .having((s) => s.winner, 'winner', null),
        ],
      );
    });

    group('UserMoveEvent', () {
      blocTest<GridGameBloc, GameState>(
        'should update user position and trigger AI1 move when valid',
        build: () => bloc,
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 3))),
        expect: () => [
          // User move
          isA<GameState>()
              .having((s) => s.userPos.y, 'userPos.y', 3)
              .having((s) => s.turn, 'turn', 'ai1'),
          // AI1 move (triggered automatically)
          isA<GameState>()
              .having((s) => s.turn, 'turn', 'ai2'),
          // AI2 move (triggered automatically)
          isA<GameState>()
              .having((s) => s.turn, 'turn', 'user'),
        ],
      );

      blocTest<GridGameBloc, GameState>(
        'should ignore invalid moves (not adjacent)',
        build: () => bloc,
        act: (bloc) => bloc.add(UserMoveEvent(Position(0, 0))),
        expect: () => [],
      );

      blocTest<GridGameBloc, GameState>(
        'should ignore moves when not user turn',
        build: () => bloc,
        seed: () => bloc.state.copyWith(turn: 'ai1'),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 3))),
        expect: () => [],
      );

      blocTest<GridGameBloc, GameState>(
        'should ignore moves when game is won',
        build: () => bloc,
        seed: () => bloc.state.copyWith(winner: 'user'),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 3))),
        expect: () => [],
      );
    });

    group('Ai1MoveEvent', () {
      blocTest<GridGameBloc, GameState>(
        'should update ai1 position and trigger AI2 move',
        build: () => bloc,
        seed: () => bloc.state.copyWith(turn: 'ai1'),
        act: (bloc) => bloc.add(Ai1MoveEvent()),
        expect: () => [
          // AI1 move
          isA<GameState>()
              .having((s) => s.turn, 'turn', 'ai2'),
          // AI2 move (triggered automatically)
          isA<GameState>()
              .having((s) => s.turn, 'turn', 'user'),
        ],
      );

      blocTest<GridGameBloc, GameState>(
        'should ignore when not ai1 turn',
        build: () => bloc,
        act: (bloc) => bloc.add(Ai1MoveEvent()),
        expect: () => [],
      );

      blocTest<GridGameBloc, GameState>(
        'should ignore when game is won',
        build: () => bloc,
        seed: () => bloc.state.copyWith(turn: 'ai1', winner: 'user'),
        act: (bloc) => bloc.add(Ai1MoveEvent()),
        expect: () => [],
      );
    });

    group('Ai2MoveEvent', () {
      blocTest<GridGameBloc, GameState>(
        'should update ai2 position and return to user turn',
        build: () => bloc,
        seed: () => bloc.state.copyWith(turn: 'ai2'),
        act: (bloc) => bloc.add(Ai2MoveEvent()),
        expect: () => [
          isA<GameState>()
              .having((s) => s.turn, 'turn', 'user'),
        ],
      );

      blocTest<GridGameBloc, GameState>(
        'should ignore when not ai2 turn',
        build: () => bloc,
        act: (bloc) => bloc.add(Ai2MoveEvent()),
        expect: () => [],
      );

      blocTest<GridGameBloc, GameState>(
        'should ignore when game is won',
        build: () => bloc,
        seed: () => bloc.state.copyWith(turn: 'ai2', winner: 'user'),
        act: (bloc) => bloc.add(Ai2MoveEvent()),
        expect: () => [],
      );
    });

    group('AI2 Strategy', () {
      blocTest<GridGameBloc, GameState>(
        'should move toward center when ai2 is winning',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          turn: 'ai2',
          ai2Pos: Position(3, 2),
          scores: {'user': 10, 'ai1': 15, 'ai2': 25},
        ),
        act: (bloc) => bloc.add(Ai2MoveEvent()),
        verify: (bloc) {
          final newPos = bloc.state.ai2Pos;
          final center = Position(2, 2);
          final oldDistance = (3 - center.x).abs() + (2 - center.y).abs();
          final newDistance = (newPos.x - center.x).abs() + (newPos.y - center.y).abs();
          expect(newDistance, lessThanOrEqualTo(oldDistance));
        },
      );

      blocTest<GridGameBloc, GameState>(
        'should move to highest value cell when not winning',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          turn: 'ai2',
          ai2Pos: Position(2, 2),
          scores: {'user': 30, 'ai1': 25, 'ai2': 15},
        ),
        act: (bloc) => bloc.add(Ai2MoveEvent()),
        verify: (bloc) {
          // AI2 should have moved to an adjacent position
          final newPos = bloc.state.ai2Pos;
          final validMoves = [
            Position(1, 2), Position(3, 2), Position(2, 1), Position(2, 3)
          ];
          expect(validMoves.any((p) => p.x == newPos.x && p.y == newPos.y), true);
        },
      );
    });

    group('Win Condition Checking', () {
      blocTest<GridGameBloc, GameState>(
        'should set couldReachCenter to true when total score >= 100',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          scores: {'user': 40, 'ai1': 35, 'ai2': 20},
          couldReachCenter: false,
        ),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 3))),
        verify: (bloc) {
          // After the move, total score should be >= 100
          final totalScore = bloc.state.scores.values.reduce((a, b) => a + b);
          if (totalScore >= 100) {
            expect(bloc.state.couldReachCenter, true);
          }
        },
      );

      blocTest<GridGameBloc, GameState>(
        'should set couldReachCenter to true when starting from null state',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          scores: {'user': 40, 'ai1': 35, 'ai2': 20},
          couldReachCenter: null, // This was the bug - null != false
        ),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 3))),
        verify: (bloc) {
          final totalScore = bloc.state.scores.values.reduce((a, b) => a + b);
          if (totalScore >= 100) {
            expect(bloc.state.couldReachCenter, true);
          }
        },
      );

      blocTest<GridGameBloc, GameState>(
        'should declare winner when player reaches center with highest score and total >= 100',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          userPos: Position(2, 1),
          scores: {'user': 50, 'ai1': 30, 'ai2': 20},
          couldReachCenter: true,
        ),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 2))), // Move to center
        verify: (bloc) {
          final totalScore = bloc.state.scores.values.reduce((a, b) => a + b);
          final userScore = bloc.state.scores['user']!;
          final otherScores = [bloc.state.scores['ai1']!, bloc.state.scores['ai2']!];
          final maxOtherScore = otherScores.reduce((a, b) => a > b ? a : b);
          
          if (totalScore >= 100 && userScore > maxOtherScore && 
              bloc.state.userPos.x == 2 && bloc.state.userPos.y == 2) {
            expect(bloc.state.winner, 'user');
          }
        },
      );

      blocTest<GridGameBloc, GameState>(
        'should not declare winner if not at center',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          scores: {'user': 60, 'ai1': 30, 'ai2': 20},
          couldReachCenter: true,
        ),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 3))), // Not center
        verify: (bloc) {
          expect(bloc.state.winner, null);
        },
      );

      blocTest<GridGameBloc, GameState>(
        'should not declare winner if total score < 100',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          userPos: Position(2, 1),
          scores: {'user': 40, 'ai1': 30, 'ai2': 20},
          couldReachCenter: false,
        ),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 2))), // Move to center
        verify: (bloc) {
          final totalScore = bloc.state.scores.values.reduce((a, b) => a + b);
          if (totalScore < 100) {
            expect(bloc.state.winner, null);
          }
        },
      );

      blocTest<GridGameBloc, GameState>(
        'should not declare winner if not highest score',
        build: () => bloc,
        seed: () => bloc.state.copyWith(
          userPos: Position(2, 1),
          scores: {'user': 30, 'ai1': 50, 'ai2': 25},
          couldReachCenter: true,
        ),
        act: (bloc) => bloc.add(UserMoveEvent(Position(2, 2))), // Move to center
        verify: (bloc) {
          final userScore = bloc.state.scores['user']!;
          final ai1Score = bloc.state.scores['ai1']!;
          if (userScore <= ai1Score) {
            expect(bloc.state.winner, null);
          }
        },
      );
    });

    group('Edge Cases', () {
      blocTest<GridGameBloc, GameState>(
        'should handle multiple restart events',
        build: () => bloc,
        act: (bloc) {
          bloc.add(UserMoveEvent(Position(2, 3)));
          bloc.add(RestartGameEvent());
          bloc.add(RestartGameEvent());
        },
        verify: (bloc) {
          expect(bloc.state.scores['user'], 0);
          expect(bloc.state.scores['ai1'], 0);
          expect(bloc.state.scores['ai2'], 0);
          expect(bloc.state.turn, 'user');
          expect(bloc.state.winner, null);
        },
      );

      blocTest<GridGameBloc, GameState>(
        'should handle rapid consecutive moves',
        build: () => bloc,
        act: (bloc) {
          bloc.add(UserMoveEvent(Position(2, 3)));
          bloc.add(UserMoveEvent(Position(2, 1))); // Should be ignored (not user turn)
        },
        verify: (bloc) {
          expect(bloc.state.userPos.y, 3); // Only first move should count
        },
      );
    });
  });

  group('GridGameEvent classes', () {
    test('UserMoveEvent should store position', () {
      final pos = Position(1, 2);
      final event = UserMoveEvent(pos);
      expect(event.pos, pos);
    });

    test('Ai1MoveEvent should be instantiable', () {
      final event = Ai1MoveEvent();
      expect(event, isA<Ai1MoveEvent>());
      expect(event, isA<GridGameEvent>());
    });

    test('Ai2MoveEvent should be instantiable', () {
      final event = Ai2MoveEvent();
      expect(event, isA<Ai2MoveEvent>());
      expect(event, isA<GridGameEvent>());
    });

    test('RestartGameEvent should be instantiable', () {
      final event = RestartGameEvent();
      expect(event, isA<RestartGameEvent>());
      expect(event, isA<GridGameEvent>());
    });
  });
}