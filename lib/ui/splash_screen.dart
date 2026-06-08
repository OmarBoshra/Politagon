import 'dart:async';
import 'package:flutter/material.dart';
import 'game_options_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _skipped = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _timer = Timer(const Duration(seconds: 4), () {
      _goToNextPage();
    });
  }

  void _goToNextPage() {
    if (_skipped || !mounted) return;
    setState(() => _skipped = true);
    _timer?.cancel();
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const GameOptionsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: GestureDetector(
        onTap: _goToNextPage,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC5A059), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC5A059).withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.webp',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'POLITAGON',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: 8.0,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'THE ART OF POWER POLITICS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 4.0,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                right: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'TAP TO SKIP',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
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
