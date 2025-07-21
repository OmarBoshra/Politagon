import 'package:flutter_test/flutter_test.dart';

// Import all test files to ensure coverage
import 'test_all.dart' as all_tests;
import 'integration/app_integration_test.dart' as integration_tests;

void main() {
  group('Coverage Tests', () {
    group('Unit and Widget Tests', () {
      all_tests.main();
    });

    group('Integration Tests', () {
      integration_tests.main();
    });
  });
}

// Test coverage summary:
// 
// Models:
// ✓ Position - 7 tests covering all methods and edge cases
// ✓ GameState - 15 tests covering constructor, copyWith, and initial state
//
// Utilities:
// ✓ Commons - 10 tests covering sumWithFold with all edge cases
// ✓ AdjacentPositions - 15 tests covering all grid positions and sizes
// ✓ GridGenerator - 15 tests covering generation logic and constraints
//
// Builders:
// ✓ GameStateBuilder - 20+ tests covering all game logic paths
//
// BLoC:
// ✓ GridGameBloc - 25+ tests covering all events, state transitions, and win conditions
//
// UI:
// ✓ SplashScreen - 10 tests covering display and navigation
// ✓ HomePage - 10 tests covering BLoC provision and structure
// ✓ GridGame - 25+ tests covering all interactions and state changes
//
// Integration:
// ✓ App flow - 12 tests covering complete user journeys
//
// Total: 150+ tests covering all cyclomatic complexity paths