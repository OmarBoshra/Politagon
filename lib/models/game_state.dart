import 'dart:math';
import 'package:politagon/models/position.dart';
import '../utilities/grid_generator.dart';

enum SocialClass { elite, noble, middle, layman, poor }

class GameState {
  final List<List<int>> grid;
  final List<GamePlayerState> players;
  final String turn;
  final String? winner;
  final bool? couldReachCenter;
  final int gridSize;

  final bool isSpectating;
  final String? spectatedPlayerId;

  GameState({
    required this.grid,
    required this.players,
    required this.turn,
    required this.gridSize,
    this.winner,
    this.couldReachCenter,
    this.isSpectating = false,
    this.spectatedPlayerId,
  });

  int get winThreshold => gridSize * 20;
  int get maxNationalPool => gridSize * gridSize * 4;

  GameState copyWith({
    List<List<int>>? grid,
    List<GamePlayerState>? players,
    String? turn,
    int? gridSize,
    String? winner,
    bool? couldReachCenter,
    bool? isSpectating,
    String? spectatedPlayerId,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      players: players ?? this.players,
      turn: turn ?? this.turn,
      gridSize: gridSize ?? this.gridSize,
      winner: winner ?? this.winner,
      couldReachCenter: couldReachCenter ?? this.couldReachCenter,
      isSpectating: isSpectating ?? this.isSpectating,
      spectatedPlayerId: spectatedPlayerId ?? this.spectatedPlayerId,
    );
  }

  static String getSocialClassName(int distance, int maxDist) {
    if (distance == 0) return 'The Politagon';
    
    const titles = [
      'The Politagon',
      'High Council',
      'Inner Circle',
      'Aristocracy',
      'Patricians',
      'The Nobility',
      'Gentry',
      'Magistrates',
      'Burgesses',
      'The Guilds',
      'Middle Class',
      'Artisans',
      'Freeholders',
      'The Commonry',
      'Laymen',
      'Peasantry',
      'The Proletariat',
      'Serfs',
      'The Poor',
      'Outcasts',
      'The Forgotten',
    ];

    if (distance < titles.length) {
      if (distance == maxDist) return 'The Underclass';
      return titles[distance];
    }
    
    return 'Level $distance';
  }

  static GameState initial({
    List<String> humanNames = const ['The Candidate'], 
    bool ai1 = true, 
    bool ai2 = true, 
    bool ai3 = false, 
    bool ai4 = false, 
    int gridSize = 5
  }) {
    final random = Random();
    final initialPool = gridSize * gridSize * 4;
    final grid = GridGenerator.generate(gridSize, gridSize, initialPool);
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

    for (int i = 0; i < humanNames.length; i++) {
      final pos = Position(random.nextInt(gridSize), random.nextInt(gridSize));
      players.add(GamePlayerState(
        id: 'user${i+1}',
        name: humanNames[i].isEmpty ? 'Candidate ${i+1}' : humanNames[i],
        pos: pos,
        type: PlayerType.human,
        colorIndex: i,
        influence: calculateStartingStat(pos, true),
        popularity: calculateStartingStat(pos, false),
      ));
    }

    if (ai1) {
      final pos = Position(random.nextInt(gridSize), random.nextInt(gridSize));
      players.add(GamePlayerState(
        id: 'ai1',
        name: 'The Firebrand',
        pos: pos,
        type: PlayerType.ai1,
        influence: calculateStartingStat(pos, true),
        popularity: calculateStartingStat(pos, false),
      ));
    }
    if (ai2) {
      final pos = Position(random.nextInt(gridSize), random.nextInt(gridSize));
      players.add(GamePlayerState(
        id: 'ai2',
        name: 'The Pragmatist',
        pos: pos,
        type: PlayerType.ai2,
        influence: calculateStartingStat(pos, true),
        popularity: calculateStartingStat(pos, false),
      ));
    }
    if (ai3) {
      final pos = Position(random.nextInt(gridSize), random.nextInt(gridSize));
      players.add(GamePlayerState(
        id: 'ai3',
        name: 'The Technocrat',
        pos: pos,
        type: PlayerType.ai3,
        influence: calculateStartingStat(pos, true),
        popularity: calculateStartingStat(pos, false),
      ));
    }
    if (ai4) {
      final pos = Position(random.nextInt(gridSize), random.nextInt(gridSize));
      players.add(GamePlayerState(
        id: 'ai4',
        name: 'The Visionary',
        pos: pos,
        type: PlayerType.ai4,
        influence: calculateStartingStat(pos, true),
        popularity: calculateStartingStat(pos, false),
      ));
    }

    return GameState(
      grid: grid,
      players: players,
      turn: players.isNotEmpty ? players.first.id : 'user1',
      gridSize: gridSize,
      winner: null,
      couldReachCenter: false,
    );
  }
}

enum PlayerType { human, ai1, ai2, ai3, ai4 }

class GamePlayerState {
  final String id;
  final String name;
  final Position pos;
  final Map<int, int> votesByDistance;
  final double influence;
  final double popularity;
  final PlayerType type;
  final int colorIndex;
  final Position? targetPos;

  int get score => votesByDistance.values.fold(0, (sum, val) => sum + val);

  GamePlayerState({
    required this.id,
    required this.name,
    required this.pos,
    Map<int, int>? votesByDistance,
    this.influence = 0.1,
    this.popularity = 0.1,
    required this.type,
    this.colorIndex = 0,
    this.targetPos,
  }) : votesByDistance = votesByDistance ?? {};

  GamePlayerState copyWith({
    Position? pos,
    Map<int, int>? votesByDistance,
    double? influence,
    double? popularity,
    Position? targetPos,
    bool clearTarget = false,
  }) {
    return GamePlayerState(
      id: id,
      name: name,
      pos: pos ?? this.pos,
      votesByDistance: votesByDistance ?? this.votesByDistance,
      influence: influence ?? this.influence,
      popularity: popularity ?? this.popularity,
      type: type,
      colorIndex: colorIndex,
      targetPos: clearTarget ? null : (targetPos ?? this.targetPos),
    );
  }
}
