import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnticipationGame extends StatefulWidget {
  const AnticipationGame({super.key});

  @override
  State<AnticipationGame> createState() => _AnticipationGameState();
}

enum _Phase { preview, running, result }

class _AnticipationGameState extends State<AnticipationGame>
    with SingleTickerProviderStateMixin {
  // --- colours ---
  static const Color _bg = Color(0xFF101318);
  static const Color _accent = Color(0xFF3DD6C4); // path (visible)
  static const Color _ballCol = Color(0xFFFF7A45); // moving ball
  static const Color _targetCol = Color(0xFFFFD54F); // end marker
  static const Color _revealCol = Color(0xFFFF3B6B); // where it really was

  static const double _ballRadius = 12; // small ball, lots of room

  int _level = 1;

  // level-driven parameters
  int get _waypointCount => _level + 1; // L1 = 2 pts (straight), L2 = 3...
  double get _blindFraction => (0.22 + 0.09 * _level).clamp(0.22, 0.72);

  _Phase _phase = _Phase.preview;

  // path data
  ui.Path? _path;
  ui.PathMetric? _metric;
  double _pathLength = 0;
  double _blindStart = 0;
  double _speed = 250; // px/sec, set per round
  Offset? _startPt;
  Offset? _endPt;

  // run state
  final Stopwatch _watch = Stopwatch();
  double _ballDistance = 0;
  Offset? _revealPos;
  double _errorMs = 0;

  late final Ticker _ticker;
  Rect? _playRect;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  // ---- path building ----

  List<Offset> _generateWaypoints(int count, Rect rect, Random rng) {
    final pts = <Offset>[];
    int tries = 0;
    while (pts.length < count && tries < 3000) {
      tries++;
      final p = Offset(
        rect.left + rng.nextDouble() * rect.width,
        rect.top + rng.nextDouble() * rect.height,
      );
      if (pts.isEmpty || pts.every((q) => (q - p).distance > 150)) {
        pts.add(p);
      }
    }
    while (pts.length < count) {
      pts.add(Offset(
        rect.left + rng.nextDouble() * rect.width,
        rect.top + rng.nextDouble() * rect.height,
      ));
    }
    return pts;
  }

  // Straight segments joined by smooth arcs at each corner.
  ui.Path _buildRoundedPath(List<Offset> pts, double r) {
    final path = ui.Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }
    for (int i = 1; i < pts.length - 1; i++) {
      final prev = pts[i - 1], curr = pts[i], next = pts[i + 1];
      final v1 = curr - prev, v2 = next - curr;
      final l1 = v1.distance, l2 = v2.distance;
      final rr = min(r, min(l1, l2) / 2);
      final entry = curr - (v1 / l1) * rr; // stop short of corner
      final exit = curr + (v2 / l2) * rr; // resume after corner
      path.lineTo(entry.dx, entry.dy);
      path.quadraticBezierTo(curr.dx, curr.dy, exit.dx, exit.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  Offset? _posAt(double d) =>
      _metric?.getTangentForOffset(d.clamp(0, _pathLength))?.position;

  void _newRound() {
    if (_playRect == null) return;
    _watch
      ..stop()
      ..reset();
    final rng = Random();
    _speed = (230 + _level * 12 + rng.nextDouble() * 30) * 0.5;

    final pts = _generateWaypoints(_waypointCount, _playRect!, rng);
    _path = _buildRoundedPath(pts, 46);
    _metric = _path!.computeMetrics().first;
    _pathLength = _metric!.length;
    _blindStart = _pathLength * (1 - _blindFraction);
    _startPt = _posAt(0);
    _endPt = _posAt(_pathLength);

    _ballDistance = 0;
    _revealPos = null;
    setState(() => _phase = _Phase.preview);
  }

  void _go() {
    if (_phase != _Phase.preview) return;
    _ballDistance = 0;
    _watch
      ..reset()
      ..start();
    setState(() => _phase = _Phase.running);
  }

  void _onTick(Duration _) {
    if (_phase != _Phase.running) return;
    final sec = _watch.elapsedMicroseconds / 1e6;
    _ballDistance = _speed * sec;
    final endTime = _pathLength / _speed;
    // if they freeze well past the end, auto-close the round
    if (sec > endTime * 1.6) {
      _register(_watch.elapsedMicroseconds);
      return;
    }
    setState(() {});
  }

  void _register(int microTap) {
    _watch.stop();
    final tapSec = microTap / 1e6;
    final tapDist = _speed * tapSec;
    final endTime = _pathLength / _speed;
    _errorMs = (tapSec - endTime) * 1000.0; // + = late, - = early
    _revealPos = _posAt(tapDist.clamp(0.0, _pathLength));
    setState(() => _phase = _Phase.result);
  }

void _onTapDown(TapDownDetails _) {
    if (_phase == _Phase.preview) {
      _go();
      return;
    }
    if (_phase == _Phase.result) {
      _newRound();
      return;
    }
    if (_phase != _Phase.running) return;
    _register(_watch.elapsedMicroseconds);
  }

  void _goHome() => Navigator.pop(context);

  String get _status {
    switch (_phase) {
      case _Phase.preview:
        return 'Level $_level';
      case _Phase.running:
        return _ballDistance < _blindStart
            ? 'Watch the speed...'
            : 'NOW — tap at the target!';
      case _Phase.result:
        final e = _errorMs.round();
        final mag = e.abs();
        final word = mag < 40
            ? 'perfect'
            : mag < 100
                ? 'great'
                : mag < 200
                    ? 'good'
                    : (e > 0 ? 'too late' : 'too early');
        return '${e >= 0 ? '+' : ''}$e ms · $word';
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_playRect == null) {
            _playRect = Rect.fromLTRB(
              50, 130, constraints.maxWidth - 50, constraints.maxHeight - 110);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _newRound();
            });
          }

          Offset? ballPos;
          if (_phase == _Phase.preview) {
            ballPos = _startPt; // resting at the start line
          } else if (_phase == _Phase.running && _ballDistance < _blindStart) {
            ballPos = _posAt(_ballDistance);
          }

          return Stack(
            children: [
              // play area (draws path + ball, and catches the timing tap)
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  behavior: HitTestBehavior.opaque,
                  child: _path == null
                      ? const SizedBox.expand()
                      : CustomPaint(
                          painter: _PathPainter(
                            path: _path!,
                            blindStart: _blindStart,
                            length: _pathLength,
                            startPt: _startPt,
                            endPt: _endPt,
                            ballPos: ballPos,
                            revealPos:
                                _phase == _Phase.result ? _revealPos : null,
                            radius: _ballRadius,
                          ),
                          child: const SizedBox.expand(),
                        ),
                ),
              ),

              // home
              SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: _goHome,
                ),
              ),

              // status
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // level selector (hidden while running)
              if (_phase != _Phase.running)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [for (int l = 1; l <= 5; l++) _levelButton(l)],
                      ),
                    ),
                  ),
                ),

              // action button
              if (_phase != _Phase.running)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton(
                        onPressed: _phase == _Phase.preview ? _go : _newRound,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 18),
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          _phase == _Phase.preview ? 'Go' : 'Next',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
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

  Widget _levelButton(int lvl) {
    final active = lvl == _level;
    return GestureDetector(
      onTap: () {
        if (_phase == _Phase.running) return;
        _level = lvl;
        _newRound();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _accent : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _accent : Colors.white24),
        ),
        child: Text(
          '$lvl',
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final ui.Path path;
  final double blindStart;
  final double length;
  final Offset? startPt;
  final Offset? endPt;
  final Offset? ballPos;
  final Offset? revealPos;
  final double radius;

  _PathPainter({
    required this.path,
    required this.blindStart,
    required this.length,
    required this.startPt,
    required this.endPt,
    required this.ballPos,
    required this.revealPos,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final metric = path.computeMetrics().first;

    // visible portion — solid, bright
    canvas.drawPath(
      metric.extractPath(0, blindStart),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = _AnticipationGameState._accent,
    );

    // blind portion — faint, so you see the route but know the ball vanishes
    canvas.drawPath(
      metric.extractPath(blindStart, length),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = _AnticipationGameState._accent.withValues(alpha: 0.25),
    );

    // start dot
    if (startPt != null) {
      canvas.drawCircle(startPt!, 6, Paint()..color = Colors.white70);
    }

    // target marker at the end
    if (endPt != null) {
      canvas.drawCircle(
        endPt!,
        16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _AnticipationGameState._targetCol,
      );
      canvas.drawCircle(
          endPt!, 3, Paint()..color = _AnticipationGameState._targetCol);
    }

    // moving ball (only while visible)
    if (ballPos != null) {
      canvas.drawCircle(
          ballPos!, radius, Paint()..color = _AnticipationGameState._ballCol);
    }

    // reveal: where the ball actually was when you tapped
    if (revealPos != null) {
      canvas.drawCircle(revealPos!, radius,
          Paint()..color = _AnticipationGameState._revealCol);
      if (endPt != null) {
        canvas.drawLine(
          revealPos!,
          endPt!,
          Paint()
            ..color = _AnticipationGameState._revealCol.withValues(alpha: 0.6)
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => true;
}