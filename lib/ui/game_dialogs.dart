import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../utilities/score_calculator.dart';
import '../bloc/grid_game_bloc.dart';
import '../bloc/grid_game_event.dart';
import 'grid_game.dart';
import 'player_icon.dart';

class GameDialogs {
  static void showPointStatus(BuildContext context, GameState state) {
    final totalPoints = ScoreCalculator.calculateTotalScore(state);
    final maxDist = (state.gridSize ~/ 2) * 2;

    // Calculate Undecided points per class
    final undecidedByLevel = <int, int>{};
    for (int i = 0; i < state.gridSize; i++) {
      for (int j = 0; j < state.gridSize; j++) {
        final cell = state.gridOwnership[i][j];
        final points = cell['undecided'] ?? 0;
        if (points > 0) {
          final distance = (i - (state.gridSize ~/ 2)).abs() + (j - (state.gridSize ~/ 2)).abs();
          undecidedByLevel[distance] = (undecidedByLevel[distance] ?? 0) + points;
        }
      }
    }
    final totalUndecided = undecidedByLevel.values.fold(0, (sum, v) => sum + v);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFC5A059), width: 1),
        ),
        title: const Text(
          'POLITICAL LANDSCAPE',
          style: TextStyle(
            color: Color(0xFFC5A059),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('TOTAL CAPITAL', '$totalPoints', Colors.white),
                _buildSummaryRow('THRESHOLD', '${state.winThreshold}', Colors.white70),
                const SizedBox(height: 20),
                
                // UNDECIDED SECTION
                _buildSectionHeader('UNDECIDED CONSTITUENCY', Colors.grey, Icons.help_outline),
                _buildLevelBreakdown(undecidedByLevel, maxDist, Colors.grey),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10),
                ),

                // PLAYERS SECTION
                ...state.players.map((p) {
                  final score = ScoreCalculator.calculateScore(state, p.id);
                  final pointsByLevel = ScoreCalculator.calculateScoreByLevel(state, p.id);
                  final playerColor = GridGame.getGlobalPlayerColor(p);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PlayerIcon(player: p, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name.toUpperCase(),
                                style: TextStyle(color: playerColor, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                            Text(
                              '$score',
                              style: TextStyle(color: playerColor, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildLevelBreakdown(pointsByLevel, maxDist, playerColor),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('DISMISS', style: TextStyle(color: Color(0xFFC5A059), letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 10, letterSpacing: 1)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  static Widget _buildLevelBreakdown(Map<int, int> pointsByLevel, int maxDist, Color themeColor) {
    if (pointsByLevel.isEmpty) {
      return const Text('NO INFLUENCE IN ANY CLASS', style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic));
    }

    return Container(
      padding: const EdgeInsets.only(left: 36),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: themeColor.withOpacity(0.2), width: 1)),
      ),
      child: Column(
        children: pointsByLevel.entries.map((entry) {
          final className = GameState.getSocialClassName(entry.key, maxDist);
          final classPalette = GameState.getSocialClassPalette(entry.key, maxDist);
          final classIcon = GameState.getSocialClassIcon(entry.key, maxDist);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(classIcon, size: 12, color: classPalette[0]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    className, 
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)
                  ),
                ),
                Text(
                  '${entry.value}', 
                  style: TextStyle(color: classPalette[0], fontSize: 11, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static void showSquareStatus(BuildContext context, GameState state, Position pos) {
    final ownership = state.gridOwnership[pos.x][pos.y];
    final totalInCell = ownership.values.fold(0, (sum, v) => sum + v);
    
    final centerIdx = state.gridSize ~/ 2;
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;
    final className = GameState.getSocialClassName(distance, maxDist);
    final classPalette = GameState.getSocialClassPalette(distance, maxDist);
    final classIcon = GameState.getSocialClassIcon(distance, maxDist);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: classPalette[0], width: 1),
        ),
        title: Row(
          children: [
            Icon(classIcon, color: classPalette[0], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className.toUpperCase(), 
                    style: TextStyle(color: classPalette[0], fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)
                  ),
                  Text('COORDINATES: [${pos.x},${pos.y}]', style: const TextStyle(color: Colors.white24, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LOCAL CAPITAL', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('$totalInCell', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10),
            ),
            if (ownership['undecided'] != null && ownership['undecided']! > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Undecided', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Text('${ownership['undecided']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ...state.players.map((p) {
              final count = ownership[p.id] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              final color = GridGame.getGlobalPlayerColor(p);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    PlayerIcon(player: p, size: 16),
                    const SizedBox(width: 10),
                    Text(p.name, style: TextStyle(color: color, fontSize: 13)),
                    const Spacer(),
                    Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CLOSE', style: TextStyle(color: Color(0xFFC5A059)))),
        ],
      ),
    );
  }

  static void showWithdrawDialog(BuildContext context, String playerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('WITHDRAW FROM RACE', style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to withdraw from the election?\n\n'
          'Your votes will be discarded and the remaining candidates will continue. '
          'If the remaining candidates\' total score falls below the threshold, the center will be locked again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              context.read<GridGameBloc>().add(WithdrawEvent(playerId));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('WITHDRAW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
