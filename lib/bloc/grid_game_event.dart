import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

import '../builders/game_state_builder.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../utilities/adjacent_positions.dart';
import '../utilities/commons.dart';

class GridGameEvent {}

class UserMoveEvent extends GridGameEvent {
  final String playerId;
  final Position pos;
  UserMoveEvent(this.playerId, this.pos);
}

class AiMoveEvent extends GridGameEvent {
  final String playerId;
  AiMoveEvent(this.playerId);
}

class RestartGameEvent extends GridGameEvent {}

class WithdrawEvent extends GridGameEvent {
  final String playerId;
  WithdrawEvent(this.playerId);
}

class ChangeSpectatorTargetEvent extends GridGameEvent {
  final bool next;
  ChangeSpectatorTargetEvent({this.next = true});
}

class GridGameBloc extends Bloc<GridGameEvent, GameState> {
  final Logger logger = Logger();
  final AudioPlayer audioPlayer = AudioPlayer();
  final List<String> initialHumanNames;
  final bool initialAi1;
  final bool initialAi2;
  final bool initialAi3;
  final bool initialAi4;
  final int initialGridSize;

  GridGameBloc({
    List<String> humanNames = const ['The Candidate'], 
    bool ai1 = true, 
    bool ai2 = true, 
    bool ai3 = false, 
    bool ai4 = false, 
    int gridSize = 5
  })  : initialHumanNames = humanNames,
        initialAi1 = ai1,
        initialAi2 = ai2,
        initialAi3 = ai3,
        initialAi4 = ai4,
        initialGridSize = gridSize,
        super(GameState.initial(humanNames: humanNames, ai1: ai1, ai2: ai2, ai3: ai3, ai4: ai4, gridSize: gridSize)) {
    on<UserMoveEvent>(_onUserMove);
    on<AiMoveEvent>(_onAiMove);
    on<RestartGameEvent>(_onRestartGame);
    on<WithdrawEvent>(_onWithdraw);
    on<ChangeSpectatorTargetEvent>(_onChangeSpectator);
  }

  void _onRestartGame(RestartGameEvent event, Emitter<GameState> emit) {
    emit(GameState.initial(
      humanNames: initialHumanNames,
      ai1: initialAi1,
      ai2: initialAi2,
      ai3: initialAi3,
      ai4: initialAi4,
      gridSize: initialGridSize,
    )); 
  }

  void _onWithdraw(WithdrawEvent event, Emitter<GameState> emit) {
    debugPrint('WithdrawEvent received for player ${event.playerId}');
    if (state.winner != null) {
      debugPrint('Withdraw rejected: game already has winner');
      return;
    }
    if (!state.players.any((p) => p.id == event.playerId)) {
      debugPrint('Withdraw rejected: player ${event.playerId} not found');
      return;
    }
    
    final withdrawingPlayer = state.players.firstWhere((p) => p.id == event.playerId);
    debugPrint('Player ${withdrawingPlayer.name} withdrawing. Current players: ${state.players.length}');
    
    final remainingPlayers = state.players.where((p) => p.id != event.playerId).toList();
    
    if (remainingPlayers.isEmpty) {
      debugPrint('Withdraw rejected: cannot withdraw last player');
      return;
    }
    
    // Calculate if center should be re-locked
    final remainingTotalScore = remainingPlayers.fold(0, (sum, p) => sum + p.score);
    final shouldLockCenter = remainingTotalScore < state.winThreshold;
    debugPrint('Remaining total score: $remainingTotalScore, threshold: ${state.winThreshold}, lockCenter: $shouldLockCenter');
    
    // Determine next turn
    String nextTurn = state.turn;
    if (state.turn == event.playerId) {
      final currentIndex = state.players.indexWhere((p) => p.id == event.playerId);
      nextTurn = remainingPlayers[currentIndex % remainingPlayers.length].id;
    }
    
    // Check for single player victory
    if (remainingPlayers.length == 1) {
      final winner = remainingPlayers.first;
      debugPrint('Single player remaining: ${winner.name} - AUTO WIN');
      emit(state.copyWith(
        players: remainingPlayers,
        winner: winner.name,
        turn: winner.id,
        couldReachCenter: shouldLockCenter ? false : state.couldReachCenter,
        isSpectating: winner.type != PlayerType.human,
        spectatedPlayerId: winner.id,
      ));
      if (winner.type == PlayerType.human) {
        audioPlayer.play(AssetSource('sounds/victory.mp3'));
      }
      return;
    }
    
    // Check if all remaining are AI - enable step-through mode
    final allAi = remainingPlayers.every((p) => p.type != PlayerType.human);
    
    debugPrint('Emitting new state with ${remainingPlayers.length} players, next turn: $nextTurn, allAi: $allAi');
    emit(state.copyWith(
      players: remainingPlayers,
      turn: nextTurn,
      couldReachCenter: shouldLockCenter ? false : state.couldReachCenter,
      isSpectating: allAi,  // Auto-enable spectator mode if all AI
      spectatedPlayerId: nextTurn,
    ));
    
    // Don't auto-trigger AI moves if all remaining are AI (step-through mode)
    if (allAi) {
      debugPrint('All remaining players are AI - entering step-through mode');
      return;
    }
    
    _checkWin(nextTurn, emit);
    if (state.winner == null && state.players.any((p) => p.id == nextTurn && p.type != PlayerType.human)) {
       add(AiMoveEvent(nextTurn));
    }
  }

