import '../domain/models/board_position.dart';
import '../domain/models/generated_puzzle.dart';

class PuzzleValidationResult {
  const PuzzleValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class PuzzleSolutionValidator {
  const PuzzleSolutionValidator();

  PuzzleValidationResult validate({
    required int rows,
    required int columns,
    required int expectedPairCount,
    required List<GeneratedPuzzlePath> paths,
  }) {
    final errors = <String>[];
    final owners = <BoardPosition, int>{};
    final pathIds = <int>{};

    if (rows <= 0 || columns <= 0) {
      errors.add('Board dimensions must be positive.');
    }
    if (paths.length != expectedPairCount) {
      errors.add(
        'Expected $expectedPairCount paths, but generated ${paths.length}.',
      );
    }

    for (final path in paths) {
      if (!pathIds.add(path.id)) {
        errors.add('Path ID ${path.id} is duplicated.');
      }
      if (path.cells.length < 2) {
        errors.add('Path ${path.id} must contain at least two cells.');
        continue;
      }
      final localCells = <BoardPosition>{};
      final logicalDegrees = <BoardPosition, int>{};

      for (var index = 0; index < path.cells.length; index += 1) {
        final cell = path.cells[index];
        if (!_inside(cell, rows: rows, columns: columns)) {
          errors.add('Path ${path.id} contains out-of-bounds cell $cell.');
        }
        if (!localCells.add(cell)) {
          errors.add('Path ${path.id} repeats cell $cell.');
        }
        final previousOwner = owners[cell];
        if (previousOwner != null && previousOwner != path.id) {
          errors.add(
            'Cell $cell is shared by paths $previousOwner and ${path.id}.',
          );
        }
        owners[cell] = path.id;

        if (index > 0) {
          final previous = path.cells[index - 1];
          if (!_adjacent(previous, cell)) {
            errors.add('Path ${path.id} has a non-orthogonal step.');
          } else {
            logicalDegrees[previous] = (logicalDegrees[previous] ?? 0) + 1;
            logicalDegrees[cell] = (logicalDegrees[cell] ?? 0) + 1;
          }
        }
      }

      for (var index = 0; index < path.cells.length; index += 1) {
        final expectedDegree = index == 0 || index == path.cells.length - 1
            ? 1
            : 2;
        if (logicalDegrees[path.cells[index]] != expectedDegree) {
          errors.add(
            'Path ${path.id} branches or has an invalid logical degree.',
          );
          break;
        }
      }
    }

    final expectedCellCount = rows * columns;
    final assignedCellCount = paths.fold<int>(
      0,
      (total, path) => total + path.cells.length,
    );
    if (assignedCellCount != expectedCellCount) {
      errors.add(
        'Paths contain $assignedCellCount cells; expected $expectedCellCount.',
      );
    }
    if (owners.length != expectedCellCount) {
      errors.add(
        'Only ${owners.length} unique cells are covered; expected '
        '$expectedCellCount.',
      );
    }

    return PuzzleValidationResult(List<String>.unmodifiable(errors));
  }

  bool _inside(
    BoardPosition position, {
    required int rows,
    required int columns,
  }) {
    return position.row >= 0 &&
        position.row < rows &&
        position.column >= 0 &&
        position.column < columns;
  }

  bool _adjacent(BoardPosition first, BoardPosition second) {
    return (first.row - second.row).abs() +
            (first.column - second.column).abs() ==
        1;
  }
}
