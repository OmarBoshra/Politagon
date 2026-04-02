import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

import '../bloc/grid_game_event.dart';
import '../bloc/grid_game_bloc.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import 'scoreboard.dart';
import 'spectator_controls.dart';
import 'grid_cell.dart';
import 'player_icon.dart';
import 'game_dialogs.dart';

class GridGame extends StatefulWidget {
  const GridGame({super.key});

  @override
  State<GridGame> createState() => _GridGameState();

  static Color getGlobalPlayerColor(GamePlayerState player) {
    switch (player.type) {
      case PlayerType.human:
        return [
          const Color(0xFF4DB6AC),
          const Color(0xFF81C784),
          const Color(0xFF9575CD),
          const Color(0xFF4FC3F7),
          const Color(0xFF7986CB)
        ][player.colorIndex % 5];
      case PlayerType.ai1:
        return const Color(0xFFE57373);
      case PlayerType.ai2:
        return const Color(0xFFFFB74D);
      case PlayerType.ai3:
        return const Color(0xFF90A4AE);
      case PlayerType.ai4:
        return const Color(0xFFCE93D8);
      case PlayerType.ai5:
        return const Color(0xFF81C784);
    }
  }
}

class _GridGameState extends State<GridGame> with TickerProviderStateMixin {
  late final FocusNode _focusNode = FocusNode();
  late final AnimationController _glowAnimationController;
  late final AnimationController _matrixAnimationController;
  late final ap.AudioPlayer _audioPlayer;
  bool _isMusicPlaying = false;
  
