import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class NeuroTrackerGame extends StatefulWidget {
  const NeuroTrackerGame({super.key});

  @override
  State<NeuroTrackerGame> createState() => _NeuroTrackerGameState();
}

enum Phase { memorize, tracking, select, result }

// Plain data holder for one ball. isTarget/selected are just fields
// with defaults now — no longer constructor params, so no unused-param warning.
class _Ball {
  Offset position;
  Offset velocity;
  bool isTarget = false;
  bool selected = false;
  _Ball({required this.position, required this.velocity});
}

class _NeuroTrackerGameState extends State<NeuroTrackerGame>
    with SingleTickerProviderStateMixin {
  // --- fixed tuning ---
  static const double _ballSize = 40;
  double get _r => _ballSize / 2;

  // --- difficulty scales with round ---
  int _round = 1;
  bool _lastPassed = false;

  int get _ballCount => (6 + _round).clamp(6, 14);
  int get _targetCount => (2 + (_round ~/ 2)).clamp(2, 6);
  double get _baseSpeed => (120 + _round * 18).clamp(120, 320).toDouble();

  // --- colours ---
  static const Color _bgGreen = Color.fromARGB(255, 175, 175, 175);
  static const Color _neutral = Color.fromARGB(255, 100, 100, 100);
  static const Color _targetRed = Color.fromARGB(255, 140, 13, 13);

  Phase _phase = Phase.memorize;
  List<_Ball> _balls = [];

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  Timer? _phaseTimer;
  Size _playSize = Size.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _setupGame() {
    final rng = Random();
    final balls = <_Ball>[];
    int attempts = 0;

    while (balls.length < _ballCount && attempts < 2000) {
      attempts++;
      final pos = Offset(
        _r + rng.nextDouble() * (_playSize.width - 2 * _r),
        _r + rng.nextDouble() * (_playSize.height - 2 * _r),
      );
      final overlaps =
          balls.any((b) => (b.position - pos).distance < _ballSize * 1.15);
      if (overlaps) continue;

      final angle = rng.nextDouble() * 2 * pi;
      final speed = _baseSpeed + rng.nextDouble() * 80;
      balls.add(_Ball(
        position: pos,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
      ));
    }

    balls.shuffle();
    for (int i = 0; i < _targetCount && i < balls.length; i++) {
      balls[i].isTarget = true;
    }

    setState(() {
      _balls = balls;
      _phase = Phase.memorize;
    });

    _phaseTimer = Timer(const Duration(seconds: 2), () {
      setState(() => _phase = Phase.tracking);
      _phaseTimer = Timer(const Duration(seconds: 6), () {
        setState(() => _phase = Phase.select);
      });
    });
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    if (_phase != Phase.tracking || _balls.isEmpty) return;

    // 1. move + bounce off walls
    for (final ball in _balls) {
      var p = ball.position + ball.velocity * dt;
      var v = ball.velocity;

      if (p.dx < _r) {
        p = Offset(_r, p.dy);
        v = Offset(-v.dx, v.dy);
      } else if (p.dx > _playSize.width - _r) {
        p = Offset(_playSize.width - _r, p.dy);
        v = Offset(-v.dx, v.dy);
      }
      if (p.dy < _r) {
        p = Offset(p.dx, _r);
        v = Offset(v.dx, -v.dy);
      } else if (p.dy > _playSize.height - _r) {
        p = Offset(p.dx, _playSize.height - _r);
        v = Offset(v.dx, -v.dy);
      }

      ball.position = p;
      ball.velocity = v;
    }

    // 2. resolve ball-to-ball collisions
    for (int i = 0; i < _balls.length; i++) {
      for (int j = i + 1; j < _balls.length; j++) {
        final a = _balls[i];
        final b = _balls[j];
        final delta = b.position - a.position;
        final dist = delta.distance;
        if (dist > 0 && dist < _ballSize) {
          final n = delta / dist; // unit normal, a -> b

          // push them apart so they don't stick
          final overlap = _ballSize - dist;
          a.position -= n * (overlap / 2);
          b.position += n * (overlap / 2);

          // relative velocity along the normal
          final relV = a.velocity - b.velocity;
          final relAlongN = relV.dx * n.dx + relV.dy * n.dy;

          // only resolve if they're actually approaching
          if (relAlongN > 0) {
            // equal masses: exchange the normal components
            a.velocity -= n * relAlongN;
            b.velocity += n * relAlongN;
          }
        }
      }
    }

    // 3. clamp back inside in case a collision nudged one out
    for (final ball in _balls) {
      ball.position = Offset(
        ball.position.dx.clamp(_r, _playSize.width - _r),
        ball.position.dy.clamp(_r, _playSize.height - _r),
      );
    }

    setState(() {});
  }

  void _onBallTap(_Ball b) {
    if (_phase != Phase.select) return;
    setState(() => b.selected = !b.selected);
  }

  void _reveal() {
    final correct = _balls.where((b) => b.isTarget && b.selected).length;
    final wrong = _balls.where((b) => !b.isTarget && b.selected).length;
    _lastPassed = correct == _targetCount && wrong == 0;
    setState(() => _phase = Phase.result);
  }

  void _restart() {
    _phaseTimer?.cancel();
    // adaptive staircase: nail it -> harder, miss -> easier
    if (_lastPassed) {
      _round++;
    } else if (_round > 1) {
      _round--;
    }
    _setupGame();
  }

  void _goHome() => Navigator.pop(context);

  Color _ballColour(_Ball b) {
    if (_phase == Phase.memorize || _phase == Phase.result) {
      return b.isTarget ? _targetRed : _neutral;
    }
    return _neutral; // tracking + select: all identical
  }

  Border? _ballBorder(_Ball b) {
    if (_phase == Phase.select && b.selected) {
      return Border.all(color: Colors.white, width: 4);
    }
    if (_phase == Phase.result) {
      if (b.selected && b.isTarget) {
        return Border.all(color: Colors.greenAccent, width: 4);
      }
      if (b.selected && !b.isTarget) {
        return Border.all(color: const Color.fromRGBO(255, 235, 59, 1), width: 4);
      }
    }
    return null;
  }

  String get _status {
    switch (_phase) {
      case Phase.memorize:
        return 'Round $_round · track red balls';
      case Phase.tracking:
        return 'Track them...';
      case Phase.select:
        return 'Tap the $_targetCount targets';
      case Phase.result:
        final correct =
            _balls.where((b) => b.isTarget && b.selected).length;
        return '$correct / $_targetCount correct · '
            '${_lastPassed ? 'level up!' : 'try again'}';
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGreen,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_initialized) {
            _initialized = true;
            _playSize = Size(constraints.maxWidth, constraints.maxHeight);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _setupGame();
            });
          }

          return Stack(
            children: [
              for (final ball in _balls)
                Positioned(
                  left: ball.position.dx - _r,
                  top: ball.position.dy - _r,
                  child: GestureDetector(
                    onTap: () => _onBallTap(ball),
                    child: Container(
                      width: _ballSize,
                      height: _ballSize,
                      decoration: BoxDecoration(
                        color: _ballColour(ball),
                        shape: BoxShape.circle,
                        border: _ballBorder(ball),
                      ),
                    ),
                  ),
                ),

              // fixation dot — fixed centre point to keep your eyes on
              const IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 235, 59, 1),
                        shape: BoxShape.circle,
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

              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              if (_phase == Phase.select || _phase == Phase.result)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton(
                        onPressed:
                            _phase == Phase.select ? _reveal : _restart,
                        child: Text(
                          _phase == Phase.select ? 'Reveal' : 'Play again',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}