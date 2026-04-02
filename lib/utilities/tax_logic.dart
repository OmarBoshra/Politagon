class TaxLogic {
  static List<List<Map<String, int>>> applyOwnershipTax({
    required List<List<Map<String, int>>> gridOwnership,
    required String playerId,
    required int winThreshold,
    required Map<String, int> playerTotals,
  }) {
    int totalPlayerPoints = playerTotals.values.fold(0, (sum, val) => sum + val);
    final excess = totalPlayerPoints - winThreshold;
    if (excess <= 0) return gridOwnership;

    final newGridOwnership = List.generate(gridOwnership.length, (i) =>
      List.generate(gridOwnership[i].length, (j) => Map<String, int>.from(gridOwnership[i][j]))
    );

    final otherPlayers = playerTotals.entries.where((e) => e.key != playerId && e.key != 'undecided').toList();
    final totalOthers = otherPlayers.fold(0, (sum, e) => sum + e.value);

    if (totalOthers > 0) {
      int remaining = excess;
      for (var entry in otherPlayers) {
        final share = (excess * entry.value ~/ totalOthers).clamp(0, entry.value);
        if (share > 0) {
          _transferDirect(newGridOwnership, entry.key, playerId, share);
          remaining -= share;
        }
      }
      if (remaining > 0) {
        otherPlayers.sort((a, b) => (playerTotals[b.key] ?? 0).compareTo(playerTotals[a.key] ?? 0));
        _transferDirect(newGridOwnership, otherPlayers.first.key, playerId, remaining);
      }
    }

    return newGridOwnership;
  }

  static void _transferDirect(List<List<Map<String, int>>> grid, String from, String to, int amount) {
    int rem = amount;
    for (var row in grid) {
      for (var cell in row) {
        if (rem <= 0) return;
        final count = cell[from] ?? 0;
        if (count > 0) {
          final take = (amount * count ~/ (amount + rem + 1)).clamp(0, count);
          if (take > 0) {
            cell[from] = count - take;
            cell[to] = (cell[to] ?? 0) + take;
            rem -= take;
          }
        }
      }
    }
  }
}
