import 'package:flutter/material.dart';
import 'reaction_game_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Reaction Game',
      home: ReactionGamePage(),
    );
  }
}
