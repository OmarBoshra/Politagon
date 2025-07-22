// Quick demo to test the glow effect
// Run with: flutter run test_glow_demo.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:politagon/bloc/grid_game_event.dart';
import 'package:politagon/models/position.dart';
import 'package:politagon/ui/grid_game.dart';

void main() {
  runApp(GlowTestApp());
}

class GlowTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glow Test',
      home: BlocProvider(
        create: (_) {
          final bloc = GridGameBloc();
          // Set scores to trigger glow effect
          bloc.emit(bloc.state.copyWith(
            scores: {'user': 40, 'ai1': 35, 'ai2': 25}, // Total = 100
            couldReachCenter: false, // This should trigger the glow
          ));
          return bloc;
        },
        child: Scaffold(
          appBar: AppBar(title: Text('Glow Effect Test')),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'The center cell should glow when total score = 100!\nMake a move to trigger the glow effect.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Expanded(child: GridGame()),
            ],
          ),
        ),
      ),
    );
  }
}