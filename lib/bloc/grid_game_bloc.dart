import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

import '../builders/game_state_builder.dart';
import '../builders/game_initializer.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../utilities/adjacent_positions.dart';
import '../utilities/commons.dart';
import '../utilities/ai_strategy.dart';
import '../utilities/ai_strategies.dart';
import '../utilities/score_calculator.dart';
import '../utilities/grid_manager.dart';
import '../utilities/win_condition_checker.dart';
import '../utilities/move_validator.dart';
import 'grid_game_event.dart';

class GridGameBloc extends Bloc<GridGameEvent, GameState> {
  final Logger logger = Logger();
  final AudioPlayer audioPlayer = AudioPlayer();
  final List<String> initialHumanNames;
  final bool initialAi1;
  final bool initialAi2;
  final bool initialAi3;
  final bool initialAi4;
  final bool initialAi5;
  final int initialGridSize;
  final double decidedThresholdPercentage;

  final Map<PlayerType, AiStrategy> _aiStrategies = {
    PlayerType.ai1: FirebrandStrategy(),
    PlayerType.ai2: PragmatistStrategy(),
    PlayerType.ai3: TechnocratStrategy(),
    PlayerType.ai4: VisionaryStrategy(),
    PlayerType.ai5: SocialistStrategy(),
  };

  GridGameBloc({
    List<String> humanNames = const ['The Candidate'], 
    bool ai1 = true, 
    bool ai2 = true, 
    bool ai3 = false, 
    bool ai4 = false, 
    bool ai5 = false,
    int gridSize = 5,
    this.decidedThresholdPercentage = 0.5,
  })  : initialHumanNames = humanNames,
        initialAi1 = ai1,
        initialAi2 = ai2,
        initialAi3 = ai3,
        initialAi4 = ai4,
        initialAi5 = ai5,
        initialGridSize = gridSize,
        super(GameInitializer.createInitialState(
          humanNames: humanNames, 
          ai1: ai1, 
          ai2: ai2, 
          ai3: ai3, 
          ai4: ai4, 
          ai5: ai5, 
          gridSize: gridSize,
          decidedThresholdPercentage: decidedThresholdPercentage,
        )) {
    on<UserMoveEvent>(_onUserMove);
    on<AiMoveEvent>(_onAiMove);
    on<RestartGameEvent>(_onRestartGame);
    on<WithdrawEvent>(_onWithdraw);
    on<ChangeSpectatorTargetEvent>(_onChangeSpectator);
    on<ToggleStepByStepModeEvent>(_onToggleStepByStepMode);
  }

  void _onToggleStepByStepMode(ToggleStepByStepModeEvent event, Emitter<GameState> emit) {
    final newState = state.copyWith(stepByStepMode: !state.stepByStepMode);
    emit(newState);
    if (newState.stepByStepMode) {
      _triggerNextTurn(newState);
    }
  }

  void _onRestartGame(RestartGameEvent event, Emitter<GameState> emit) {
    emit(GameInitializer.createInitialState(
      humanNames: initialHumanNames,
      ai1: initialAi1,
      ai2: initialAi2,
      ai3: initialAi3,
      ai4: initialAi4,
      ai5: initialAi5,
      gridSize: initialGridSize,
      decidedThresholdPercentage: decidedThresholdPercentage,
    ).copyWith(stepByStepMode: state.stepByStepMode)); 
  }

  void _onWithdraw(WithdrawEvent event, Emitter<GameState> emit) {
    if (state.winner != null) return;
    if (!state.players.any((p) => p.id == event.playerId)) return;
    
    final remainingPlayers = state.players.where((p) => p.id != event.playerId).toList();
    if (remainingPlayers.isEmpty) return;
    
    final newGridOwnership = GridManager.convertPlayerPointsToUndecided(state.gridOwnership, event.playerId);
    
    String nextTurn = state.turn;
    if (state.turn == event.playerId) {
      final currentIndex = state.players.indexWhere((p) => p.id == event.playerId);
      nextTurn = remainingPlayers[currentIndex % remainingPlayers.length].id;
    }
    
    if (remainingPlayers.length == 1) {
      final winner = remainingPlayers.first;
      emit(state.copyWith(
        players: remainingPlayers,
        winner: winner.name,
        turn: winner.id,
        isSpectating: winner.type != PlayerType.human,
        spectatedPlayerId: winner.id,
        gridOwnership: newGridOwnership,
      ));
      if (winner.type == PlayerType.human) _playVictorySound();
      return;
    }
    
    final allAi = remainingPlayers.every((p) => p.type != PlayerType.human);
    final newState = state.copyWith(
      players: remainingPlayers,
      turn: nextTurn,
      isSpectating: allAi,
      spectatedPlayerId: nextTurn,
      gridOwnership: newGridOwnership,
    );
    emit(newState);
    
    if (allAi && !state.stepByStepMode) return;
    
    _processWinAndNextTurn(nextTurn, emit, newState);
  }

