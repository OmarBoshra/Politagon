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
      expect(decoration.image!.fit, BoxFit.contain);
    });

    testWidgets('should have correct scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should create state correctly', (WidgetTester tester) async {
      const splashScreen = SplashScreen();
      expect(splashScreen.createState(), isA<State<SplashScreen>>());
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

    testWidgets('should initialize with correct timer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      // Initially should show splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('should have correct decoration properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      
      expect(decoration.image!.fit, BoxFit.contain);
      expect(decoration.image!.image, isA<AssetImage>());
    });

    testWidgets('should use correct asset path', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen()),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      final assetImage = decoration.image!.image as AssetImage;
      
      expect(assetImage.assetName, 'assets/logo.jpg');
    });
  });
}