import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import 'grid_game.dart';

class DistributionStrokePainter extends CustomPainter {
  final GameState state;
  final Position pos;
  final double strokeWidth;
  final bool isActive;
  final bool isCenter;
  final bool showGlow;
  final double glowValue;

  DistributionStrokePainter({
    required this.state, 
    required this.pos, 
    this.strokeWidth = 2.0, 
    this.isActive = false,
    this.isCenter = false,
    this.showGlow = false,
    this.glowValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (isCenter) {
      _paintThePolitagonSeat(canvas, size, rect);
      return;
    }

    final ownership = state.gridOwnership[pos.x][pos.y];
    final total = ownership.values.fold(0, (sum, v) => sum + v);
    
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRect(rect, paint);
      return;
    }

    final segments = <StrokeSegment>[];
    final undecided = ownership['undecided'] ?? 0;
    if (undecided > 0) {
      segments.add(StrokeSegment(undecided / total, Colors.grey.withOpacity(isActive ? 0.8 : 0.3)));
    }

    for (var player in state.players) {
      final share = ownership[player.id] ?? 0;
      if (share > 0) {
        segments.add(StrokeSegment(share / total, GridGame.getGlobalPlayerColor(player).withOpacity(isActive ? 1.0 : 0.6)));
      }
    }

    double currentProgress = 0.0;
    final perimeter = size.width * 2 + size.height * 2;

    for (var segment in segments) {
      final segmentLength = segment.ratio * perimeter;
      final startDist = currentProgress;
      final endDist = currentProgress + segmentLength;
      
      _drawSegment(canvas, size, startDist, endDist, segment.color, strokeWidth);
      currentProgress += segmentLength;
    }

    if (isActive) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect.inflate(1.0), paint);
    }
  }

  void _paintThePolitagonSeat(Canvas canvas, Size size, Rect rect) {
    final gold = const Color(0xFFC5A059);
    final coreGold = const Color(0xFFFFD700);
    final center = rect.center;

    // 1. Radial "Solar" Glow behind the chair
    if (showGlow) {
      final sunPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            coreGold.withOpacity(0.8 * glowValue),
            gold.withOpacity(0.4 * glowValue),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.8));
      
      canvas.drawCircle(center, size.width * 0.75 * (0.8 + 0.2 * glowValue), sunPaint);

      // 2. Light Rays (Solar Corona effect)
      final rayPaint = Paint()
        ..color = coreGold.withOpacity(0.3 * glowValue)
        ..strokeWidth = 2.0;
      
      for (int i = 0; i < 8; i++) {
        final angle = (i * pi / 4) + (glowValue * 0.2);
        final rayStart = Offset(center.dx + cos(angle) * (size.width * 0.2), center.dy + sin(angle) * (size.height * 0.2));
        final rayEnd = Offset(center.dx + cos(angle) * (size.width * 0.45), center.dy + sin(angle) * (size.height * 0.45));
        canvas.drawLine(rayStart, rayEnd, rayPaint);
      }
    }

    // 3. Main Outer Frame (Dark obsidian border with gold trim)
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = showGlow ? 3.0 : 1.5
      ..color = showGlow ? gold : gold.withOpacity(0.3);
    canvas.drawRect(rect, framePaint);

    // 4. Inner "Throne Room" detailing
    final detailPaint = Paint()
      ..color = gold.withOpacity(showGlow ? 0.4 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Four corner accents pointing inward
    const inset = 4.0;
    final l = size.width * 0.2;
    canvas.drawPath(Path()..moveTo(inset, inset + l)..lineTo(inset, inset)..lineTo(inset + l, inset), detailPaint);
    canvas.drawPath(Path()..moveTo(size.width - inset, inset + l)..lineTo(size.width - inset, inset)..lineTo(size.width - inset - l, inset), detailPaint);
    canvas.drawPath(Path()..moveTo(inset, size.height - inset - l)..lineTo(inset, size.height - inset)..lineTo(inset + l, size.height - inset), detailPaint);
    canvas.drawPath(Path()..moveTo(size.width - inset, size.height - inset - l)..lineTo(size.width - inset, size.height - inset)..lineTo(size.width - inset - l, size.height - inset), detailPaint);
  }

  void _drawSegment(Canvas canvas, Size size, double startDist, double endDist, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final path = Path();
    final perimeter = 2 * size.width + 2 * size.height;
    
    for (double d = startDist; d < endDist; d += 1.0) {
      final point = _getPointOnRect(size, d);
      if (d == startDist) path.moveTo(point.dx, point.dy);
      else path.lineTo(point.dx, point.dy);
    }
    
    final lastPoint = _getPointOnRect(size, endDist % perimeter);
    path.lineTo(lastPoint.dx, lastPoint.dy);

    canvas.drawPath(path, paint);
  }

  Offset _getPointOnRect(Size size, double distance) {
    final double w = size.width;
    final double h = size.height;
    double d = distance % (2 * w + 2 * h);

    if (d <= w) return Offset(d, 0);
    d -= w;
    if (d <= h) return Offset(w, d);
    d -= h;
    if (d <= w) return Offset(w - d, h);
    d -= w;
    return Offset(0, h - d);
  }

  @override
  bool shouldRepaint(covariant DistributionStrokePainter oldDelegate) => true;
}

class StrokeSegment {
  final double ratio;
  final Color color;
  StrokeSegment(this.ratio, this.color);
}
