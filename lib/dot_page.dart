import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DotReactionGame extends StatefulWidget {
  const DotReactionGame({super.key});

  @override
  State<DotReactionGame> createState() => _DotReactionGameState();
}

enum DotGameState { waiting, ready, tooEarly, missed, done }

class _DotReactionGameState extends State<DotReactionGame> {
  DotGameState _state = DotGameState.waiting;
  Timer? _timer;
  int _startTime = 0;
  int _reactionMs = 0;

  // Dot position stored as fractions (0.0–1.0) of the available space.
  // Converted to real pixels in build, so we don't need the screen
  // size inside the timer callback.
  double _dotXFraction = 0;
  double _dotYFraction = 0;

  static const double _dotSize = 80;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    setState(() => _state = DotGameState.waiting);
    final delay = 2000 + Random().nextInt(5000); // 2–7s
    _timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        _dotXFraction = Random().nextDouble();
        _dotYFraction = Random().nextDouble();
        _state = DotGameState.ready;
        _startTime = DateTime.now().millisecondsSinceEpoch;
      });
    });
  }

  void _goHome() {
    Navigator.pop(context);
  }

  // Taps anywhere on the background.
  void _onBackgroundTap() {
    switch (_state) {
      case DotGameState.waiting:
        _timer?.cancel();
        setState(() => _state = DotGameState.tooEarly);
        break;
      case DotGameState.ready:
        // Dot is showing but they tapped empty space instead of the dot.
        setState(() => _state = DotGameState.missed);
        break;
      case DotGameState.tooEarly:
      case DotGameState.missed:
      case DotGameState.done:
        _startRound();
        break;
    }
  }

  // Tap landed on the dot itself.
  void _onDotTap() {
    _reactionMs = DateTime.now().millisecondsSinceEpoch - _startTime;
    setState(() => _state = DotGameState.done);
  }

  String get _message {
    switch (_state) {
      case DotGameState.waiting:
        return 'Wait for the dot...';
      case DotGameState.ready:
        return '';
      case DotGameState.tooEarly:
        return 'Too early!\nTap to try again';
      case DotGameState.missed:
        return 'Missed!\nTap to try again';
      case DotGameState.done:
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
      backgroundColor: const Color.fromARGB(255, 21, 177, 0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final left = _dotXFraction * (constraints.maxWidth - _dotSize);
          final top = _dotYFraction * (constraints.maxHeight - _dotSize);

          return Stack(
            children: [
              // Full-screen background tap layer + message.
              GestureDetector(
                onTap: _onBackgroundTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              // The dot — only exists in the widget tree while ready.
              if (_state == DotGameState.ready)
                Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onTap: _onDotTap,
                    child: Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 66, 66, 66),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

              // Home button.
              SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: _goHome,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}