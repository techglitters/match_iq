class BoardPosition {
  const BoardPosition({required this.row, required this.column});

  final int row;
  final int column;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BoardPosition &&
            runtimeType == other.runtimeType &&
            row == other.row &&
            column == other.column;
  }

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'BoardPosition(row: $row, column: $column)';
}
