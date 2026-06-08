import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';

class StatGrowthLogic {
  static (double influence, double popularity) calculateNewStats({
    required GameState state,
    required GamePlayerState player,
    required Position pos,
    required int actualCaptured,
    required int currentScore,
  }) {
    if (currentScore == 0 && actualCaptured == 0) {
      return (player.influence, player.popularity);
    }

    final centerIdx = state.gridSize ~/ 2;
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;
    final targetQuality = (maxDist + 1 - distance) / (maxDist + 1).toDouble();
    final extremeQuality = targetQuality * targetQuality;

    const double baseWeight = 1.0;
    final double currentWeight = currentScore.toDouble();
    final double totalWeight = currentWeight + actualCaptured + baseWeight;
    
    final double infContributionWeight = 0.15 + (0.70 * extremeQuality);
    final double popContributionWeight = 0.15 + (0.70 * (1.0 - extremeQuality));

    double newInfluence = (((player.influence * currentWeight) + (actualCaptured * infContributionWeight) + (0.1 * baseWeight)) / totalWeight);
    double newPopularity = (((player.popularity * currentWeight) + (actualCaptured * popContributionWeight) + (0.1 * baseWeight)) / totalWeight);

    // Dilution Logic: Staying in the same social class for more than 3 turns leads to stagnation and dilution of power.
    if (player.turnsInCurrentClass > 3) {
      final dilutionFactor = (1.0 - (0.05 * (player.turnsInCurrentClass - 3))).clamp(0.7, 1.0);
      newInfluence *= dilutionFactor;
      newPopularity *= dilutionFactor;
    }

    return (newInfluence.clamp(0.05, 1.0), newPopularity.clamp(0.05, 1.0));
  }
}
