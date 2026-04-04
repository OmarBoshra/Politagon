import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../utilities/score_calculator.dart';
import '../bloc/grid_game_bloc.dart';
import '../bloc/grid_game_event.dart';

class GameDialogs {
  static void showPointStatus(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('POLITICAL CAPITAL AUDIT', style: TextStyle(color: Color(0xFFC5A059), letterSpacing: 1.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('National Pool: ${state.maxNationalPool} total points', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text('DISTRIBUTION BY CANDIDATE:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            const Divider(color: Colors.white10),
            ...state.players.map((p) {
              final score = ScoreCalculator.calculateScore(state, p.id);
              final pct = (score / state.maxNationalPool * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.name, style: const TextStyle(color: Colors.white60)),
                    Text('$score ($pct%)', style: const TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
            const Divider(color: Colors.white10),
            Text(
              'Unlocking Threshold: ${(state.maxNationalPool * state.decidedThresholdPercentage).ceil()} points (${(state.decidedThresholdPercentage * 100).toInt()}%)',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            Text(
              'Status: ${state.couldReachCenter == true ? "CENTER UNLOCKED" : "CENTER SEALED"}',
              style: TextStyle(
                color: state.couldReachCenter == true ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISMISS', style: TextStyle(color: Color(0xFFC5A059)))),
        ],
      ),
    );
  }

  static void showDossier(BuildContext context, {bool isFirstTime = false}) {
    showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC5A059), width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: Color(0xFFC5A059), size: 28),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE POLITAGON DOSSIER',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 18, letterSpacing: 2.0, color: Colors.white),
                        ),
                        Text(
                          isFirstTime ? 'NEW CANDIDATE ORIENTATION' : 'CLASSIFIED STRATEGY HANDBOOK',
                          style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStorySection(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: Colors.white10, thickness: 1),
                      ),
                      
                      _buildRuleSection(
                        '01. MOVEMENT & NAVIGATION',
                        'You move one square at a time in cardinal directions (Up, Down, Left, Right). Diagonal movement is impossible.',
                        Icons.open_with,
                        visual: _buildAdjacencyVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '02. CAPTURE & CONVERSION',
                        'Landing on a cell captures its "Political Capital" (points). You drain Undecided voters first, then take points from the weakest opponents on that cell.',
                        Icons.public,
                        visual: _buildCaptureVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '03. THE INF-POP BALANCE',
                        'Your stats change based on where you land. Land at the Center to gain Influence (INF) for the elite classes. Land at the Edges to gain Popularity (POP) among the masses. Gaining one usually drains the other.',
                        Icons.trending_up,
                        visual: _buildStatBalanceVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '04. THE SHUFFLING TIDE',
                        'The electorate is unstable. Every turn, points randomly shuffle between cells of the same social class. You must maintain presence in a class to keep your votes.',
                        Icons.shuffle,
                        visual: _buildShuffleVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '05. THE WIN CONDITION',
                        'The Center (Politagon) is locked initially. It unlocks once enough voters have decided. You can only enter the Center if you are the current leading Candidate.',
                        Icons.military_tech,
                        visual: _buildVictoryVisual(),
                      ),
                      const SizedBox(height: 32),

                      _buildRuleSection(
                        '06. OCCUPATION & COEXISTENCE',
                        'Multiple Candidates can occupy the same cell simultaneously. You do not block others, but the competition for local capital becomes fiercer.',
                        Icons.groups,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      if (isFirstTime) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_seen_rules_v1', true);
                      }
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC5A059)),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('I UNDERSTAND THE STAKES', style: TextStyle(color: Color(0xFFC5A059), letterSpacing: 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showWithdrawDialog(BuildContext context, String playerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('CONFIRM WITHDRAWAL', style: TextStyle(color: Colors.redAccent, letterSpacing: 1.5)),
        content: const Text('Are you sure you want to withdraw from the Politagon race? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              context.read<GridGameBloc>().add(WithdrawEvent(playerId));
              Navigator.pop(context);
            },
            child: const Text('WITHDRAW', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  static void showSquareStatus(BuildContext context, GameState state, Position pos) {
    final cell = state.gridOwnership[pos.x][pos.y];
    final centerIdx = state.gridSize ~/ 2;
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;
    final className = GameState.getSocialClassName(distance, maxDist);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(className.toUpperCase(), style: const TextStyle(color: Color(0xFFC5A059), letterSpacing: 1.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Position: (${pos.x}, ${pos.y})', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            const Text('VOTER DISTRIBUTION:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            const Divider(color: Colors.white10),
            ...cell.entries.where((e) => e.value > 0).map((e) {
              String name = e.key;
              if (e.key == 'undecided') name = 'Undecided';
              else {
                final p = state.players.firstWhere((player) => player.id == e.key, orElse: () => state.players.first);
                name = p.name;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white60)),
                    Text('${e.value}', style: const TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: Color(0xFFC5A059)))),
        ],
      ),
    );
  }

  static Widget _buildStorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE PREMISE',
          style: TextStyle(color: Color(0xFFC5A059), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: const Border(left: BorderSide(color: Color(0xFFC5A059), width: 2)),
          ),
          child: const Text(
            'In the wake of the Great Collapse, traditional governance dissolved into the Politagon—a high-stakes arena where power is defined by grid coordinates. As a Candidate, you must navigate a rigid social hierarchy, from the forgotten Outcasts on the fringes to the Inner Circle at the core. Will you court the elite to gain Influence, or rally the masses for raw Popularity? The path to the center remains sealed until the electorate reaches a breaking point. Outmaneuver your rivals, convert their followers, and ascend the classes. In this new world, power isn’t granted—it’s captured.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  static Widget _buildRuleSection(String title, String body, IconData icon, {Widget? visual}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFC5A059)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visual != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 12),
            child: visual,
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            body,
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  static Widget _buildAdjacencyVisual() {
    return Row(
      children: [
        Column(
          children: [
            _miniSquare(false),
            _miniSquare(true, isTarget: true),
            _miniSquare(false),
          ],
        ),
        Column(
          children: [
            _miniSquare(true, isTarget: true),
            _miniSquare(true, hasPlayer: true),
            _miniSquare(true, isTarget: true),
          ],
        ),
        Column(
          children: [
            _miniSquare(false),
            _miniSquare(true, isTarget: true),
            _miniSquare(false),
          ],
        ),
        const SizedBox(width: 20),
        const Icon(Icons.arrow_right_alt, color: Colors.white24),
        const SizedBox(width: 10),
        const Text('CARDINAL MOVES', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }

  static Widget _buildCaptureVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statBox('UNDECIDED', '1st', Colors.grey),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 14),
          _statBox('WEAK RIVAL', '2nd', Colors.redAccent.withOpacity(0.5)),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 14),
          _statBox('STRONG RIVAL', '3rd', Colors.redAccent),
        ],
      ),
    );
  }

  static Widget _buildStatBalanceVisual() {
    return Row(
      children: [
        _statEvolutionBox('CENTER', 'INF ↑', 'POP ↓', const Color(0xFFC5A059)),
        const SizedBox(width: 8),
        _statEvolutionBox('EDGE', 'POP ↑', 'INF ↓', Colors.blueAccent),
      ],
    );
  }

  static Widget _buildShuffleVisual() {
    return Row(
      children: [
        _miniSquare(true, color: Colors.indigo.withOpacity(0.3)),
        const Icon(Icons.sync, color: Color(0xFFC5A059), size: 16),
        _miniSquare(true, color: Colors.indigo.withOpacity(0.3)),
        const SizedBox(width: 12),
        const Text('SAME CLASS ONLY', style: TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  static Widget _buildVictoryVisual() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC5A059)),
        gradient: LinearGradient(colors: [const Color(0xFFC5A059).withOpacity(0.1), Colors.transparent]),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open, color: Color(0xFFC5A059), size: 16),
          SizedBox(width: 12),
          Text('UNLOCKABLE CENTER', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  static Widget _miniSquare(bool visible, {bool hasPlayer = false, bool isTarget = false, Color? color}) {
    return Container(
      width: 20, height: 20,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color ?? (visible ? Colors.white.withOpacity(0.05) : Colors.transparent),
        border: isTarget ? Border.all(color: const Color(0xFFC5A059), width: 1) : (visible ? Border.all(color: Colors.white10) : null),
      ),
      child: hasPlayer ? const Center(child: Icon(Icons.person, size: 12, color: Colors.white)) : null,
    );
  }

  static Widget _statBox(String label, String priority, Color color) {
    return Column(
      children: [
        Text(priority, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8)),
      ],
    );
  }

  static Widget _statEvolutionBox(String loc, String gain, String loss, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.03),
      child: Column(
        children: [
          Text(loc, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(gain, style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          Text(loss, style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
        ],
      ),
    );
  }
}