  void _onChangeSpectator(ChangeSpectatorTargetEvent event, Emitter<GameState> emit) {
    if (!state.isSpectating || state.players.isEmpty) return;
    int currentIdx = state.players.indexWhere((p) => p.id == (state.spectatedPlayerId ?? state.turn));
    int nextIdx = event.next ? (currentIdx + 1) % state.players.length : (currentIdx - 1 + state.players.length) % state.players.length;
    emit(state.copyWith(spectatedPlayerId: state.players[nextIdx].id));
  }

  void _onUserMove(UserMoveEvent event, Emitter<GameState> emit) {
    final player = state.players.firstWhere((p) => p.id == event.playerId);
    if (state.turn != player.id || state.winner != null) return;
    
    if (MoveValidator.isMoveBlockedByCenter(event.pos, player, state)) return;

    final validMoves = AdjacentPositions.get(player.pos, state.gridSize, state.gridSize);
    if (!validMoves.any((m) => m.equals(event.pos))) return;
    
    final newState = GameStateBuilder.onCellTapGameState(state, event, event.pos);
    emit(newState);
    _processWinAndNextTurn(player.id, emit, newState);
  }

  void _onAiMove(AiMoveEvent event, Emitter<GameState> emit) {
    if (!state.players.any((p) => p.id == event.playerId)) return;
    final player = state.players.firstWhere((p) => p.id == event.playerId);
    if (state.turn != player.id || state.winner != null) return;
    
    var validMoves = AdjacentPositions.get(player.pos, state.gridSize, state.gridSize);
    validMoves = validMoves.where((m) => !MoveValidator.isMoveBlockedByCenter(m, player, state)).toList();
    if (validMoves.isEmpty) { _triggerNextTurn(); return; }

    final centerIdx = state.gridSize ~/ 2;
    final center = Position(centerIdx, centerIdx);
    
    final bool isWinningOrTied = _isPlayerWinningOrTied(player, state);
    final bool centerUnlocked = state.couldReachCenter == true;

    Position nextPos;
    if (centerUnlocked && isWinningOrTied) {
      nextPos = AiStrategyUtils.rushCenter(validMoves, center);
    } else {
      final strategy = _aiStrategies[player.type];
      nextPos = strategy?.getNextMove(player, state, validMoves) ?? validMoves[Random().nextInt(validMoves.length)];
    }

    final newState = GameStateBuilder.onCellTapGameState(state, event, nextPos);
    emit(newState);
    _processWinAndNextTurn(player.id, emit, newState);
  }

  bool _isPlayerWinningOrTied(GamePlayerState player, GameState state) {
    final playerScore = ScoreCalculator.calculateScore(state, player.id);
    final otherPlayers = state.players.where((p) => p.id != player.id);
    final maxOtherScore = otherPlayers.isEmpty ? 0 : otherPlayers.map((p) => ScoreCalculator.calculateScore(state, p.id)).reduce(max);
    return playerScore >= maxOtherScore;
  }

  void _processWinAndNextTurn(String lastPlayerId, Emitter<GameState> emit, GameState checkState) {
    final winCheckedState = WinConditionChecker.checkWin(checkState, lastPlayerId);
    if (winCheckedState != checkState) {
      emit(winCheckedState);
      if (winCheckedState.winner != null) {
        final winner = winCheckedState.players.firstWhere((p) => p.name == winCheckedState.winner);
        if (winner.type == PlayerType.human) _playVictorySound();
        return;
      }
    }
    _triggerNextTurn(winCheckedState);
  }

  void _triggerNextTurn([GameState? currentState]) {
    final activeState = currentState ?? state;
    if (activeState.winner != null) return;
    if (activeState.isSpectating && !activeState.stepByStepMode) return;
    
    final nextPlayerId = activeState.turn;
    final nextPlayer = activeState.players.firstWhere((p) => p.id == nextPlayerId);
    if (nextPlayer.type != PlayerType.human) {
      if (activeState.stepByStepMode) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!isClosed && state.turn == nextPlayerId && state.winner == null) {
            add(AiMoveEvent(nextPlayerId));
          }
        });
      } else {
        add(AiMoveEvent(nextPlayerId));
      }
    }
  }

  void _playVictorySound() {
    audioPlayer.play(AssetSource('sounds/victory.mp3'));
  }
}