  void _onChangeSpectator(ChangeSpectatorTargetEvent event, Emitter<GameState> emit) {
    if (!state.isSpectating || state.players.isEmpty) return;
    int currentIdx = state.players.indexWhere((p) => p.id == (state.spectatedPlayerId ?? state.turn));
    int nextIdx = event.next ? (currentIdx + 1) % state.players.length : (currentIdx - 1 + state.players.length) % state.players.length;
    emit(state.copyWith(spectatedPlayerId: state.players[nextIdx].id));
  }

  bool _isCenter(Position pos) {
    final centerIdx = state.gridSize ~/ 2;
    return pos.x == centerIdx && pos.y == centerIdx;
  }

  bool _isMoveBlockedByCenter(Position targetPos, GamePlayerState player) {
    if (!_isCenter(targetPos)) return false;
    if (state.couldReachCenter != true) return true;
    if (player.type != PlayerType.human) {
      final otherPlayers = state.players.where((p) => p.id != player.id);
      final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((p) => p.score).reduce(max);
      if (player.score < maxOtherScore) return true;
    }
    return false;
  }

  void _onUserMove(UserMoveEvent event, Emitter<GameState> emit) {
    final player = state.players.firstWhere((p) => p.id == event.playerId);
    if (state.turn != player.id || state.winner != null) return;
    if (_isCenter(event.pos) && state.couldReachCenter != true) return;
    final validMoves = AdjacentPositions.get(player.pos, state.gridSize, state.gridSize);
    if (!validMoves.any((m) => m.equals(event.pos))) return;
    final newState = GameStateBuilder.onCellTapGameState(state, event, event.pos);
    emit(newState);
    _checkWin(player.id, emit);
    if (state.winner == null) _triggerNextTurn();
  }

  void _onAiMove(AiMoveEvent event, Emitter<GameState> emit) {
    if (!state.players.any((p) => p.id == event.playerId)) return;
    final player = state.players.firstWhere((p) => p.id == event.playerId);
    if (state.turn != player.id || state.winner != null) return;
    var validMoves = AdjacentPositions.get(player.pos, state.gridSize, state.gridSize);
    validMoves = validMoves.where((m) => !_isMoveBlockedByCenter(m, player)).toList();
    if (validMoves.isEmpty) { _triggerNextTurn(); return; }
    Position nextPos;
    if (player.type == PlayerType.ai1) {
      nextPos = validMoves[Random().nextInt(validMoves.length)];
    } else if (player.type == PlayerType.ai2) {
      final otherPlayers = state.players.where((p) => p.id != player.id);
      final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((p) => p.score).reduce(max);
      final isWinningOrTied = player.score >= maxOtherScore;
      if (isWinningOrTied && state.couldReachCenter == true) {
        final centerIdx = state.gridSize ~/ 2;
        final center = Position(centerIdx, centerIdx);
        nextPos = validMoves.reduce((a, b) {
          final distA = (a.x - center.x).abs() + (a.y - center.y).abs();
          final distB = (b.x - center.x).abs() + (b.y - center.y).abs();
          return distA < distB ? a : b;
        });
      } else { nextPos = validMoves.reduce((a, b) => state.grid[a.x][a.y] > state.grid[b.x][b.y] ? a : b); }
    } else if (player.type == PlayerType.ai3) {
      final centerIdx = state.gridSize ~/ 2;
      final center = Position(centerIdx, centerIdx);
      final otherPlayers = state.players.where((p) => p.id != player.id);
      final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((p) => p.score).reduce(max);
      bool winsIfGoesCenter = state.couldReachCenter == true && player.score >= maxOtherScore;
      if (validMoves.any((m) => m.equals(center)) && winsIfGoesCenter) { nextPos = center; }
      else {
        final bestGain = validMoves.map((m) => _calculateExpectedGain(player, m)).reduce(max);
        if (bestGain == 0 && state.couldReachCenter == true) {
          nextPos = validMoves.reduce((a, b) {
            final distA = (a.x - center.x).abs() + (a.y - center.y).abs();
            final distB = (b.x - center.x).abs() + (b.y - center.y).abs();
            return distA < distB ? a : b;
          });
        } else {
          nextPos = validMoves.reduce((a, b) {
            double scoreA = _calculateExpectedGain(player, a);
            double scoreB = _calculateExpectedGain(player, b);
            return scoreA > scoreB ? a : b;
          });
        }
      }
    } else { nextPos = _handleAi4StrategicMove(player, validMoves); }
    final newState = GameStateBuilder.onCellTapGameState(state, event, nextPos);
    emit(newState);
    _checkWin(player.id, emit);
    if (state.winner == null) _triggerNextTurn();
  }

