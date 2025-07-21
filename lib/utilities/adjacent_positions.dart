

import '../models/position.dart';

class AdjacentPositions {
  static List<Position> get(Position pos, int rows, int cols) {
    final moves = <Position>[];
    if (pos.x > 0) moves.add(Position(pos.x - 1, pos.y));
    if (pos.x < rows - 1) moves.add(Position(pos.x + 1, pos.y));
    if (pos.y > 0) moves.add(Position(pos.x, pos.y - 1));
    if (pos.y < cols - 1) moves.add(Position(pos.x, pos.y + 1));
    return moves;
  }
}