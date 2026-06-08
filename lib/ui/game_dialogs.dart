import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../utilities/score_calculator.dart';
import '../bloc/grid_game_bloc.dart';
import '../bloc/grid_game_event.dart';
import 'player_icon.dart';
import 'grid_game.dart';

class GameDialogs {
  static String _classIconAsset(int distance) {
    final d = distance.clamp(0, 20);
    return 'assets/svg/classes/class_$d.svg';
  }

  static Map<int, int> _calculateUndecidedByLevel(GameState state) {
    final centerIdx = state.gridSize ~/ 2;
    final result = <int, int>{};
    for (int i = 0; i < state.gridSize; i++) {
      for (int j = 0; j < state.gridSize; j++) {
        final cell = state.gridOwnership[i][j];
        final undecided = cell['undecided'] ?? 0;
        if (undecided <= 0) continue;
        final distance = (i - centerIdx).abs() + (j - centerIdx).abs();
        result[distance] = (result[distance] ?? 0) + undecided;
      }
    }
    return result;
  }

  static Widget _buildDialogHeader(BuildContext context, String title, {String? subtitle, Widget? leading}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
                if (subtitle != null)
                  Text(
                    subtitle.toUpperCase(),
                    style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFC5A059)),
            padding: const EdgeInsets.all(16),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: const Text('✓', style: TextStyle(color: Color(0xFFC5A059), letterSpacing: 2)),
        ),
      ),
    );
  }

  static void showPointStatus(BuildContext context, GameState state) {
    final int totalPoints = state.maxNationalPool;
    final int totalDecided = ScoreCalculator.calculateTotalPlayerScore(state);
    final int undecidedPoints = totalPoints - totalDecided;
    final double undecidedPct = (undecidedPoints / (totalPoints <= 0 ? 1 : totalPoints)) * 100;
    final int centerIdx = state.gridSize ~/ 2;
    final int maxDist = centerIdx * 2;
    final undecidedByLevel = _calculateUndecidedByLevel(state);
    final undecidedDistances = undecidedByLevel.keys.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC5A059), width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        child: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                context, 
                'POLITICAL CAPITAL', 
                subtitle: 'NATIONAL POOL: $totalPoints PTS', 
                leading: const Icon(Icons.pie_chart_outline, color: Color(0xFFC5A059), size: 28),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
                          title: Text(
                            'UNDECIDED CAPITAL: $undecidedPoints (${undecidedPct.toStringAsFixed(1)}%)',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          children: undecidedDistances.isEmpty
                              ? [const Text('No undecided capital', style: TextStyle(color: Colors.white24, fontSize: 11))]
                              : undecidedDistances.map((dist) {
                                  final points = undecidedByLevel[dist] ?? 0;
                                  final className = GameState.getSocialClassName(dist, maxDist);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(_classIconAsset(dist), width: 14, height: 14),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(className, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                                        ),
                                        Text('$points', style: const TextStyle(color: Color(0xFFC5A059), fontSize: 11)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('DISTRIBUTION BY CANDIDATE:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                      const Divider(color: Colors.white10),
                      ...state.players.map((p) {
                        final score = ScoreCalculator.calculateScore(state, p.id);
                        final pct = (score / (state.maxNationalPool <= 0 ? 1 : state.maxNationalPool) * 100).toStringAsFixed(1);
                        final scoreByLevel = ScoreCalculator.calculateScoreByLevel(state, p.id);
                        final sortedDistances = scoreByLevel.keys.toList()..sort();

                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      PlayerIcon(player: p, size: 16, isCurrentTurn: false),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                                Text('$pct%', style: const TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            subtitle: Text('Score: $score pts', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            children: sortedDistances.isEmpty 
                              ? [const Padding(padding: EdgeInsets.all(8.0), child: Text('No capital held', style: TextStyle(color: Colors.white24, fontSize: 10)))]
                              : sortedDistances.map((dist) {
                                  final points = scoreByLevel[dist]!;
                                  final className = GameState.getSocialClassName(dist, maxDist);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                _classIconAsset(dist),
                                                width: 14,
                                                height: 14,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(className, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                        ),
                                        Text('$points', style: const TextStyle(color: Color(0xFFC5A059), fontSize: 11)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  static void showDossier(BuildContext context, {bool isFirstTime = false}) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 600 ? 500.0 : width * 0.9;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

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
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                context, 
                isAndroid ? 'THE DOSSIER' : 'THE POLITAGON DOSSIER', 
                subtitle: isFirstTime ? 'NEW CANDIDATE ORIENTATION' : 'STRATEGY HANDBOOK', 
                leading: const Icon(Icons.menu_book, color: Color(0xFFC5A059), size: 28),
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
                        '01. MOVEMENT',
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
                        '03. THE WIN CONDITION',
                        'The Center (Politagon) is locked initially. It unlocks once enough voters have decided. You can only enter the Center if you are the current leading Candidate.',
                        Icons.military_tech,
                        visual: _buildVictoryVisual(),
                      ),
                      const SizedBox(height: 32),

                      _buildRuleSection(
                        '04. THE INF-POP BALANCE',
                        'Your stats evolve based on your movement. Near the Center, you gain Influence (INF) for elites, which also helps sway lower classes. At the Edges, you gain Popularity (POP) for the masses, which aids in courting higher tiers. Beware: staying in the same social class for too long dilutes your impact through political stagnation.',
                        Icons.trending_up,
                        visual: _buildStatBalanceVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '05. THE SHUFFLING TIDE',
                        'The electorate is unstable. Every turn, points randomly shuffle between cells of the same social class. You must maintain presence in a class to keep your votes.',
                        Icons.shuffle,
                        visual: _buildShuffleVisual(),
                      ),
                      const SizedBox(height: 32),


                      _buildRuleSection(
                        '06. OCCUPATION',
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
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('✓', style: TextStyle(color: Color(0xFFC5A059), letterSpacing: 2)),
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
    final bloc = context.read<GridGameBloc>();
    showDialog(
      context: context,
      builder: (innerContext) => Dialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.redAccent, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                context, 
                'CONFIRM WITHDRAWAL', 
                leading: const Icon(Icons.warning_amber, color: Colors.redAccent, size: 28)
              ),
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Are you sure you want to withdraw from the Politagon race? This action cannot be undone.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(innerContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.all(16),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: const Text('CANCEL', style: TextStyle(color: Colors.white38, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          bloc.add(WithdrawEvent(playerId));
                          Navigator.pop(innerContext);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.all(16),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: const Text('WITHDRAW', style: TextStyle(color: Colors.redAccent, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showPlayerStatus(BuildContext context, GameState state, GamePlayerState player) {
    final score = ScoreCalculator.calculateScore(state, player.id);
    final pct = state.maxNationalPool <= 0 ? 0.0 : (score / state.maxNationalPool) * 100;
    final centerIdx = state.gridSize ~/ 2;
    final maxDist = centerIdx * 2;
    final scoreByLevel = ScoreCalculator.calculateScoreByLevel(state, player.id);
    final sortedDistances = scoreByLevel.keys.toList()..sort();

    final canWithdraw =
        !state.isSpectating &&
        state.winner == null &&
        player.type == PlayerType.human &&
        state.players.length > 1 &&
        state.turn == player.id;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC5A059), width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                context, 
                player.name, 
                subtitle: 'SCORE: $score PTS (${pct.toStringAsFixed(1)}%)', 
                leading: PlayerIcon(player: player, size: 28, isCurrentTurn: false),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DISTRIBUTION AMONG CLASSES:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                      const Divider(color: Colors.white10),
                      if (sortedDistances.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No capital held', style: TextStyle(color: Colors.white24, fontSize: 11)),
                        )
                      else
                        ...sortedDistances.map((dist) {
                          final points = scoreByLevel[dist]!;
                          final className = GameState.getSocialClassName(dist, maxDist);
                          final classPct = score <= 0 ? 0 : ((points / score) * 100).round();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SvgPicture.asset(_classIconAsset(dist), width: 14, height: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(className, style: const TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Text('$classPct%', style: const TextStyle(color: Color(0xFFC5A059), fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Text('$points', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: canWithdraw 
                  ? OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        showWithdrawDialog(context, player.id);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.all(16),
                        minimumSize: const Size(double.infinity, 54),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('WITHDRAW FROM RACE', style: TextStyle(color: Colors.redAccent, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    )
                  : _buildCloseButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSquareStatus(BuildContext context, GameState state, Position pos) {
    final cell = state.gridOwnership[pos.x][pos.y];
    final centerIdx = state.gridSize ~/ 2;
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;
    final className = GameState.getSocialClassName(distance, maxDist);
    final entries = cell.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC5A059), width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                context, 
                className, 
                subtitle: 'POSITION: (${pos.x}, ${pos.y})', 
                leading: SvgPicture.asset(_classIconAsset(distance), width: 28, height: 28),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VOTER DISTRIBUTION:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                      const Divider(color: Colors.white10),
                      ...entries.map((e) {
                        String name = e.key;
                        GamePlayerState? player;
                        if (e.key == 'undecided') name = 'Undecided';
                        else {
                          player = state.players.firstWhere((p) => p.id == e.key, orElse: () => state.players.first);
                          name = player.name;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (player != null) ...[
                                      PlayerIcon(player: player, size: 14, isCurrentTurn: false),
                                      const SizedBox(width: 8),
                                    ] else ...[
                                      const Icon(Icons.help_outline, size: 14, color: Colors.white24),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(child: Text(name, style: const TextStyle(color: Colors.white60), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.value}', style: const TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              _buildCloseButton(context),
            ],
          ),
        ),
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
            'After the Great economic Collapse, governance was replaced by the Politagon, a ruthless arena where power is measured by grid position. As a Candidate, you must climb a strict hierarchy, from Outcasts to the Inner Circle. Will you gain Influence by courting elites, or build Popularity with the masses? The center remains locked until tensions peak. Outsmart rivals, convert followers, and rise—because in this world, power is acquired, not granted.',
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                overflow: TextOverflow.ellipsis,
              ),
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
        const Flexible(child: Text('CARDINAL MOVES', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1))),
      ],
    );
  }

  static Widget _buildCaptureVisual() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
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
        const Flexible(child: Text('SAME CLASS ONLY', style: TextStyle(color: Colors.white24, fontSize: 10))),
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
          Flexible(child: Text('UNLOCKABLE CENTER', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
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

  static void showMaturityStats(BuildContext context, GameState state) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 600 ? 600.0 : width * 0.95;

    double totalInfluence = state.players.fold(0.0, (sum, p) => sum + p.influence);
    double totalPopularity = state.players.fold(0.0, (sum, p) => sum + p.popularity);
    
    if (totalInfluence == 0) totalInfluence = 1;
    if (totalPopularity == 0) totalPopularity = 1;

    final int threshold = (state.maxNationalPool * state.decidedThresholdPercentage).ceil();
    final int totalDecided = ScoreCalculator.calculateTotalPlayerScore(state);
    final double maturityProgress = (totalDecided / (threshold <= 0 ? 1 : threshold)).clamp(0.0, 1.0);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC5A059), width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                context, 
                'CAMPAIGN MATURITY', 
                subtitle: 'NATIONAL DECISION PROGRESS',
                leading: const Icon(Icons.trending_up, color: Color(0xFFC5A059), size: 28)
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMaturityStatSection('INFLUENCE DISTRIBUTION', totalInfluence, state.players, (p) => p.influence, Colors.blueAccent),
                      const SizedBox(height: 24),
                      _buildMaturityStatSection('POPULARITY DISTRIBUTION', totalPopularity, state.players, (p) => p.popularity, const Color(0xFFC5A059)),
                      const SizedBox(height: 24),
                      _buildMaturityProgressSection(state, maturityProgress, totalDecided),
                    ],
                  ),
                ),
              ),
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMaturityStatSection(String title, double total, List<GamePlayerState> players, double Function(GamePlayerState) getter, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: titleColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Row(
            children: players.where((p) => getter(p) > 0).map((p) {
              final percentage = (getter(p) / total).clamp(0.0, 1.0);
              return Flexible(
                flex: (percentage * 100).toInt().clamp(1, 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: GridGame.getGlobalPlayerColor(p),
                    border: Border(right: BorderSide(color: const Color(0xFF0D1117).withOpacity(0.5), width: 0.5)),
                  ),
                  child: Center(
                    child: Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static Widget _buildMaturityProgressSection(GameState state, double progress, int totalDecided) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MATURITY TOWARDS CENTER', style: TextStyle(color: Color(0xFFC5A059), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Row(
            children: [
              ...state.players.map((p) {
                final score = ScoreCalculator.calculateScore(state, p.id);
                if (score <= 0) return const SizedBox.shrink();
                final percentage = (score / (totalDecided <= 0 ? 1 : totalDecided)).clamp(0.0, 1.0) * progress;
                if (percentage <= 0) return const SizedBox.shrink();
                return Flexible(
                  flex: (percentage * 100).toInt().clamp(1, 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: GridGame.getGlobalPlayerColor(p),
                      border: Border(right: BorderSide(color: const Color(0xFF0D1117).withOpacity(0.5), width: 0.5)),
                    ),
                    child: Center(
                      child: Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ),
                );
              }),
              if (progress < 1.0)
                Flexible(
                  flex: ((1 - progress) * 100).toInt().clamp(1, 100),
                  child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.03))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
