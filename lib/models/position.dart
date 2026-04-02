class Position {
  final int x;
  final int y;
  Position(this.x, this.y);

  bool equals(Position other) {
    return x == other.x && y == other.y;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Position) return false;
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}