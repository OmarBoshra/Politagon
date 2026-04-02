import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide PlayerState;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

import '../bloc/grid_game_event.dart';
import '../models/game_state.dart';
import '../models/position.dart';

class GridGame extends StatefulWidget {
  const GridGame({super.key});

  @override
  State<GridGame> createState() => _GridGameState();
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

  void _showWithdrawDialog(String playerId) {
    debugPrint('Showing withdraw dialog for player $playerId');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('WITHDRAW FROM RACE', style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to withdraw from the election?\n\n'
          'Your votes will be discarded and the remaining candidates will continue. '
          'If the remaining candidates\' total score falls below the threshold, the center will be locked again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Withdraw cancelled');
              Navigator.pop(dialogContext);
            },
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('Withdraw confirmed for player $playerId');
              context.read<GridGameBloc>().add(WithdrawEvent(playerId));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('WITHDRAW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
      if (!isCenter || state.couldReachCenter == true) {
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
        // The actual player whose turn it is
        final actualTurnPlayer = state.players.any((p) => p.id == state.turn)
            ? state.players.firstWhere((p) => p.id == state.turn)
            : state.players.isNotEmpty ? state.players.first : null;
        
        // The player being viewed (may differ in spectator mode)
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
                  _buildScoreboard(context, state),
                  if (state.winner != null) _buildWinnerBanner(context, state.winner!),
                  if (state.isSpectating) _buildSpectatorControls(context, state),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double availableSize = constraints.biggest.shortestSide * 0.95;
                          final double cellWidth = availableSize / state.gridSize;
                          final double iconSize = (cellWidth * 0.75).clamp(8.0, 48.0);
  
                          return SizedBox(
                            width: availableSize, height: availableSize,
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              boundaryMargin: const EdgeInsets.all(200),
                              child: Stack(
                                children: [
                                  GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: state.gridSize),
                                    itemCount: state.gridSize * state.gridSize,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final pos = Position(index ~/ state.gridSize, index % state.gridSize);
                                      // Use actualTurnPlayer for grid cell logic, not viewedPlayer
                                      return _buildGridCell(context, state, pos, actualTurnPlayer ?? state.players.first, cellWidth);
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
                                      width: cellWidth, height: cellWidth,
                                      child: Center(child: _buildPlayerIconFromState(p, iconSize, isCurrentTurn)),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildSpectatorControls(BuildContext context, GameState state) {
    final allAi = state.players.every((p) => p.type != PlayerType.human);
    
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('AI BATTLE MODE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(width: 16),
          if (allAi && state.winner == null)
            ElevatedButton.icon(
              onPressed: () => context.read<GridGameBloc>().add(AiMoveEvent(state.turn)),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('NEXT TURN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Offset _calculatePlayerOffset(GamePlayerState player, List<GamePlayerState> allPlayers, double cellWidth) {
    final sharing = allPlayers.where((p) => p.pos.equals(player.pos)).toList();
    if (sharing.length <= 1) return Offset.zero;
    final idx = sharing.indexOf(player);
    final double angle = (2 * pi * idx) / sharing.length;
    return Offset(cos(angle) * cellWidth * 0.25, sin(angle) * cellWidth * 0.25);
  }

  Widget _buildScoreboard(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: Color(0xFF161B22), border: Border(bottom: BorderSide(color: Color(0xFFC5A059), width: 0.5))),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: state.players.map((p) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _buildScoreItem(p, p.id == state.turn, state),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(GamePlayerState player, bool isCurrentTurn, GameState state) {
    final colors = [const Color(0xFF4DB6AC), const Color(0xFF81C784), const Color(0xFF9575CD), const Color(0xFF4FC3F7), const Color(0xFF7986CB)];
    final playerColor = _getPlayerColor(player, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTurn ? playerColor.withOpacity(0.08) : Colors.transparent,
        border: Border.all(color: isCurrentTurn ? playerColor.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(children: [
            _buildPlayerIconFromState(player, 14.0, false), 
            const SizedBox(width: 6), 
            Text(player.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isCurrentTurn ? playerColor : Colors.white70, fontSize: 10))
          ]),
          const SizedBox(height: 4),
          Text('${player.score}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildMiniStat('INF', player.influence, Colors.blueAccent),
              const SizedBox(width: 8),
              _buildMiniStat('POP', player.popularity, const Color(0xFFC5A059)),
            ],
          ),
          if (!state.isSpectating && isCurrentTurn && player.type == PlayerType.human && state.players.length > 1)
            GestureDetector(
              onTap: () {
                debugPrint('Withdraw button tapped for player ${player.id}');
                _showWithdrawDialog(player.id);
              },
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('WITHDRAW', style: TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 7, fontWeight: FontWeight.bold)),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getPlayerColor(GamePlayerState player, List<Color> colors) {
    switch (player.type) {
      case PlayerType.human: return colors[player.colorIndex % colors.length];
      case PlayerType.ai1: return const Color(0xFFE57373);
      case PlayerType.ai2: return const Color(0xFFFFB74D);
      case PlayerType.ai3: return const Color(0xFF90A4AE);
      case PlayerType.ai4: return const Color(0xFFCE93D8);
    }
  }

  Widget _buildWinnerBanner(BuildContext context, String winner) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16), color: const Color(0xFFC5A059), child: Center(child: Text('VICTORY: $winner', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))));
  }

  Widget _buildGridCell(BuildContext context, GameState state, Position pos, GamePlayerState currentPlayer, double cellWidth) {
    final centerIdx = state.gridSize ~/ 2;
    final isCenter = pos.x == centerIdx && pos.y == centerIdx;
    final bool isAdjacent = (pos.x - currentPlayer.pos.x).abs() + (pos.y - currentPlayer.pos.y).abs() == 1;
    final bool isTappable = !state.isSpectating && currentPlayer.type == PlayerType.human && state.winner == null && isAdjacent && (!isCenter || state.couldReachCenter == true);
    
    final distance = (pos.x - centerIdx).abs() + (pos.y - centerIdx).abs();
    final maxDist = centerIdx * 2;

    // Define thematic palettes for different grid depths
    final corePalette = [const Color(0xFF1A237E), const Color(0xFF283593), const Color(0xFF303F9F)]; // Blues
    final elitePalette = [const Color(0xFF004D40), const Color(0xFF00695C), const Color(0xFF00796B)]; // Teals
    final middlePalette = [const Color(0xFF2E7D32), const Color(0xFF388E3C), const Color(0xFF43A047)]; // Greens
    final lowPalette = [const Color(0xFF4E342E), const Color(0xFF5D4037), const Color(0xFF6D4C41)]; // Browns
    final edgePalette = [const Color(0xFF212121), const Color(0xFF424242), const Color(0xFF000000)]; // Greys/Blacks

    final allColors = [...corePalette, ...elitePalette, ...middlePalette, ...lowPalette, ...edgePalette];
    
    // Scale the color selection based on the current grid's maximum distance
    // This ensures that even in a 5x5 grid (max dist 4), colors are spread out
    // while in an 11x11 (max dist 10), they still remain unique.
    final colorIdx = ((distance / maxDist) * (allColors.length - 1)).round();
    final cellColor = allColors[colorIdx.clamp(0, allColors.length - 1)];

    final double fontSize = (cellWidth * 0.35).clamp(14.0, 22.0);

    return GestureDetector(
      onTap: isTappable ? () => context.read<GridGameBloc>().add(UserMoveEvent(currentPlayer.id, pos)) : null,
      child: AnimatedBuilder(
        animation: _glowAnimationController,
        builder: (context, child) {
          final showGlow = isCenter && state.couldReachCenter == true;
          return Container(
            margin: const EdgeInsets.all(1.0),
            decoration: BoxDecoration(
              color: cellColor.withOpacity(isTappable ? 0.9 : 0.6),
              border: Border.all(
                color: isTappable 
                  ? Colors.white.withOpacity(0.8) 
                  : isCenter 
                    ? const Color(0xFFC5A059).withOpacity(0.8) 
                    : Colors.white.withOpacity(0.05),
                width: isTappable ? 2.0 : 0.5,
              ),
              boxShadow: showGlow ? [
                BoxShadow(
                  color: const Color(0xFFC5A059).withOpacity(0.3 + (_glowAnimationController.value * 0.4)),
                  blurRadius: 10 * _glowAnimationController.value,
                  spreadRadius: 2 * _glowAnimationController.value,
                )
              ] : (isTappable ? [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 4, spreadRadius: 1)] : null),
            ),
            child: Center(
              child: isCenter 
                ? Icon(Icons.chair, color: const Color(0xFFC5A059), size: cellWidth * 0.5) 
                : Text(
                    '${state.grid[pos.x][pos.y]}', 
                    style: TextStyle(
                      fontSize: fontSize, 
                      fontWeight: FontWeight.bold,
                      color: isTappable ? Colors.white : Colors.white.withOpacity(0.4),
                      letterSpacing: -0.5,
                    )
                  )
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerIconFromState(GamePlayerState player, double size, bool isCurrentTurn) {
    final colors = [const Color(0xFF4DB6AC), const Color(0xFF81C784), const Color(0xFF9575CD), const Color(0xFF4FC3F7), const Color(0xFF7986CB)];
    final color = _getPlayerColor(player, colors);
    
    Widget icon = SvgPicture.string(_getPlayerSvg(player.type, color), width: size, height: size);
    
    if (isCurrentTurn) {
      return AnimatedBuilder(
        animation: _glowAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15 + (_glowAnimationController.value * 0.15)),
                  blurRadius: 4 + (_glowAnimationController.value * 4),
                  spreadRadius: 1 + (_glowAnimationController.value * 2),
                ),
              ],
            ),
            child: icon,
          );
        },
      );
    }
    
    return icon;
  }

  String _getPlayerSvg(PlayerType type, Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    const bodyPath = 'M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z';
    return '<svg viewBox="0 0 24 24"><path fill="#$hex" d="$bodyPath"/></svg>';
  }
}
