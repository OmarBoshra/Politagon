import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/main.dart';
import 'package:politagon/ui/splash_screen.dart';
import 'package:politagon/ui/home_page.dart';
import 'package:politagon/ui/grid_game.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('complete app flow from splash to game', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Should start with splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      // Wait for splash screen transition
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should now be on home page with game
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(GridGame), findsOneWidget);

      // Check initial game state
      expect(find.text('User: 0'), findsOneWidget);
      expect(find.text('AI 1: 0'), findsOneWidget);
      expect(find.text('AI 2: 0'), findsOneWidget);
      expect(find.text('Politagon'), findsOneWidget);
    });

    testWidgets('game interaction flow', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Skip splash screen
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should be on game screen
      expect(find.byType(GridGame), findsOneWidget);

      // Test keyboard interaction
      await tester.tap(find.byType(GridView));
      await tester.pump();

      // Make a move with arrow key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Scores should have changed (user made a move)
      expect(find.textContaining('User:'), findsOneWidget);
      
      // AI should have made moves automatically
      await tester.pump(Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('restart functionality', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Skip splash screen
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Make some moves first
      await tester.tap(find.byType(GridView));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Tap restart button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Should be back to initial state
      expect(find.text('User: 0'), findsOneWidget);
      expect(find.text('AI 1: 0'), findsOneWidget);
      expect(find.text('AI 2: 0'), findsOneWidget);
    });

    testWidgets('music toggle functionality', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Skip splash screen
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Initially should show music off
      expect(find.byIcon(Icons.music_off), findsOneWidget);

      // Toggle music on
      await tester.tap(find.byIcon(Icons.music_off));
      await tester.pump();

      // Should now show music on
      expect(find.byIcon(Icons.music_note), findsOneWidget);

      // Toggle back off
      await tester.tap(find.byIcon(Icons.music_note));
      await tester.pump();

      // Should be back to music off
      expect(find.byIcon(Icons.music_off), findsOneWidget);
    });

    testWidgets('grid cell interaction', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Skip splash screen
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should have 25 grid cells
      expect(find.byType(GestureDetector), findsNWidgets(25));

      // Test cell tap (should work when it's user's turn)
      final cellFinder = find.byType(GestureDetector).first;
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      // Game should progress
      expect(find.byType(GridGame), findsOneWidget);
    });

    testWidgets('app navigation structure', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Check app structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(SplashScreen), findsOneWidget);

      // Check app properties
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, false);
      expect(materialApp.title, 'Politagon');
    });

    testWidgets('theme and styling', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Skip splash screen
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Check that app bar has theme styling
      expect(find.byType(AppBar), findsOneWidget);
      
      // Check that grid has proper styling
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('error handling - no crashes during normal flow', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      // Go through complete flow without crashes
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Make several moves
      await tester.tap(find.byType(GridView));
      await tester.pump();
      
      for (final key in [
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowUp,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }

      // Restart multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();
      }

      // Toggle music multiple times
      for (int i = 0; i < 4; i++) {
        final musicIcon = find.byIcon(Icons.music_off).evaluate().isNotEmpty 
            ? find.byIcon(Icons.music_off) 
            : find.byIcon(Icons.music_note);
        await tester.tap(musicIcon);
        await tester.pump();
      }

      // Should not have any exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive layout', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(Size(400, 800));
      await tester.pumpWidget(MyRootApp());

      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(GridGame), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);

      // Test with wider screen
      await tester.binding.setSurfaceSize(Size(800, 600));
      await tester.pump();

      expect(find.byType(GridGame), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('accessibility features', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Check for tooltips on buttons
      expect(find.byTooltip('Restart Game'), findsOneWidget);
      expect(find.byTooltip('Toggle Music'), findsOneWidget);
    });

    testWidgets('state persistence during navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MyRootApp());

      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Make a move
      await tester.tap(find.byType(GridView));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // State should be maintained
      expect(find.byType(GridGame), findsOneWidget);
      
      // Game should continue to work
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    });
  });
}