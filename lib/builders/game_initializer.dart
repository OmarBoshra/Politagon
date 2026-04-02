import 'dart:math';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../utilities/grid_generator.dart';

class GameInitializer {
  static GameState createInitialState({
    List<String> humanNames = const ['The Candidate'],
    bool ai1 = true,
    bool ai2 = true,
    bool ai3 = false,
    bool ai4 = false,
    bool ai5 = false,
    int gridSize = 5,
  }) {
    final random = Random();
    final initialPool = gridSize * gridSize * 4;
    final grid = GridGenerator.generate(gridSize, gridSize, initialPool);

    final gridOwnership = List.generate(gridSize, (i) =>
      List.generate(gridSize, (j) {
        final value = grid[i][j];
        return value > 0 ? {'undecided': value} : {'undecided': 0};
      }),
    );

    final gridMajority = List.generate(gridSize, (i) =>
      List<String?>.generate(gridSize, (j) => 'undecided'),
    );

    final players = <GamePlayerState>[];
    final centerIdx = gridSize ~/ 2;
    final maxDist = centerIdx * 2;

    double calculateStartingStat(Position pos, bool isInfluence) {
      final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
      if (isInfluence) {
        return (maxDist + 1 - distance) / (maxDist + 1).toDouble();
      } else {
        return (distance + 1) / (maxDist + 1).toDouble();
      }
    }

    Position getNonCenterPosition() {
      while (true) {
        final x = random.nextInt(gridSize);
        final y = random.nextInt(gridSize);
        if (x != centerIdx || y != centerIdx) return Position(x, y);
      }
    }

    for (int i = 0; i < humanNames.length; i++) {
      final pos = getNonCenterPosition();
      players.add(GamePlayerState(
        id: 'user${i + 1}',
        name: humanNames[i].isEmpty ? 'Candidate ${i + 1}' : humanNames[i],
        pos: pos,
        type: PlayerType.human,
        colorIndex: i,
        influence: calculateStartingStat(pos, true),
        popularity: calculateStartingStat(pos, false),
      ));
    }

    final aiConfigs = [
      (ai1, 'ai1', 'The Firebrand', PlayerType.ai1),
      (ai2, 'ai2', 'The Pragmatist', PlayerType.ai2),
      (ai3, 'ai3', 'The Technocrat', PlayerType.ai3),
      (ai4, 'ai4', 'The Visionary', PlayerType.ai4),
      (ai5, 'ai5', 'The Socialist', PlayerType.ai5),
    ];

    for (var config in aiConfigs) {
      if (config.$1) {
        final pos = getNonCenterPosition();
        players.add(GamePlayerState(
          id: config.$2,
          name: config.$3,
          pos: pos,
          type: config.$4,
          influence: calculateStartingStat(pos, true),
          popularity: calculateStartingStat(pos, false),
        ));
      }
    }

    grid[centerIdx][centerIdx] = 0;
    gridOwnership[centerIdx][centerIdx] = {'undecided': 0};
    gridMajority[centerIdx][centerIdx] = null;

    return GameState(
      grid: grid,
      gridOwnership: gridOwnership,
      gridMajority: gridMajority,
      players: players,
      turn: players.isNotEmpty ? players.first.id : 'user1',
      gridSize: gridSize,
      winner: null,
      couldReachCenter: false,
    );
  }
}