  Position _handleAi4StrategicMove(GamePlayerState player, List<Position> validMoves) {
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    final otherPlayers = state.players.where((p) => p.id != player.id);
    final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((p) => p.score).reduce(max);
    bool winsIfGoesCenter = state.couldReachCenter == true && player.score >= maxOtherScore;
    if (validMoves.any((m) => m.equals(center)) && winsIfGoesCenter) return center;
    Position target;
    if (player.targetPos == null || player.pos.equals(player.targetPos!) || state.grid[player.targetPos!.x][player.targetPos!.y] == 0) {
      target = _findBestStrategicTarget(player);
    } else { target = player.targetPos!; }
    return validMoves.reduce((a, b) {
      final distA = (a.x - target.x).abs() + (a.y - target.y).abs();
      final distB = (b.x - target.x).abs() + (b.y - target.y).abs();
      return distA < distB ? a : b;
    });
  }

  Position _findBestStrategicTarget(GamePlayerState player) {
    final centerIdx = state.gridSize ~/ 2;
    Position bestPos = Position(0, 0); double bestRegionScore = -1.0;
    for (int i = 0; i < state.gridSize; i++) {
      for (int j = 0; j < state.gridSize; j++) {
        double regionScore = 0;
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            int nx = i + dx; int ny = j + dy;
            if (nx >= 0 && nx < state.gridSize && ny >= 0 && ny < state.gridSize) {
              regionScore += _calculateExpectedGain(player, Position(nx, ny));
            }
          }
        }
        final dist = (i - centerIdx).abs() + (j - centerIdx).abs();
        if (player.popularity < 0.3) regionScore *= (dist + 1);
        if (player.influence < 0.3) regionScore *= (state.gridSize - dist);
        if (regionScore > bestRegionScore) { bestRegionScore = regionScore; bestPos = Position(i, j); }
      }
    }
    return bestPos;
  }

  double _calculateExpectedGain(GamePlayerState player, Position pos) {
    final cellValue = state.grid[pos.x][pos.y];
    final centerIdx = state.gridSize ~/ 2;
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;
    final targetQuality = (maxDist + 1 - distance) / (maxDist + 1).toDouble();
    final extremeQuality = targetQuality * targetQuality;
    final eliteCaptureNeed = extremeQuality;
    final grassrootsCaptureNeed = 1.0 - extremeQuality;
    final captureRate = (player.popularity * eliteCaptureNeed + 
                         player.influence * grassrootsCaptureNeed).clamp(0.05, 1.0);
    return cellValue * captureRate;
  }

  void _triggerNextTurn() {
    // In spectator mode (all AI), don't auto-trigger - let user control with "NEXT TURN" button
    if (state.isSpectating) return;
    
    final nextPlayerId = state.turn;
    final nextPlayer = state.players.firstWhere((p) => p.id == nextPlayerId);
    if (nextPlayer.type != PlayerType.human) {
      add(AiMoveEvent(nextPlayer.id));
    }
  }

  bool _isGridEmpty() {
    for (var row in state.grid) { for (var val in row) { if (val > 0) return false; } }
    return true;
  }

  void _checkWin(String playerId, Emitter<GameState> emit) {
    if (!state.players.any((p) => p.id == playerId)) return;
    final player = state.players.firstWhere((p) => p.id == playerId);
    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    final allScores = state.players.map((p) => p.score).toList();
    final totalScore = sumWithFold(allScores);
    if (state.couldReachCenter != true && (totalScore >= state.winThreshold || _isGridEmpty())) {
      emit(state.copyWith(couldReachCenter: true));
    }
    if (player.pos.equals(center)) {
      final otherPlayers = state.players.where((p) => p.id != player.id);
      final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((p) => p.score).reduce(max);
      if (state.couldReachCenter == true && player.score >= maxOtherScore) {
        emit(state.copyWith(winner: player.name));
        if (player.type == PlayerType.human) { audioPlayer.play(AssetSource('sounds/victory.mp3')); }
      }
    }
  }
}
