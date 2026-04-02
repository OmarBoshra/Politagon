import 'package:flutter/material.dart';
import 'package:politagon/ui/splash_screen.dart';

void main() {
  runApp(const MyRootApp());
}

class MyRootApp extends StatelessWidget {
  const MyRootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Politagon',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A237E), // Deep Indigo
        scaffoldBackgroundColor: const Color(0xFF0D1117), // Very Dark Grey
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC5A059), // Gold/Brass Accent
          secondary: Color(0xFF4DB6AC), // Slate Teal
          surface: Color(0xFF161B22),
          onSurface: Colors.white70,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Color(0xFFC5A059),
            fontFamily: 'Georgia',
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFFC5A059),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFFC5A059),
          thumbColor: const Color(0xFFC5A059),
          overlayColor: const Color(0xFFC5A059).withOpacity(0.2),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(const Color(0xFFC5A059)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC5A059),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
