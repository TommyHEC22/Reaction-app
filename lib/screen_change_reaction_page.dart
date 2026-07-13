import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ScreenChangeReaction extends StatefulWidget {
  const ScreenChangeReaction({super.key});

  @override
  State<ScreenChangeReaction> createState() => _ScreenChangeReactionState();
}

enum GameState { waiting, ready, tooEarly, done }

class _ScreenChangeReactionState extends State<ScreenChangeReaction> {
  GameState _state = GameState.waiting;
  Timer? _timer;
  int _startTime = 0;
  int _reactionMs = 0;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    setState(() => _state = GameState.waiting);
    // random delay between 2 and 5 seconds
    final delay = 2000 + Random().nextInt(5000);
    _timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        _state = GameState.ready;
        _startTime = DateTime.now().millisecondsSinceEpoch;
      });
    });
  }

  void _goHome() {
    Navigator.pop(context);
  }

  void _onTap() {
    switch (_state) {
      case GameState.waiting:
        // tapped before colour changed
        _timer?.cancel();
        setState(() => _state = GameState.tooEarly);
        break;
      case GameState.ready:
        _reactionMs =
            DateTime.now().millisecondsSinceEpoch - _startTime;
        setState(() => _state = GameState.done);
        break;
      case GameState.tooEarly:
      case GameState.done:
        _startRound();
        break;
    }
  }

  Color get _bgColour {
    switch (_state) {
      case GameState.waiting:
        return Colors.red;
      case GameState.ready:
        return Colors.green;
      case GameState.tooEarly:
        return Colors.orange;
      case GameState.done:
        return Colors.blue;
    }
  }

  String get _message {
    switch (_state) {
      case GameState.waiting:
        return 'Wait for green...';
      case GameState.ready:
        return 'TAP!';
      case GameState.tooEarly:
        return 'Too early!\nTap to try again';
      case GameState.done:
        return '$_reactionMs ms\nTap to go again';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack (
        children: [
          GestureDetector(
            onTap: _onTap,
            child: Container(
              color: _bgColour,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    
                  ),
                ),
              ),
            ),
          ),
              SafeArea(
      child: IconButton(
        icon: const Icon(Icons.home, color: Colors.white),
        onPressed: _goHome,
      ),
    ),
  ],
),
        );
  }
}