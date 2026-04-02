import 'position.dart';

enum SocialClass { elite, noble, middle, layman, poor }

enum PlayerType { human, ai1, ai2, ai3, ai4, ai5 }

class GamePlayerState {
  final String id;
  final String name;
  final Position pos;
  final double influence;
  final double popularity;
  final PlayerType type;
  final int colorIndex;
  final Position? targetPos;

  GamePlayerState({
    required this.id,
    required this.name,
    required this.pos,
    this.influence = 0.1,
    this.popularity = 0.1,
    required this.type,
    this.colorIndex = 0,
    this.targetPos,
  });

  GamePlayerState copyWith({
    Position? pos,
    double? influence,
    double? popularity,
    Position? targetPos,
    bool clearTarget = false,
  }) {
    return GamePlayerState(
      id: id,
      name: name,
      pos: pos ?? this.pos,
      influence: influence ?? this.influence,
      popularity: popularity ?? this.popularity,
      type: type,
      colorIndex: colorIndex,
      targetPos: clearTarget ? null : (targetPos ?? this.targetPos),
    );
  }
}
