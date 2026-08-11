import 'daily_puzzle_challenge.dart';
import 'daily_puzzle_result.dart';

class DailyPuzzleHistoryEntry {
  const DailyPuzzleHistoryEntry({
    required this.date,
    required this.challenge,
    required this.result,
    required this.isToday,
  });

  final DateTime date;
  final DailyPuzzleChallenge challenge;
  final DailyPuzzleResult result;
  final bool isToday;

  String get dateKey => challenge.dateKey;

  bool get isCompleted => result.completed;

  String get statusLabel {
    if (isCompleted) {
      return 'Solved - ${result.bestMoves ?? result.moves ?? 0} moves';
    }
    return isToday ? 'Ready today' : 'Missed';
  }
}
