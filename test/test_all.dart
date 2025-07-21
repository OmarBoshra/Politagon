import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'models/position_test.dart' as position_test;
import 'models/game_state_test.dart' as game_state_test;
import 'utilities/commons_test.dart' as commons_test;
import 'utilities/adjacent_positions_test.dart' as adjacent_positions_test;
import 'utilities/grid_generator_test.dart' as grid_generator_test;
import 'builders/game_state_builder_test.dart' as game_state_builder_test;
import 'bloc/grid_game_event_test.dart' as bloc_test;
import 'ui/splash_screen_test.dart' as splash_screen_test;
import 'ui/home_page_test.dart' as home_page_test;
import 'ui/grid_game_test.dart' as grid_game_test;

void main() {
  group('All Tests', () {
    group('Models', () {
      position_test.main();
      game_state_test.main();
    });

    group('Utilities', () {
      commons_test.main();
      adjacent_positions_test.main();
      grid_generator_test.main();
    });

    group('Builders', () {
      game_state_builder_test.main();
    });

    group('BLoC', () {
      bloc_test.main();
    });

    group('UI', () {
      splash_screen_test.main();
      home_page_test.main();
      grid_game_test.main();
    });
  });
}