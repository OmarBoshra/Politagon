import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

import '../builders/game_state_builder.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../utilities/adjacent_positions.dart';
import '../utilities/commons.dart';
import '../utilities/grid_generator.dart';

class GridGameEvent {}

class UserMoveEvent extends GridGameEvent {
  final Position pos;
  UserMoveEvent(this.pos);
}

class Ai1MoveEvent extends GridGameEvent {}

class Ai2MoveEvent extends GridGameEvent {}

class RestartGameEvent extends GridGameEvent {}  // Add this event class

class GridGameBloc extends Bloc<GridGameEvent, GameState> {
  final Logger logger = Logger();
  final AudioPlayer audioPlayer = AudioPlayer();


  GridGameBloc() : super(_initialState()) {
    on<UserMoveEvent>(_onUserMove);
    on<Ai1MoveEvent>(_onAi1Move);
    on<Ai2MoveEvent>(_onAi2Move);
    on<RestartGameEvent>(_onRestartGame);  // Add handler for restart event
  }

  void _onRestartGame(RestartGameEvent event, Emitter<GameState> emit) {
    emit(_initialState());  // Reset to initial state
  }


  static GameState _initialState() => GameState.initial();


  void _onUserMove(UserMoveEvent event, Emitter<GameState> emit) {
    if (state.turn != 'user' || state.winner != null) return;
    final validMoves = AdjacentPositions.get(state.userPos, 5, 5);
    if (!validMoves.any((m) => m.equals(event.pos))) return;
    final newState = GameStateBuilder.onCellTapGameState(state, event, event.pos);
    emit(newState);
    _checkWin('user', emit);
    if (state.winner == null) add(Ai1MoveEvent());
  }


  void _onAi1Move(Ai1MoveEvent event, Emitter<GameState> emit) {
    if (state.turn != 'ai1' || state.winner != null) return;
    final validMoves = AdjacentPositions.get(state.ai1Pos, 5, 5);
    // Position based on random movement.
    final nextPos = validMoves[Random().nextInt(validMoves.length)];
    final newState = GameStateBuilder.onCellTapGameState(state, event, nextPos);
    emit(newState);
    _checkWin('ai1', emit);
    if (state.winner == null) add(Ai2MoveEvent());
  }

  void _onAi2Move(Ai2MoveEvent event, Emitter<GameState> emit) {
    if (state.turn != 'ai2' || state.winner != null) return;
    final validMoves = AdjacentPositions.get(state.ai2Pos, 5, 5);
    Position nextPos;
    final scores = state.scores;
    if (scores['ai2']! > scores['user']! && scores['ai2']! > scores['ai1']!) {
      final center = Position(2, 2);
      // Position based on going to the largest number
      nextPos = validMoves.reduce((a, b) {
        final distA = (a.x - center.x).abs() + (a.y - center.y).abs();
        final distB = (b.x - center.x).abs() + (b.y - center.y).abs();
        return distA < distB ? a : b;
      });
    } else {
      nextPos = validMoves.reduce(
          (a, b) => state.grid[a.x][a.y] > state.grid[b.x][b.y] ? a : b);
    }
    final newState = GameStateBuilder.onCellTapGameState(state, event, nextPos);

    emit(newState);
    _checkWin('ai2', emit);
  }

  void _checkWin(String player, Emitter<GameState> emit) {
    final center = Position(2, 2);
    final pos = player == 'user'
        ? state.userPos
        : player == 'ai1'
            ? state.ai1Pos
            : state.ai2Pos;
    final score = state.scores[player]!;
    final otherScores = state.scores.values.where((s) => s != score).toList();
    final allScores = state.scores.values.toList();
    final totalScore = sumWithFold(allScores);
    if(state.couldReachCenter != true && totalScore >= 100){
      final newState = state.copyWith(couldReachCenter: true);
      emit(newState);
    }
    if (pos.equals(center) && sumWithFold(allScores) >= 100 && score > otherScores.reduce(max)) {
      final newState = state.copyWith(winner: player);
      emit(newState);
      if (player == 'user') {
        audioPlayer.play(AssetSource('sounds/victory.mp3'));
      }
    }
  }
}
