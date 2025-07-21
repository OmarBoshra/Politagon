

class Position {
  final int x;
  final int y;
  Position(this.x, this.y);

  bool equals(Position other) {
    return x == other.x && y == other.y;
  }
}