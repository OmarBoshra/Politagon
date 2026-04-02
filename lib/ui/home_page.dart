import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/grid_game_bloc.dart';
import '../bloc/grid_game_event.dart';
import 'grid_game.dart';

class HomePage extends StatelessWidget {
  final List<String> humanNames;
  final bool ai1;
  final bool ai2;
  final bool ai3;
  final bool ai4;
  final bool ai5;
  final int gridSize;

  const HomePage({
    super.key,
    required this.humanNames,
    this.ai1 = true,
    this.ai2 = true,
    this.ai3 = false,
    this.ai4 = false,
    this.ai5 = false,
    this.gridSize = 5,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GridGameBloc(
        humanNames: humanNames,
        ai1: ai1,
        ai2: ai2,
        ai3: ai3,
        ai4: ai4,
        ai5: ai5,
        gridSize: gridSize,
      ),
      child: const GridGame(),
    );
  }
}
