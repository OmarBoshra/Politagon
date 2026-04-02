import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';

abstract class AiStrategy {
  Position getNextMove(GamePlayerState player, GameState state, List<Position> validMoves);
}
