import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Draws four-point sparkles that twinkle in and out — the "freshly
/// cleaned" motif used on the splash, scan ring and success screen.
class SparkleField extends StatefulWidget {
  const SparkleField({super.key, this.count = 14, this.seed = 7, this.burst = false});
  final int count;
  final int seed;

  /// If true, sparkles fly outward from the centre once (celebration).
  final bool burst;

  @override
  State<SparkleField> createState() => _SparkleFieldState();
}

class _SparkleFieldState extends State<SparkleField> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final r = math.Random(widget.seed);
    _sparks = List.generate(
      widget.count,
      (_) => _Spark(
        angle: r.nextDouble() * math.pi * 2,
        dist: .25 + r.nextDouble() * .75,
        size: 4 + r.nextDouble() * 9,
        phase: r.nextDouble(),
      ),
    );
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.burst ? 1600 : 2600));
    widget.burst ? _c.forward() : _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            size: Size.infinite,
            painter: _SparklePainter(_sparks, _c.value, widget.burst),
          ),
        ),
      );
}

class _Spark {
  _Spark({required this.angle, required this.dist, required this.size, required this.phase});
  final double angle, dist, size, phase;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.sparks, this.t, this.burst);
  final List<_Spark> sparks;
  final double t;
  final bool burst;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    for (final s in sparks) {
      double alpha, scale, d;
      if (burst) {
        d = Curves.easeOutCubic.transform(t) * s.dist;
        alpha = (1 - t).clamp(0.0, 1.0);
        scale = .6 + .6 * math.sin(t * math.pi);
      } else {
        final p = (t + s.phase) % 1.0;
        final tw = math.sin(p * math.pi); // 0→1→0
        alpha = tw;
        scale = .3 + .7 * tw;
        d = s.dist;
      }
      final pos = c + Offset(math.cos(s.angle), math.sin(s.angle)) * (maxR * d);
      _star(canvas, pos, s.size * scale, Lux.blueLight.withValues(alpha: alpha.clamp(0.0, 1.0)));
    }
  }

  void _star(Canvas canvas, Offset p, double r, Color color) {
    final path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.t != t;
}
