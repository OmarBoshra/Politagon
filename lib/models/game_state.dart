import 'package:flutter/material.dart';
import 'package:politagon/models/position.dart';
import 'game_player_state.dart';

class GameState {
  final List<List<int>> grid;
  final List<List<Map<String, int>>> gridOwnership;
  final List<List<String?>> gridMajority;
  final List<GamePlayerState> players;
  final String turn;
  final String? winner;
  final bool? couldReachCenter;
  final int gridSize;

  final bool isSpectating;
  final String? spectatedPlayerId;
  final bool stepByStepMode;

  GameState({
    required this.grid,
    required this.gridOwnership,
    required this.gridMajority,
    required this.players,
    required this.turn,
    required this.gridSize,
    this.winner,
    this.couldReachCenter,
    this.isSpectating = false,
    this.spectatedPlayerId,
    this.stepByStepMode = false,
  });

  int get winThreshold => (maxNationalPool * 0.75).ceil();
  int get maxNationalPool => gridSize * gridSize * 4;

  GameState copyWith({
    List<List<int>>? grid,
    List<List<Map<String, int>>>? gridOwnership,
    List<List<String?>>? gridMajority,
    List<GamePlayerState>? players,
    String? turn,
    int? gridSize,
    String? winner,
    bool? couldReachCenter,
    bool? isSpectating,
    String? spectatedPlayerId,
    bool? stepByStepMode,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      gridOwnership: gridOwnership ?? this.gridOwnership,
      gridMajority: gridMajority ?? this.gridMajority,
      players: players ?? this.players,
      turn: turn ?? this.turn,
      gridSize: gridSize ?? this.gridSize,
      winner: winner ?? this.winner,
      couldReachCenter: couldReachCenter ?? this.couldReachCenter,
      isSpectating: isSpectating ?? this.isSpectating,
      spectatedPlayerId: spectatedPlayerId ?? this.spectatedPlayerId,
      stepByStepMode: stepByStepMode ?? this.stepByStepMode,
    );
  }

  static String getSocialClassName(int distance, int maxDist) {
    if (distance == 0) return 'The Politagon';
    
    const titles = [
      'The Politagon', 'High Council', 'Inner Circle', 'Aristocracy', 'Patricians',
      'The Nobility', 'Gentry', 'Magistrates', 'Burgesses', 'The Guilds',
      'Middle Class', 'Artisans', 'Freeholders', 'The Commonry', 'Laymen',
      'Peasantry', 'The Proletariat', 'Serfs', 'The Poor', 'Outcasts', 'The Forgotten',
    ];

    if (distance < titles.length) {
      if (distance == maxDist) return 'The Underclass';
      return titles[distance];
    }
    
    return 'Level $distance';
  }

  static List<Color> getSocialClassPalette(int distance, int maxDist) {
    // Distance 0 is the center (The Politagon). 
    // We use a deep "Obsidian" background so the golden chair and sun-glow pop.
    if (distance == 0) return [const Color(0xFF0D0D0D), const Color(0xFF1A1A1A)]; 

    const baseColors = [
      Color(0xFF1A237E), // Deep Indigo (High Council)
      Color(0xFF4A148C), // Purple (Inner Circle)
      Color(0xFF01579B), // Blue (Aristocracy)
      Color(0xFF006064), // Cyan/Teal (Patricians)
      Color(0xFF1B5E20), // Green (Middle Class)
      Color(0xFF827717), // Olive (Artisans)
      Color(0xFFF57F17), // Orange/Amber (Commonry)
      Color(0xFFE65100), // Deep Orange (Peasantry)
      Color(0xFF3E2723), // Brown (Serfs)
      Color(0xFF212121), // Charcoal (Underclass)
    ];

    if (maxDist <= 0) return [baseColors[0], baseColors[0]];

    final double ratio = (distance - 1) / (maxDist == 1 ? 1 : maxDist - 1);
    final double scaledRatio = ratio.clamp(0.0, 1.0) * (baseColors.length - 1);
    final int index = scaledRatio.floor();
    final int nextIndex = (index + 1).clamp(0, baseColors.length - 1);
    final double localRatio = scaledRatio - index;

    final primary = Color.lerp(baseColors[index], baseColors[nextIndex], localRatio)!;
    final secondary = Color.lerp(primary, Colors.white, 0.2)!;

    return [primary, secondary];
  }

  static IconData getSocialClassIcon(int distance, int maxDist) {
    if (distance == 0) return Icons.account_balance; // The Politagon
    
    final ratio = distance / maxDist;
    if (ratio < 0.2) return Icons.stars;
    if (ratio < 0.4) return Icons.gavel;
    if (ratio < 0.6) return Icons.work;
    if (ratio < 0.8) return Icons.groups;
    return Icons.person_outline;
  }
}
