import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../bloc/grid_game_bloc.dart';
import '../bloc/grid_game_event.dart';

class SpectatorControls extends StatelessWidget {
  final GameState state;

  const SpectatorControls({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final allAi = state.players.every((p) => p.type != PlayerType.human);
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('AI BATTLE MODE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(width: 16),
          if (allAi && state.winner == null)
            ElevatedButton.icon(
              onPressed: () => context.read<GridGameBloc>().add(AiMoveEvent(state.turn)),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('NEXT TURN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}
