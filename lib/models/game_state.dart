import 'package:politagon/models/position.dart';

import '../utilities/grid_generator.dart';

class GameState {
  final List<List<int>> grid;
  final Position userPos;
  final Position ai1Pos;
  final Position ai2Pos;
  final Map<String, int> scores;
  final String turn;
  final String? winner;
  final bool? couldReachCenter;

  GameState({
    required this.grid,
    required this.userPos,
    required this.ai1Pos,
    required this.ai2Pos,
    required this.scores,
    required this.turn,
    this.winner,
    this.couldReachCenter,
  });

  GameState copyWith({
    List<List<int>>? grid,
    Position? userPos,
    Position? ai1Pos,
    Position? ai2Pos,
    Map<String, int>? scores,
    String? turn,
    String? winner,
    bool? couldReachCenter,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      userPos: userPos ?? this.userPos,
      ai1Pos: ai1Pos ?? this.ai1Pos,
      ai2Pos: ai2Pos ?? this.ai2Pos,
      scores: scores ?? this.scores,
      turn: turn ?? this.turn,
      winner: winner ?? this.winner,
      couldReachCenter: couldReachCenter ?? this.couldReachCenter,
    );
  }

  static GameState initial() {
    final grid = GridGenerator.generate(5, 5);
    final center = Position(2, 2);
    return GameState(
      grid: grid,
      userPos: center,
      ai1Pos: center,
      ai2Pos: center,
      scores: {'user': 0, 'ai1': 0, 'ai2': 0},
      turn: 'user',
    );
  }
}
