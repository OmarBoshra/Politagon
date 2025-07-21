import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:politagon/ui/splash_screen.dart';
import 'package:politagon/ui/home_page.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('should display logo image', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      // Check if the image is displayed
      expect(find.byType(Container), findsOneWidget);
      
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, isA<BoxDecoration>());
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.image, isNotNull);
      expect(decoration.image!.image, isA<AssetImage>());
      
      final assetImage = decoration.image!.image as AssetImage;
      expect(assetImage.assetName, 'assets/logo.jpg');
      expect(decoration.image!.fit, BoxFit.cover);
    });

    testWidgets('should navigate to HomePage after 2 seconds', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      // Initially should show splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      // Wait for 2 seconds
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should now show HomePage
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should have correct scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should not navigate before 2 seconds', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      // Wait for 1 second (less than 2)
      await tester.pump(Duration(seconds: 1));

      // Should still show splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('should handle multiple pump calls correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      // Multiple small pumps
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 500));

      // Should now navigate (total 2 seconds)
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should create state correctly', (WidgetTester tester) async {
      const splashScreen = SplashScreen();
      expect(splashScreen.createState(), isA<_SplashScreenState>());
    });

    testWidgets('should be a StatefulWidget', (WidgetTester tester) async {
      const splashScreen = SplashScreen();
      expect(splashScreen, isA<StatefulWidget>());
    });

    testWidgets('should have correct key when provided', (WidgetTester tester) async {
      const key = Key('splash_key');
      const splashScreen = SplashScreen(key: key);
      expect(splashScreen.key, key);
    });

    testWidgets('should handle navigation replacement correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
          routes: {
            '/home': (context) => HomePage(),
          },
        ),
      );

      // Wait for navigation
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Check that we can't go back to splash (replacement navigation)
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}