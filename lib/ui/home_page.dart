import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/grid_game_event.dart';
import 'grid_game.dart';

class HomePage extends StatelessWidget {
  final List<String> humanNames;
  final bool ai1;
  final bool ai2;
  final bool ai3;
  final bool ai4;
  final int gridSize;

  const HomePage({
    super.key, 
    required this.humanNames, 
    required this.ai1, 
    required this.ai2, 
    this.ai3 = false, 
    this.ai4 = false,
    required this.gridSize
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GridGameBloc(
        humanNames: humanNames, 
        ai1: ai1, 
        ai2: ai2, 
        ai3: ai3, 
        ai4: ai4,
        gridSize: gridSize
      ),
      child: const Scaffold(
        body: GridGame(),
      ),
    );
  }
}
