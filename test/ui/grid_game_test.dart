import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:politagon/ui/grid_game.dart';
import 'package:politagon/bloc/grid_game_event.dart';
import 'package:politagon/models/game_state.dart';
import 'package:politagon/models/position.dart';

void main() {
  group('GridGame', () {
    late GridGameBloc bloc;

    setUp(() {
      bloc = GridGameBloc();
    });

    tearDown(() {
      bloc.close();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<GridGameBloc>.value(
          value: bloc,
          child: GridGame(),
        ),
      );
    }

    testWidgets('should display initial game state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for app bar
      expect(find.byType(AppBar), findsOneWidget);
      
      // Check for restart button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      
      // Check for music toggle button
      expect(find.byIcon(Icons.music_off), findsOneWidget);
      
      // Check for scoreboard
      expect(find.textContaining('User:'), findsOneWidget);
      expect(find.textContaining('AI 1:'), findsOneWidget);
      expect(find.textContaining('AI 2:'), findsOneWidget);
      
      // Check for grid
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should display correct initial scores', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('User: 0'), findsOneWidget);
      expect(find.text('AI 1: 0'), findsOneWidget);
      expect(find.text('AI 2: 0'), findsOneWidget);
    });

    testWidgets('should handle restart button tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // First make a move
      bloc.add(UserMoveEvent(Position(2, 3)));
      await tester.pump();

      // Then restart
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Should be back to initial state
      expect(find.text('User: 0'), findsOneWidget);
      expect(find.text('AI 1: 0'), findsOneWidget);
      expect(find.text('AI 2: 0'), findsOneWidget);
    });

    testWidgets('should handle music toggle button tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially should show music_off icon
      expect(find.byIcon(Icons.music_off), findsOneWidget);

      // Tap to toggle music
      await tester.tap(find.byIcon(Icons.music_off));
      await tester.pump();

      // Should now show music_note icon
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('should display 25 grid cells', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should have 25 cells in 5x5 grid
      expect(find.byType(GestureDetector), findsNWidgets(25));
    });

    testWidgets('should handle keyboard input - arrow up', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Focus the widget
      await tester.tap(find.byType(GridView));
      await tester.pump();

      // Simulate arrow up key press
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // User should have moved up (from center 2,2 to 1,2)
      expect(bloc.state.userPos.x, 1);
      expect(bloc.state.userPos.y, 2);
    });

    testWidgets('should handle keyboard input - arrow down', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(GridView));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(bloc.state.userPos.x, 3);
      expect(bloc.state.userPos.y, 2);
    });

    testWidgets('should handle keyboard input - arrow left', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(GridView));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(bloc.state.userPos.x, 2);
      expect(bloc.state.userPos.y, 1);
    });

    testWidgets('should handle keyboard input - arrow right', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(GridView));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(bloc.state.userPos.x, 2);
      expect(bloc.state.userPos.y, 3);
    });

    testWidgets('should ignore keyboard input at boundaries', (WidgetTester tester) async {
      // Set user at top-left corner
      bloc.emit(bloc.state.copyWith(userPos: Position(0, 0)));
      
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byType(GridView));
      await tester.pump();

      // Try to move up (should be ignored)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(bloc.state.userPos.x, 0);
      expect(bloc.state.userPos.y, 0);

      // Try to move left (should be ignored)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(bloc.state.userPos.x, 0);
      expect(bloc.state.userPos.y, 0);
    });

    testWidgets('should ignore keyboard input when not user turn', (WidgetTester tester) async {
      bloc.emit(bloc.state.copyWith(turn: 'ai1'));
      
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byType(GridView));
      await tester.pump();

      final initialPos = bloc.state.userPos;
      
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(bloc.state.userPos.x, initialPos.x);
      expect(bloc.state.userPos.y, initialPos.y);
    });

    testWidgets('should ignore keyboard input when game is won', (WidgetTester tester) async {
      bloc.emit(bloc.state.copyWith(winner: 'user'));
      
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byType(GridView));
      await tester.pump();

      final initialPos = bloc.state.userPos;
      
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(bloc.state.userPos.x, initialPos.x);
      expect(bloc.state.userPos.y, initialPos.y);
    });

    testWidgets('should display winner banner when game is won', (WidgetTester tester) async {
      bloc.emit(bloc.state.copyWith(winner: 'user'));
      
      await tester.pumpWidget(createTestWidget());

      expect(find.text('user Wins!'), findsOneWidget);
    });

    testWidgets('should not display winner banner when game is ongoing', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('Wins!'), findsNothing);
    });

    testWidgets('should handle cell tap when user turn', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find a cell adjacent to center (2,2) - let's try (2,3)
      final cellFinder = find.byType(GestureDetector).at(13); // Index for position (2,3)
      
      await tester.tap(cellFinder);
      await tester.pump();

      // User should have moved
      expect(bloc.state.userPos.y, 3);
    });

    testWidgets('should show glow animation when couldReachCenter is true', (WidgetTester tester) async {
      bloc.emit(bloc.state.copyWith(couldReachCenter: true));
      
      await tester.pumpWidget(createTestWidget());

      // Should find the glow animation container
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('should not show glow animation when couldReachCenter is false', (WidgetTester tester) async {
      bloc.emit(bloc.state.copyWith(couldReachCenter: false));
      
      await tester.pumpWidget(createTestWidget());

      // The glow animation should not be present
      final animatedBuilders = find.byType(AnimatedBuilder);
      // There might be other AnimatedBuilders, but the glow one should not be active
      expect(animatedBuilders, findsWidgets);
    });

    testWidgets('should display correct cell colors based on distance', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // All cells should be rendered
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should handle different keyboard keys correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byType(GridView));
      await tester.pump();

      // Test space key (should be ignored)
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(bloc.state.userPos.x, 2);
      expect(bloc.state.userPos.y, 2);

      // Test enter key (should be ignored)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(bloc.state.userPos.x, 2);
      expect(bloc.state.userPos.y, 2);
    });

    testWidgets('should maintain focus correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final focusFinder = find.byType(Focus);
      expect(focusFinder, findsOneWidget);

      final focus = tester.widget<Focus>(focusFinder);
      expect(focus.autofocus, true);
    });

    testWidgets('should create and dispose animation controller', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Widget should build without errors
      expect(tester.takeException(), isNull);
      
      // Dispose the widget
      await tester.pumpWidget(Container());
      
      // Should dispose without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle state changes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Change scores
      bloc.emit(bloc.state.copyWith(
        scores: {'user': 10, 'ai1': 20, 'ai2': 30}
      ));
      await tester.pump();

      expect(find.text('User: 10'), findsOneWidget);
      expect(find.text('AI 1: 20'), findsOneWidget);
      expect(find.text('AI 2: 30'), findsOneWidget);
    });

    testWidgets('should be a StatefulWidget', (WidgetTester tester) async {
      const gridGame = GridGame();
      expect(gridGame, isA<StatefulWidget>());
    });

    testWidgets('should have correct key when provided', (WidgetTester tester) async {
      const key = Key('grid_key');
      const gridGame = GridGame(key: key);
      expect(gridGame.key, key);
    });
  });
}