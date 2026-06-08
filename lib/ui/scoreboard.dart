import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../utilities/score_calculator.dart';
import 'grid_game.dart';
import 'player_icon.dart';
import 'game_dialogs.dart';

class Scoreboard extends StatefulWidget {
  final GameState state;
  final Animation<double> glowAnimation;
  final bool isLandscape;
  final String currentPlayerId;

  const Scoreboard({
    super.key,
    required this.state,
    required this.glowAnimation,
    this.isLandscape = false,
    required this.currentPlayerId,
  });

  @override
  State<Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<Scoreboard> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPlayer();
    });
  }

  @override
  void didUpdateWidget(Scoreboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPlayerId != widget.currentPlayerId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentPlayer();
      });
    }
  }

  void _scrollToCurrentPlayer() {
    final index = widget.state.players.indexWhere((p) => p.id == widget.currentPlayerId);
    if (index == -1) return;

    if (!_scrollController.hasClients) return;

    // Get the current scroll position info
    final maxExtent = _scrollController.position.maxScrollExtent;
    final viewportDimension = _scrollController.position.viewportDimension;
    
    // If content fits in viewport, no need to scroll
    if (maxExtent <= 0) return;

    // Calculate scroll position: distribute remaining space evenly between cards
    // For spacing, assume each card + padding takes approximately equal space
    final numCards = widget.state.players.length;
    final totalContentSize = maxExtent + viewportDimension;
    final cardSize = totalContentSize / numCards;
    
    // Target position: center of the current player's card in the viewport
    final cardCenterPosition = (index * cardSize) + (cardSize / 2);
    final viewportCenter = viewportDimension / 2;
    final targetScroll = (cardCenterPosition - viewportCenter).clamp(0.0, maxExtent);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollAxis = widget.isLandscape ? Axis.vertical : Axis.horizontal;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(bottom: BorderSide(color: Color(0xFFC5A059), width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: scrollAxis,
        controller: _scrollController,
        child: widget.isLandscape
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.state.players.map((p) {
                  final score = ScoreCalculator.calculateScore(widget.state, p.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: _ScoreItem(
                      player: p,
                      score: score,
                      isCurrentTurn: p.id == widget.currentPlayerId,
                      state: widget.state,
                      glowAnimation: widget.glowAnimation,
                    ),
                  );
                }).toList(),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.state.players.map((p) {
                  final score = ScoreCalculator.calculateScore(widget.state, p.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: _ScoreItem(
                      player: p,
                      score: score,
                      isCurrentTurn: p.id == widget.currentPlayerId,
                      state: widget.state,
                      glowAnimation: widget.glowAnimation,
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
    final isHuman = player.type == PlayerType.human;

    final card = Container(
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
        ],
      ),
    );

    if (!isHuman) return card;

    return InkWell(
      onTap: () => GameDialogs.showPlayerStatus(context, state, player),
      borderRadius: BorderRadius.circular(4),
      child: card,
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
