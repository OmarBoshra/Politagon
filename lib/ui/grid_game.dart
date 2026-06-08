import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../bloc/grid_game_event.dart';
import '../bloc/grid_game_bloc.dart';
import '../models/game_state.dart';
import '../models/game_player_state.dart';
import '../models/position.dart';
import '../utilities/score_calculator.dart';
import 'scoreboard.dart';
import 'spectator_controls.dart';
import 'grid_cell.dart';
import 'player_icon.dart';
import 'game_dialogs.dart';
import 'distribution_stroke_painter.dart';

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

class _GridGameState extends State<GridGame> with TickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _matrixAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_matrixTween != null) {
          _transformationController.value = _matrixTween!.evaluate(_matrixAnimationController);
        }
      });

    _audioPlayer = ap.AudioPlayer();
    _initAudio();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isMusicPlaying) {
        _audioPlayer.setVolume(0);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isMusicPlaying) {
        _audioPlayer.setVolume(1);
      }
    }
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ap.ReleaseMode.loop);
      await _audioPlayer.play(ap.AssetSource('sounds/background.m4a'), volume: 1);
      if (mounted) {
        setState(() => _isMusicPlaying = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isMusicPlaying = false);
      }
    }
  }

  void _toggleMusic() async {
    try {
      if (_isMusicPlaying) {
        await _audioPlayer.setVolume(0);
      } else {
        await _audioPlayer.setVolume(1);
      }
      if (mounted) {
        setState(() => _isMusicPlaying = !_isMusicPlaying);
      }
    } catch (_) {}
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

  void _showDossier() {
    GameDialogs.showDossier(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowAnimationController.dispose();
    _matrixAnimationController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BlocBuilder<GridGameBloc, GameState>(
      builder: (context, state) {
        final actualTurnPlayer = state.players.any((p) => p.id == state.turn)
            ? state.players.firstWhere((p) => p.id == state.turn)
            : state.players.isNotEmpty ? state.players.first : null;
        
        final viewedPlayer = state.players.any((p) => p.id == (state.spectatedPlayerId ?? state.turn))
            ? state.players.firstWhere((p) => p.id == (state.spectatedPlayerId ?? state.turn))
            : actualTurnPlayer;

        final List<(String, Color)> playerInfo = state.players.map((p) => (p.id, GridGame.getGlobalPlayerColor(p))).toList();

        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) => _handleKeyEvent(event, state, actualTurnPlayer!),
          child: Scaffold(
            backgroundColor: const Color(0xFF0D1117),
            appBar: AppBar(
              title: Text(
                state.isSpectating ? 'SPECTATOR' : 'OPERATIONAL GRID',
                style: const TextStyle(fontSize: 16),
              ),
              centerTitle: true,
              actions: [
                if (!isMobile) ...[
                  IconButton(
                    icon: Icon(state.stepByStepMode ? Icons.slow_motion_video : Icons.speed), 
                    onPressed: () => context.read<GridGameBloc>().add(ToggleStepByStepModeEvent()),
                    tooltip: 'Toggle Step-by-Step Mode',
                    color: state.stepByStepMode ? const Color(0xFFC5A059) : null,
                  ),
                  IconButton(icon: const Icon(Icons.pie_chart_outline), onPressed: () => GameDialogs.showPointStatus(context, state), tooltip: 'Political Capital'),
                  IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => _animatedZoom(1.2)),
                  IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => _animatedZoom(0.8)),
                  IconButton(icon: const Icon(Icons.zoom_out_map), onPressed: () => _smoothTransform(Matrix4.identity())),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _restartGame),
                  IconButton(icon: Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off), onPressed: _toggleMusic),
                  IconButton(icon: const Icon(Icons.menu_book), onPressed: _showDossier, tooltip: 'Read Dossier'),
                  IconButton(
                    icon: SvgPicture.string(
                      '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41 0.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="white"/></svg>',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(Color(0xFFC5A059), BlendMode.srcIn),
                    ),
                    onPressed: () => launchUrl(Uri.parse('https://sites.google.com/view/politagon/support')),
                    tooltip: 'Support the Project',
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFFC5A059)),
                    onSelected: (value) {
                      switch (value) {
                        case 'step': context.read<GridGameBloc>().add(ToggleStepByStepModeEvent()); break;
                        case 'status': GameDialogs.showPointStatus(context, state); break;
                        case 'reset_zoom': _smoothTransform(Matrix4.identity()); break;
                        case 'restart': _restartGame(); break;
                        case 'music': _toggleMusic(); break;
                        case 'dossier': _showDossier(); break;
                        case 'donate': launchUrl(Uri.parse('https://sites.google.com/view/politagon/support')); break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'step', child: Text(state.stepByStepMode ? 'Disable Step-by-Step' : 'Enable Step-by-Step')),
                      const PopupMenuItem(value: 'status', child: Text('Political Capital')),
                      const PopupMenuItem(value: 'reset_zoom', child: Text('Reset View')),
                      const PopupMenuItem(value: 'restart', child: Text('Restart Campaign')),
                      PopupMenuItem(value: 'music', child: Text(_isMusicPlaying ? 'Mute Audio' : 'Unmute Audio')),
                      const PopupMenuItem(value: 'dossier', child: Text('Read Dossier')),
                      const PopupMenuItem(value: 'donate', child: Text('Support Project')),
                    ],
                  ),
                ],
              ],
            ),
            body: BlocListener<GridGameBloc, GameState>(
              listenWhen: (previous, current) => previous.couldReachCenter != current.couldReachCenter,
              listener: (context, state) {
                if (!state.isSpectating && state.players.any((p) => p.id == state.turn && p.type == PlayerType.human)) {
                  _focusNode.requestFocus();
                }
                
                if (state.couldReachCenter == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          border: Border.all(color: const Color(0xFFC5A059), width: 2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_open, color: Color(0xFFC5A059), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'THE POLITAGON SEAT IS UNLOCKED',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      duration: const Duration(seconds: 2.5),
                    ),
                  );
                }
              },
              child: SafeArea(
                child: Builder(
                  builder: (context) {
                    final size = MediaQuery.of(context).size;
                    final isLandscape = size.width > size.height;
                    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
                    final useLandscapeLayout = isLandscape && isAndroid;

                    // Build the main content (winner banner, spectator controls, grid)
                    final mainContent = Column(
                      children: [
                        if (state.winner != null) _WinnerBanner(winner: state.winner!),
                        if (state.isSpectating) RepaintBoundary(child: SpectatorControls(state: state)),
                        Expanded(
                          child: Center(
                            child: _GameGrid(
                              state: state,
                              playerInfo: playerInfo,
                              transformationController: _transformationController,
                              actualTurnPlayer: actualTurnPlayer!,
                              glowAnimation: _glowAnimationController,
                            ),
                          ),
                        ),
                      ],
                    );

                    if (useLandscapeLayout) {
                      // Landscape: cards and progress bar side by side
                      final sidebar = Row(
                        children: [
                          Expanded(
                            child: RepaintBoundary(
                              child: Scoreboard(
                                state: state,
                                glowAnimation: _glowAnimationController,
                                isLandscape: true,
                                currentPlayerId: state.turn,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: RepaintBoundary(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _MaturityProgressBar(state: state),
                              ),
                            ),
                          ),
                        ],
                      );

                      // Landscape layout: sidebar on left, grid on right
                      return Row(
                        children: [
                          // Left sidebar with cards and progress bar side by side
                          SizedBox(
                            width: 240,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: sidebar,
                            ),
                          ),
                          // Right main content area with grid
                          Expanded(
                            child: mainContent,
                          ),
                        ],
                      );
                    } else {
                      // Portrait layout: vertical stack
                      return Column(
                        children: [
                          RepaintBoundary(
                            child: Scoreboard(
                              state: state,
                              glowAnimation: _glowAnimationController,
                              isLandscape: false,
                              currentPlayerId: state.turn,
                            ),
                          ),
                          RepaintBoundary(child: _MaturityProgressBar(state: state)),
                          ...mainContent.children,
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MaturityProgressBar extends StatelessWidget {
  final GameState state;
  const _MaturityProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final int threshold = (state.maxNationalPool * state.decidedThresholdPercentage).ceil();
    final int totalDecided = ScoreCalculator.calculateTotalPlayerScore(state);
    final double progress = (totalDecided / threshold).clamp(0.0, 1.0);
    final bool isUnlocked = state.couldReachCenter == true;

    final playerSegments = state.players
        .map((p) => (
              playerId: p.id,
              color: GridGame.getGlobalPlayerColor(p),
              points: ScoreCalculator.calculateScore(state, p.id),
            ))
        .where((s) => s.points > 0)
        .toList();

    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final useLandscapeLayout = isLandscape && isAndroid;

    if (useLandscapeLayout) {
      // Vertical bar for landscape mode
      return InkWell(
        onTap: () => GameDialogs.showMaturityStats(context, state),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border: Border(
              top: BorderSide(
                color: isUnlocked ? Colors.greenAccent.withOpacity(0.4) : const Color(0xFFC5A059).withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Expanded(
                child: SizedBox(
                  width: 8.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const barWidth = 4.0;

                        final segmentWidgets = <Widget>[];

                        final denom = totalDecided <= 0 ? 1 : totalDecided;

                        for (final s in playerSegments) {
                          final percentage = (s.points / denom).clamp(0.0, 1.0);
                          final flexValue = (percentage * progress * 100).toInt().clamp(1, 100);

                          if (flexValue < 1) continue;

                          segmentWidgets.add(
                            Flexible(
                              flex: flexValue,
                              child: SizedBox(
                                width: barWidth,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    boxShadow: [
                                      BoxShadow(
                                        color: s.color.withOpacity(0.3),
                                        blurRadius: 2,
                                        offset: const Offset(1, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // Unfilled section (undecided voters)
                        final unfilledFlex = ((1 - progress) * 100).toInt().clamp(1, 100);
                        segmentWidgets.add(
                          Flexible(
                            flex: unfilledFlex,
                            child: SizedBox(
                              width: barWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                ),
                              ),
                            ),
                          ),
                        );

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: segmentWidgets.reversed.toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Horizontal bar for portrait mode
    return InkWell(
      onTap: () => GameDialogs.showMaturityStats(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          border: Border(
            bottom: BorderSide(
              color: isUnlocked ? Colors.greenAccent.withOpacity(0.4) : const Color(0xFFC5A059).withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const barHeight = 4.0;

                  final segmentWidgets = <Widget>[];

                  final denom = totalDecided <= 0 ? 1 : totalDecided;

                  for (final s in playerSegments) {
                    final percentage = (s.points / denom).clamp(0.0, 1.0);
                    final flexValue = (percentage * progress * 100).toInt().clamp(1, 100);

                    if (flexValue < 1) continue;

                    segmentWidgets.add(
                      Flexible(
                        flex: flexValue,
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: s.color,
                            boxShadow: [
                              BoxShadow(
                                color: s.color.withOpacity(0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Unfilled section (undecided voters)
                  final unfilledFlex = ((1 - progress) * 100).toInt().clamp(1, 100);
                  segmentWidgets.add(
                    Flexible(
                      flex: unfilledFlex,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                  );

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: segmentWidgets,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFC5A059),
      child: Center(
        child: Text(
          'VICTORY: $winner',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
        ),
      ),
    );
  }
}

class _GameGrid extends StatelessWidget {
  final GameState state;
  final List<(String, Color)> playerInfo;
  final TransformationController transformationController;
  final GamePlayerState actualTurnPlayer;
  final Animation<double> glowAnimation;

  const _GameGrid({
    required this.state,
    required this.playerInfo,
    required this.transformationController,
    required this.actualTurnPlayer,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableSize = constraints.biggest.shortestSide * 0.98;
        final double cellWidth = availableSize / state.gridSize;
        final double iconSize = (cellWidth * 0.75).clamp(8.0, 48.0);

        return SizedBox(
          width: availableSize,
          height: availableSize,
          child: InteractiveViewer(
            transformationController: transformationController,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 4.0,
            child: RepaintBoundary(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridBackgroundPainter(
                        state: state,
                        playerInfo: playerInfo,
                        currentPlayerPos: actualTurnPlayer.pos,
                        isHumanTurn: actualTurnPlayer.type == PlayerType.human,
                        isSpectating: state.isSpectating,
                        isUnlocked: state.couldReachCenter ?? false,
                      ),
                    ),
                  ),
                  GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: state.gridSize),
                    itemCount: state.gridSize * state.gridSize,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final x = index ~/ state.gridSize;
                      final y = index % state.gridSize;
                      final pos = Position(x, y);
                      return GridCell(
                        ownership: state.gridOwnership[x][y],
                        cellValue: state.grid[x][y],
                        playerInfo: playerInfo,
                        pos: pos,
                        currentPlayerPos: actualTurnPlayer.pos,
                        currentPlayerId: actualTurnPlayer.id,
                        isHumanTurn: actualTurnPlayer.type == PlayerType.human,
                        isSpectating: state.isSpectating,
                        winner: state.winner,
                        couldReachCenter: state.couldReachCenter ?? false,
                        gridSize: state.gridSize,
                        cellWidth: cellWidth,
                        glowAnimation: glowAnimation,
                      );
                    },
                  ),
                  // Using IgnorePointer here to make sure clicks pass through players to grid cells
                  IgnorePointer(
                    child: Stack(
                      children: state.players.map((p) {
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
                      }).toList(),
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

  Offset _calculatePlayerOffset(GamePlayerState player, List<GamePlayerState> allPlayers, double cellWidth) {
    final sharing = allPlayers.where((p) => p.pos.equals(player.pos)).toList();
    if (sharing.length <= 1) return Offset.zero;
    final idx = sharing.indexOf(player);
    final double angle = (2 * pi * idx) / sharing.length;
    return Offset(cos(angle) * cellWidth * 0.25, sin(angle) * cellWidth * 0.25);
  }
}
