import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerPage extends StatefulWidget {
  final String assetPath;
  final VoidCallback onFinished;

  const VideoPlayerPage({
    super.key,
    required this.assetPath,
    required this.onFinished,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _player.stream.completed.listen((completed) {
      if (completed && !_isFinished) {
        _onVideoEnd();
      }
    });

    _player.stream.error.listen((error) {
      debugPrint("MediaKit Error: $error");
      _onVideoEnd();
    });

    try {
      await _player.open(Media('asset:///${widget.assetPath}'));
    } catch (e) {
      debugPrint("Failed to open video: $e");
      _onVideoEnd();
    }
  }

  void _onVideoEnd() {
    if (_isFinished) return;
    _isFinished = true;
    
    Future.microtask(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeInTransition(
        child: GestureDetector(
          onTap: _onVideoEnd,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Center(
                child: Video(
                  controller: _videoController,
                  fill: Colors.black,
                  // Disable the built-in MediaKit UI controls
                  controls: NoVideoControls,
                ),
              ),
              Positioned(
                bottom: 40,
                right: 40,
                child: Text(
                  'TAP ANYWHERE TO SKIP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeInTransition extends StatefulWidget {
  final Widget child;
  const FadeInTransition({super.key, required this.child});

  @override
  State<FadeInTransition> createState() => _FadeInTransitionState();
}

class _FadeInTransitionState extends State<FadeInTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _animation, child: widget.child);
}
