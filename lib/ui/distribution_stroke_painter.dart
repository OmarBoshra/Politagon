import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/position.dart';

class GridBackgroundPainter extends CustomPainter {
  final GameState state;
  final List<(String id, Color color)> playerInfo;
  final Position? currentPlayerPos;
  final bool isHumanTurn;
  final bool isSpectating;
  final bool isUnlocked;

  GridBackgroundPainter({
    required this.state,
    required this.playerInfo,
    required this.currentPlayerPos,
    required this.isHumanTurn,
    required this.isSpectating,
    required this.isUnlocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / state.gridSize;
    final int centerIdx = state.gridSize ~/ 2;
    final int maxDist = centerIdx * 2;
    const double cellGap = 2.0;

    for (int i = 0; i < state.gridSize; i++) {
      for (int j = 0; j < state.gridSize; j++) {
        final pos = Position(i, j);
        final rect = Rect.fromLTWH(j * cellWidth, i * cellWidth, cellWidth, cellWidth);
        final innerRect = rect.deflate(cellGap);
        
        // 1. Draw Social Class Background
        final distance = (i - centerIdx).abs() + (j - centerIdx).abs();
        final palette = GameState.getSocialClassPalette(distance, maxDist);
        final isCenter = i == centerIdx && j == centerIdx;
        
        final bool isAdjacent = currentPlayerPos != null && 
                               (pos.x - currentPlayerPos!.x).abs() + (pos.y - currentPlayerPos!.y).abs() == 1;
        final bool isTappable = !isSpectating && isHumanTurn && state.winner == null && isAdjacent && (!isCenter || isUnlocked);

        final paint = Paint()
          ..color = palette[0].withOpacity(isTappable ? 0.9 : 0.6)
          ..style = PaintingStyle.fill;
        canvas.drawRect(innerRect, paint);

        // 2. Draw Borders/Strokes
        if (isCenter) {
          _drawCenterFrame(canvas, innerRect, isUnlocked);
        } else {
          _drawOwnershipStrokes(canvas, innerRect, state.gridOwnership[i][j], isTappable, playerInfo);
        }
      }
    }
  }

  void _drawCenterFrame(Canvas canvas, Rect rect, bool unlocked) {
    final gold = const Color(0xFFC5A059);
    final paint = Paint()
      ..color = unlocked ? gold : gold.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unlocked ? 2.5 : 1.5;
    canvas.drawRect(rect.deflate(1), paint);
  }

  void _drawOwnershipStrokes(Canvas canvas, Rect rect, Map<String, int> ownership, bool isActive, List<(String, Color)> playerInfo) {
    final total = ownership.values.fold(0, (sum, v) => sum + v);
    final strokeWidth = isActive ? 3.0 : 1.5;
    
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRect(rect.deflate(1), paint);
      return;
    }

    final perimeter = rect.width * 4;
    double currentDist = 0;

    // Undecided
    final undecided = ownership['undecided'] ?? 0;
    if (undecided > 0) {
      final length = (undecided / total) * perimeter;
      _drawSegment(canvas, rect, currentDist, length, Colors.grey.withOpacity(isActive ? 0.8 : 0.3), strokeWidth);
      currentDist += length;
    }

    // Players
    for (var p in playerInfo) {
      final share = ownership[p.$1] ?? 0;
      if (share > 0) {
        final length = (share / total) * perimeter;
        _drawSegment(canvas, rect, currentDist, length, p.$2.withOpacity(isActive ? 1.0 : 0.6), strokeWidth);
        currentDist += length;
      }
    }
  }

  void _drawSegment(Canvas canvas, Rect rect, double start, double length, Color color, double width) {
    if (length <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final w = rect.width;
    final h = rect.height;
    final perimeter = 2 * w + 2 * h;
    
    double remaining = length;
    double current = start % perimeter;

    while (remaining > 0) {
      Offset p1 = _getPointOnRect(rect, current);
      Offset p2;
      double step;

      if (current < w) {
        step = min(remaining, w - current);
        p2 = Offset(rect.left + current + step, rect.top);
      } else if (current < w + h) {
        step = min(remaining, (w + h) - current);
        p2 = Offset(rect.right, rect.top + (current - w) + step);
      } else if (current < 2 * w + h) {
        step = min(remaining, (2 * w + h) - current);
        p2 = Offset(rect.right - (current - (w + h) + step), rect.bottom);
      } else {
        step = min(remaining, perimeter - current);
        p2 = Offset(rect.left, rect.bottom - (current - (2 * w + h) + step));
      }
      
      canvas.drawLine(p1, p2, paint);
      current = (current + step) % perimeter;
      remaining -= step;
      if (step <= 0) break; 
    }
  }

  Offset _getPointOnRect(Rect rect, double d) {
    final w = rect.width;
    final h = rect.height;
    if (d <= w) return Offset(rect.left + d, rect.top);
    if (d <= w + h) return Offset(rect.right, rect.top + (d - w));
    if (d <= 2 * w + h) return Offset(rect.right - (d - (w + h)), rect.bottom);
    return Offset(rect.left, rect.bottom - (d - (2 * w + h)));
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) {
    return oldDelegate.state != state || 
           oldDelegate.currentPlayerPos != currentPlayerPos ||
           oldDelegate.isHumanTurn != isHumanTurn ||
           oldDelegate.isUnlocked != isUnlocked;
  }
}

class CellGlowPainter extends CustomPainter {
  final double glowValue;
  final Color color;

  CellGlowPainter({required this.glowValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final gold = const Color(0xFFC5A059);
    final coreGold = const Color(0xFFFFD700);

    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          coreGold.withOpacity(0.6 * glowValue),
          gold.withOpacity(0.3 * glowValue),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
    
    canvas.drawCircle(center, size.width * 0.6 * (0.9 + 0.1 * glowValue), sunPaint);
  }

  @override
  bool shouldRepaint(covariant CellGlowPainter oldDelegate) => oldDelegate.glowValue != glowValue;
}
