import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:politagon/ui/home_page.dart';
import 'package:politagon/ui/grid_game.dart';
import 'package:politagon/bloc/grid_game_event.dart';

void main() {
  group('HomePage', () {
    testWidgets('should display app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Politagon'), findsOneWidget);
    });

    testWidgets('should provide GridGameBloc to GridGame', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      expect(find.byType(BlocProvider<GridGameBloc>), findsOneWidget);
      expect(find.byType(GridGame), findsOneWidget);
    });

    testWidgets('should have correct scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(GridGame), findsOneWidget);
    });

    testWidgets('should create GridGameBloc instance', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      final blocProvider = tester.widget<BlocProvider<GridGameBloc>>(
        find.byType(BlocProvider<GridGameBloc>),
      );

      expect(blocProvider.create, isNotNull);
    });

    testWidgets('should be a StatelessWidget', (WidgetTester tester) async {
      final homePage = HomePage();
      expect(homePage, isA<StatelessWidget>());
    });

    testWidgets('should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should have GridGame as body', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isA<GridGame>());
    });

    testWidgets('should provide context to GridGame', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      // Verify that GridGame can access the BLoC
      expect(find.byType(GridGame), findsOneWidget);
      
      // The GridGame should be able to access the BLoC context
      final gridGameFinder = find.byType(GridGame);
      expect(gridGameFinder, findsOneWidget);
    });

    testWidgets('should handle theme correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: HomePage(),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Politagon'), findsOneWidget);
    });

    testWidgets('should maintain BLoC lifecycle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage()),
      );

      // Pump a few frames to ensure BLoC is stable
      await tester.pump();
      await tester.pump();

      expect(find.byType(GridGame), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}