// lib/main.dart
import 'package:flutter/material.dart';
import 'package:politagon/ui/splash_screen.dart';
void main() {
  runApp(MyRootApp());
}

/// This wraps the splash and the real app under one MaterialApp.
class MyRootApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}