import '../domain/models/board_position.dart';
import '../domain/models/generated_puzzle.dart';

class PuzzleSignatureGenerator {
  const PuzzleSignatureGenerator();

  String fromPaths({
    required int rows,
    required int columns,
    required List<GeneratedPuzzlePath> paths,
  }) {
    final normalizedPairs = <String>[
      for (final path in paths) _normalizedPair(path.first, path.last),
    ]..sort();
    return '${rows}x$columns|${normalizedPairs.join('|')}';
  }

  String _normalizedPair(BoardPosition first, BoardPosition second) {
    final firstText = '${first.row},${first.column}';
    final secondText = '${second.row},${second.column}';
    return firstText.compareTo(secondText) <= 0
        ? '$firstText-$secondText'
        : '$secondText-$firstText';
  }
}

class PuzzleSignatureHistory {
  PuzzleSignatureHistory({this.capacity = 50}) : assert(capacity > 0);

  final int capacity;
  final List<String> _signatures = <String>[];

  bool contains(String signature) => _signatures.contains(signature);

  void add(String signature) {
    _signatures.remove(signature);
    _signatures.add(signature);
    if (_signatures.length > capacity) {
      _signatures.removeAt(0);
    }
  }

  List<String> get values => List<String>.unmodifiable(_signatures);
}
