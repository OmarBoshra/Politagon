import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/grid_game_event.dart';
import 'grid_game.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GridGameBloc(),
      child: Scaffold(
        body: GridGame(),
      ),
    );
  }
}