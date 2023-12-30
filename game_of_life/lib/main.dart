import 'package:flutter/material.dart';
import 'package:game_of_life/welcome_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Game of Life',
      home: WelcomeScreen(),
    );
  }
}

