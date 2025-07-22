import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';

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
  late final AudioPlayer _audioPlayer;
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setSource(AssetSource('sounds/background.m4a'));
  }

  void _toggleMusic() async {
    if (_isMusicPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() => _isMusicPlaying = !_isMusicPlaying);
  }

  void _restartGame() {
    context.read<GridGameBloc>().add(RestartGameEvent());
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: 'Restart Game',
          ),
          IconButton(
            icon: Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off),
            onPressed: _toggleMusic,
            tooltip: 'Toggle Music',
          ),
        ],
      ),
      body: BlocListener<GridGameBloc, GameState>(
        listener: (context, state) {
          if (state.turn == 'user' && state.winner == null) {
            _focusNode.requestFocus();
          }
        },
        child: BlocBuilder<GridGameBloc, GameState>(
          builder: (context, state) {
            return Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKey: (node, event) {
                if (state.turn != 'user' || state.winner != null) {
                  return KeyEventResult.ignored;
                }

                if (event is RawKeyDownEvent) {
                  final userPos = state.userPos;
                  Position? newPos;

                  switch (event.logicalKey) {
                    case LogicalKeyboardKey.arrowUp:
                      if (userPos.x > 0) newPos = Position(userPos.x - 1, userPos.y);
                      break;
                    case LogicalKeyboardKey.arrowDown:
                      if (userPos.x < 4) newPos = Position(userPos.x + 1, userPos.y);
                      break;
                    case LogicalKeyboardKey.arrowLeft:
                      if (userPos.y > 0) newPos = Position(userPos.x, userPos.y - 1);
                      break;
                    case LogicalKeyboardKey.arrowRight:
                      if (userPos.y < 4) newPos = Position(userPos.x, userPos.y + 1);
                      break;
                    default:
                      return KeyEventResult.ignored;
                  }

                  if (newPos != null) {
                    context.read<GridGameBloc>().add(UserMoveEvent(newPos));
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildScoreboard(context, state),
                    const SizedBox(height: 20),
                    if (state.winner != null) _buildWinnerBanner(context, state.winner!),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: LayoutBuilder( // Use LayoutBuilder to get the constraints of the Stack
                            builder: (context, constraints) {
                              final double totalWidth = constraints.maxWidth;
                              final double totalHeight = constraints.maxHeight;
                              final double cellWidth = totalWidth / 5.0;
                              final double cellHeight = totalHeight / 5.0;

                              // The center cell in a 0-indexed 5x5 grid is at (row: 2, col: 2)
                              final double centerCellLeft = cellWidth * 2;
                              final double centerCellTop = cellHeight * 2;

                              return Stack(
                                children: [
                                  GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                    ),
                                    itemCount: 25,
                                    itemBuilder: (context, index) {
                                      final pos = Position(index ~/ 5, index % 5);
                                      return _buildGridCell(context, state, pos);
                                    },
                                  ),
                                  if (state.couldReachCenter == true)
                                    Positioned(
                                      left: centerCellLeft,
                                      top: centerCellTop,
                                      width: cellWidth,
                                      height: cellHeight,
                                      child: IgnorePointer( // Keep IgnorePointer if the glow shouldn't intercept taps
                                        child: AnimatedBuilder(
                                          animation: _glowAnimationController,
                                          builder: (context, child) {
                                            // The glow effect will now be contained within this Positioned widget,
                                            // which is exactly the size of the center cell.
                                            return Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.rectangle, // Or BoxShape.rect if you prefer
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.yellow.withOpacity(0.6 * _glowAnimationController.value),
                                                    // Adjust blurRadius and spreadRadius to look good
                                                    // relative to the smaller cell size.
                                                    // These values might need to be smaller now.
                                                    blurRadius: 8 * _glowAnimationController.value,  // Example: smaller blur
                                                    spreadRadius: 3 * _glowAnimationController.value, // Example: smaller spread
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.orange.withOpacity(0.4 * _glowAnimationController.value),
                                                    blurRadius: 12 * _glowAnimationController.value, // Example: smaller blur
                                                    spreadRadius: 5 * _glowAnimationController.value,  // Example: smaller spread
                                                  ),
                                                ],
                                              ),
                                              // Optional: If you want the glow container to be visible for debugging
                                              // child: Container(color: Colors.red.withOpacity(0.2)),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreboard(BuildContext context, GameState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('User: ${state.scores['user']}', style: Theme.of(context).textTheme.titleMedium),
        Text('AI 1: ${state.scores['ai1']}', style: Theme.of(context).textTheme.titleMedium),
        Text('AI 2: ${state.scores['ai2']}', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildWinnerBanner(BuildContext context, String winner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Text(
        '$winner Wins!',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  Widget _buildGridCell(BuildContext context, GameState state, Position pos) {
    final bool isTappable = state.turn == 'user' && state.winner == null;
    final distance = (pos.x - 2).abs() + (pos.y - 2).abs();
    final levelColors = [
      Colors.purple.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.red.shade300,
    ];
    final cellColor = levelColors[distance];
    final isCenterCell = pos.x == 2 && pos.y == 2;

    return GestureDetector(
      onTap: isTappable ? () => context.read<GridGameBloc>().add(UserMoveEvent(pos)) : null,
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCenterCell && state.couldReachCenter == true
                ? Colors.yellow
                : Colors.grey.shade700,
            width: isCenterCell && state.couldReachCenter == true ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8.0),
          color: cellColor.withOpacity(isTappable ? 0.9 : 0.7),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${state.grid[pos.x][pos.y]}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            _buildPlayerIcons(state, pos, cellColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerIcons(GameState state, Position pos, Color cellColor) {
    final players = [
      if (state.userPos.equals(pos)) 'user',
      if (state.ai1Pos.equals(pos)) 'ai1',
      if (state.ai2Pos.equals(pos)) 'ai2',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max size per icon (1/3 of cell width minus padding)
        final maxIconSize = (constraints.maxWidth - 8) / players.length;
        final iconSize = maxIconSize.clamp(20.0, 28.0); // Min 20px, max 28px

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: players.isNotEmpty
              ? Row(
            key: ValueKey(players.join()),
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: players
                .map((p) => _buildPlayerIcon(p, cellColor, iconSize))
                .toList(),
          )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildPlayerIcon(String playerType, Color cellColor, double size) {
    final playerColors = {
      'user': Colors.blue,
      'ai1': Colors.red,
      'ai2': Colors.orange,
    };

    // Create a contrasting stroke color (darker version of player color)
    final strokeColor = _darken(playerColors[playerType]!, 0.3);
    final blendedColor = Color.lerp(playerColors[playerType]!, cellColor, 0.6)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: SvgPicture.string(
        _getPlayerSvg(playerType, blendedColor, strokeColor),
        width: size,
        height: size,
      ),
    );
  }

// Helper function to darken a color
  Color _darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  String _getPlayerSvg(String playerType, Color color, Color strokeColor) {
    final hexColor = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    final strokeHex = strokeColor.value.toRadixString(16).padLeft(8, '0').substring(2);

    // Stroke properties
    const strokeWidth = 1.8;
    final strokeProps = 'stroke="#$strokeHex" stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round"';

    switch (playerType) {
      case 'user':
        return '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path $strokeProps fill="#$hexColor" d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
</svg>
''';
      case 'ai1':
        return '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path $strokeProps fill="#$hexColor" d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z"/>
</svg>
''';
      case 'ai2':
        return '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path $strokeProps fill="#$hexColor" d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
  <circle $strokeProps fill="#$hexColor" cx="18" cy="8" r="3"/>
</svg>
''';
      default:
        return '';
    }
  }
}