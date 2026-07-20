import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/app/app.dart';
import 'package:match_iq/core/constants/game_constants.dart';

void main() {
  testWidgets('Splash navigates to home and play opens the game', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ConnectGrowApp());

    expect(find.text('Connect & Grow'), findsOneWidget);

    await tester.pump(
      GameConstants.splashDuration + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();

    expect(find.text('Match things that belong together'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.text('Nature 1'), findsOneWidget);
    expect(find.text('Pairs'), findsOneWidget);
    expect(find.text('Moves'), findsOneWidget);
  });
}
