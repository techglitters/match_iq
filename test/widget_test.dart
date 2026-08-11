import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/app/app.dart';
import 'package:match_iq/core/constants/game_constants.dart';
import 'package:match_iq/core/persistence/memory_progress_store.dart';
import 'package:match_iq/features/game/presentation/widgets/game_path_painter.dart';
import 'package:match_iq/features/themes/domain/app_progress_data.dart';
import 'package:match_iq/features/themes/domain/theme_progress.dart';

void main() {
  testWidgets('Splash navigates to home and play opens the game', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ConnectGrowApp(progressStore: MemoryProgressStore()),
    );

    expect(find.text('Link & Learn'), findsOneWidget);

    await tester.pump(
      GameConstants.splashDuration + const Duration(milliseconds: 100),
    );
    await tester.pump();

    expect(find.text('Match things that belong together'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.text('Nature World'), findsOneWidget);

    await tester.tap(find.text('Play Level 1'));
    await tester.pumpAndSettle();

    expect(find.text('Nature 1'), findsOneWidget);
    expect(find.text('Pairs'), findsOneWidget);
    expect(find.text('Moves'), findsOneWidget);
  });

  testWidgets('Continue opens the last played level directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ConnectGrowApp(
        progressStore: MemoryProgressStore(
          const AppProgressData(
            activeThemeId: 'nature',
            lastPlayedThemeId: 'nature',
            lastPlayedLevelNumber: 3,
            hasSeenHome: true,
            themes: {
              'nature': ThemeProgress(highestUnlockedLevel: 3, levels: {}),
            },
          ),
        ),
      ),
    );

    await tester.pump(
      GameConstants.splashDuration + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Nature 3'), findsOneWidget);
  });

  testWidgets('Daily puzzle card opens today challenge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ConnectGrowApp(progressStore: MemoryProgressStore()),
    );

    await tester.pump(
      GameConstants.splashDuration + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Today's Daily Puzzle"));
    await tester.pumpAndSettle();

    expect(find.text('Daily Puzzle'), findsOneWidget);
    expect(find.text('Pairs'), findsOneWidget);
  });

  testWidgets('Daily history opens from the home card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ConnectGrowApp(progressStore: MemoryProgressStore()),
    );

    await tester.pump(
      GameConstants.splashDuration + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Daily history'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Daily history'));
    await tester.pumpAndSettle();

    expect(find.text('Daily History'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
  });

  testWidgets('Settings can reveal the known color-coded solution paths', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ConnectGrowApp(progressStore: MemoryProgressStore()),
    );

    await tester.pump(
      GameConstants.splashDuration + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Show solution paths'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.text('Show solution paths'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play Level 1'));
    await tester.pumpAndSettle();

    final pathPaint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GamePathPainter,
      ),
    );
    final pathPainter = pathPaint.painter! as GamePathPainter;

    expect(pathPainter.solutionPaths, isNotEmpty);
    expect(pathPainter.solutionPaths, hasLength(3));
  });
}