  final TransformationController _transformationController = TransformationController();
  Matrix4Tween? _matrixTween;

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _matrixAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _audioPlayer = ap.AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setReleaseMode(ap.ReleaseMode.loop);
    await _audioPlayer.setSource(ap.AssetSource('sounds/background.m4a'));
  }

  void _toggleMusic() async {
    if (_isMusicPlaying) await _audioPlayer.pause();
    else await _audioPlayer.resume();
    setState(() => _isMusicPlaying = !_isMusicPlaying);
  }

  void _restartGame() {
    context.read<GridGameBloc>().add(RestartGameEvent());
    _smoothTransform(Matrix4.identity());
  }

  void _smoothTransform(Matrix4 target) {
    _matrixTween = Matrix4Tween(begin: _transformationController.value, end: target);
    _matrixAnimationController.reset();
    _matrixAnimationController.forward();
  }

  void _animatedZoom(double factor) {
    final Matrix4 target = _transformationController.value.clone()..scale(factor);
    _smoothTransform(target);
  }

  void _handleKeyEvent(KeyEvent event, GameState state, GamePlayerState currentPlayer) {
    if (event is! KeyDownEvent || state.isSpectating || state.winner != null || currentPlayer.type != PlayerType.human) return;

    Position? targetPos;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      targetPos = Position(currentPlayer.pos.x - 1, currentPlayer.pos.y);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      targetPos = Position(currentPlayer.pos.x + 1, currentPlayer.pos.y);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      targetPos = Position(currentPlayer.pos.x, currentPlayer.pos.y - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      targetPos = Position(currentPlayer.pos.x, currentPlayer.pos.y + 1);
    }

    if (targetPos != null && targetPos.x >= 0 && targetPos.x < state.gridSize && targetPos.y >= 0 && targetPos.y < state.gridSize) {
      final centerIdx = state.gridSize ~/ 2;
      final isCenter = targetPos.x == centerIdx && targetPos.y == centerIdx;
      final isAdjacent = (targetPos.x - currentPlayer.pos.x).abs() + (targetPos.y - currentPlayer.pos.y).abs() == 1;
      
      if (isAdjacent && (!isCenter || state.couldReachCenter == true)) {
        context.read<GridGameBloc>().add(UserMoveEvent(currentPlayer.id, targetPos));
      }
    }
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _matrixAnimationController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridGameBloc, GameState>(
      builder: (context, state) {
        final actualTurnPlayer = state.players.any((p) => p.id == state.turn)
            ? state.players.firstWhere((p) => p.id == state.turn)
            : state.players.isNotEmpty ? state.players.first : null;
        
        final viewedPlayer = state.players.any((p) => p.id == (state.spectatedPlayerId ?? state.turn))
            ? state.players.firstWhere((p) => p.id == (state.spectatedPlayerId ?? state.turn))
            : actualTurnPlayer;

        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) => _handleKeyEvent(event, state, actualTurnPlayer!),
          child: Scaffold(
            backgroundColor: const Color(0xFF0D1117),
            appBar: AppBar(
              title: Text(state.isSpectating ? 'SPECTATOR MODE: ${viewedPlayer?.name ?? ""}' : 'POLITAGON OPERATIONAL GRID'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(state.stepByStepMode ? Icons.slow_motion_video : Icons.speed), 
                  onPressed: () => context.read<GridGameBloc>().add(ToggleStepByStepModeEvent()),
                  tooltip: 'Toggle Step-by-Step Mode',
                  color: state.stepByStepMode ? const Color(0xFFC5A059) : null,
                ),
                IconButton(icon: const Icon(Icons.pie_chart_outline), onPressed: () => GameDialogs.showPointStatus(context, state), tooltip: 'Point Status'),
                IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => _animatedZoom(1.2)),
                IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => _animatedZoom(0.8)),
                IconButton(icon: const Icon(Icons.zoom_out_map), onPressed: () => _smoothTransform(Matrix4.identity())),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _restartGame),
                IconButton(icon: Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off), onPressed: _toggleMusic),
              ],
            ),
            body: BlocListener<GridGameBloc, GameState>(
              listener: (context, state) {
                if (!state.isSpectating && state.players.any((p) => p.id == state.turn && p.type == PlayerType.human)) {
                  _focusNode.requestFocus();
                }
              },
              child: Column(
                children: [
                  Scoreboard(state: state, glowAnimation: _glowAnimationController),
                  if (state.winner != null) _WinnerBanner(winner: state.winner!),
                  if (state.isSpectating) SpectatorControls(state: state),
                  Expanded(
                    child: Center(
                      child: _GameGrid(
                        state: state,
                        transformationController: _transformationController,
                        actualTurnPlayer: actualTurnPlayer!,
                        glowAnimation: _glowAnimationController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  final String winner;
  const _WinnerBanner({required this.winner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFC5A059),
      child: Center(
        child: Text(
          'VICTORY: $winner',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}

class _GameGrid extends StatelessWidget {
  final GameState state;
  final TransformationController transformationController;
  final GamePlayerState actualTurnPlayer;
  final Animation<double> glowAnimation;

  const _GameGrid({
    required this.state,
    required this.transformationController,
    required this.actualTurnPlayer,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableSize = constraints.biggest.shortestSide * 0.95;
        final double cellWidth = availableSize / state.gridSize;
        final double iconSize = (cellWidth * 0.75).clamp(8.0, 48.0);

        return SizedBox(
          width: availableSize,
          height: availableSize,
          child: InteractiveViewer(
            transformationController: transformationController,
            boundaryMargin: const EdgeInsets.all(200),
            child: Stack(
              children: [
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: state.gridSize),
                  itemCount: state.gridSize * state.gridSize,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final pos = Position(index ~/ state.gridSize, index % state.gridSize);
                    return GridCell(
                      state: state,
                      pos: pos,
                      currentPlayer: actualTurnPlayer,
                      cellWidth: cellWidth,
                      glowAnimation: glowAnimation,
                    );
                  },
                ),
                ...state.players.map((p) {
                  final offset = _calculatePlayerOffset(p, state.players, cellWidth);
                  final isCurrentTurn = p.id == state.turn;
                  return AnimatedPositioned(
                    key: ValueKey('p_${p.id}'),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    left: (p.pos.y * cellWidth) + offset.dx,
                    top: (p.pos.x * cellWidth) + offset.dy,
                    width: cellWidth,
                    height: cellWidth,
                    child: Center(
                      child: PlayerIcon(
                        player: p,
                        size: iconSize,
                        isCurrentTurn: isCurrentTurn,
                        glowAnimation: glowAnimation,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _calculatePlayerOffset(GamePlayerState player, List<GamePlayerState> allPlayers, double cellWidth) {
    final sharing = allPlayers.where((p) => p.pos.equals(player.pos)).toList();
    if (sharing.length <= 1) return Offset.zero;
    final idx = sharing.indexOf(player);
    final double angle = (2 * pi * idx) / sharing.length;
    return Offset(cos(angle) * cellWidth * 0.25, sin(angle) * cellWidth * 0.25);
  }
}
