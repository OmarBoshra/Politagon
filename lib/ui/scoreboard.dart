import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../utilities/score_calculator.dart';
import 'grid_game.dart';
import 'player_icon.dart';
import 'game_dialogs.dart';

class Scoreboard extends StatelessWidget {
  final GameState state;
  final Animation<double> glowAnimation;

  const Scoreboard({
    super.key,
    required this.state,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(bottom: BorderSide(color: Color(0xFFC5A059), width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: state.players.map((p) {
            final score = ScoreCalculator.calculateScore(state, p.id);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _ScoreItem(
                player: p,
                score: score,
                isCurrentTurn: p.id == state.turn,
                state: state,
                glowAnimation: glowAnimation,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final GamePlayerState player;
  final int score;
  final bool isCurrentTurn;
  final GameState state;
  final Animation<double> glowAnimation;

  const _ScoreItem({
    required this.player,
    required this.score,
    required this.isCurrentTurn,
    required this.state,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = GridGame.getGlobalPlayerColor(player);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTurn ? playerColor.withOpacity(0.08) : Colors.transparent,
        border: Border.all(color: isCurrentTurn ? playerColor.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(children: [
            PlayerIcon(player: player, size: 14.0, isCurrentTurn: false), 
            const SizedBox(width: 6), 
            Text(player.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isCurrentTurn ? playerColor : Colors.white70, fontSize: 10))
          ]),
          const SizedBox(height: 4),
          Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
          const SizedBox(height: 4),
          Row(
            children: [
              _MiniStat(label: 'INF', value: player.influence, color: Colors.blueAccent),
              const SizedBox(width: 8),
              _MiniStat(label: 'POP', value: player.popularity, color: const Color(0xFFC5A059)),
            ],
          ),
          if (!state.isSpectating && isCurrentTurn && player.type == PlayerType.human && state.players.length > 1)
            GestureDetector(
              onTap: () => GameDialogs.showWithdrawDialog(context, player.id),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1), borderRadius: BorderRadius.circular(3)),
                child: const Text('WITHDRAW', style: TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 7, fontWeight: FontWeight.bold)),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
