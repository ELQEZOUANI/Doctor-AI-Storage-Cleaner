import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'ad_service.dart';
import 'sparkles.dart';
import 'theme.dart';

/// Animated brand splash screen with a high-velocity rushing loading bar
/// and luxury midnight dark blue presentation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _initAttAndProgress();
  }

  Future<void> _initAttAndProgress() async {
    // Wait until the view hierarchy is fully mounted and active
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      // Trigger Apple App Tracking Transparency authorization dialog
      await AdService.i.requestTrackingAuthorization();
      if (!mounted) return;

      _progressController.forward().then((_) {
        _sweepController.stop();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) widget.onDone();
        });
      });
    });
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _statusText(double v) {
    if (v < 0.18) return 'INITIALIZING AI ENGINE';
    if (v < 0.38) return 'SCANNING STORAGE CLUTTER';
    if (v < 0.65) return 'RUSHING DEEP CLEAN SCAN';
    if (v < 0.88) return 'PURGING JUNK & DUPLICATES';
    if (v < 0.99) return 'OPTIMIZING MEMORY HEALTH';
    return 'SYSTEM PRISTINE · 100%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFF123466),
              Color(0xFF0A192F),
              Color(0xFF050E1A),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: SparkleField(count: 18),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Icon with Midnight Aura
                Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E52A8).withValues(alpha: 0.65),
                        blurRadius: 40,
                        spreadRadius: 6,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset('assets/icon/icon_1024.png', fit: BoxFit.cover),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(.88, .88), end: const Offset(1, 1), duration: 700.ms, curve: Curves.easeOutBack)
                    .then(delay: 150.ms)
                    .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: .4)),

                const SizedBox(height: 32),

                // Luxury Brand Typography
                Text(
                  'DOCTOR AI',
                  style: Lux.sans(16, c: Colors.white, w: FontWeight.w700, ls: 8),
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 500.ms)
                    .slideY(begin: .3, curve: Curves.easeOut),

                const SizedBox(height: 8),

                Text(
                  'Storage Cleaner · AI Diagnostics',
                  style: Lux.serif(19, c: const Color(0xFFD6E3F8)),
                )
                    .animate()
                    .fadeIn(delay: 550.ms, duration: 500.ms),

                const SizedBox(height: 48),

                // Rushing Loading Bar Section (0% to 100% over 5 seconds)
                AnimatedBuilder(
                  animation: Listenable.merge([_progressAnimation, _sweepController]),
                  builder: (context, _) {
                    final v = _progressAnimation.value.clamp(0.0, 1.0);
                    final pct = (v * 100).toInt();
                    final sweep = _sweepController.value;

                    return SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          // Rushing Progress Track with Cleaning Brush Head
                          SizedBox(
                            height: 14,
                            width: 260,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.centerLeft,
                              children: [
                                // Background Track
                                Container(
                                  height: 7,
                                  width: 260,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                ),

                                // Filled Gradient Bar (Pristine Cleaned Track)
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: v == 0 ? 0.005 : v,
                                  child: Container(
                                    height: 7,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0F3E8A),
                                          Color(0xFF2563EB),
                                          Color(0xFF38BDF8),
                                          Colors.white,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.85),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Elegant Cleaning Brush & Light Rush
                                if (v > 0.01)
                                  Positioned(
                                    left: ((260 * v) - 10).clamp(-4.0, 260 - 10.0),
                                    top: -20,
                                    child: CleaningBrushHead(
                                      progress: v,
                                      sweepValue: sweep,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Dynamic Phase Caption & Percentage
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _statusText(v),
                                  style: Lux.sans(9.5, c: const Color(0xFF94A3B8), w: FontWeight.w600, ls: 1),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$pct%',
                                style: Lux.sans(12, c: Colors.white, w: FontWeight.w800, ls: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Elegant Luxury Brush & Radiant Light Rush sweeping along the loading bar
class CleaningBrushHead extends StatelessWidget {
  const CleaningBrushHead({
    super.key,
    required this.progress,
    required this.sweepValue,
  });

  final double progress;
  final double sweepValue;

  @override
  Widget build(BuildContext context) {
    // Graceful sine-wave sway: gentle rocking between -26° and -34°
    final angle = (-30.0 + (sweepValue - 0.5) * 8.0) * (math.pi / 180.0);
    // Micro scrub motion along the track
    final scrubX = (sweepValue - 0.5) * 1.8;

    return Transform.translate(
      offset: Offset(scrubX, 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. ELEGANT RUSH OF LIGHT (Trailing glowing wave along the cleaned bar)
          Positioned(
            right: 12,
            bottom: 4,
            child: _LightRushTrail(sweep: sweepValue),
          ),

          // 2. Luminous contact halo where bristles kiss the loading track
          Positioned(
            left: 3,
            bottom: 4,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.95),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // 3. The Slender, High-End Luxury Brush / Stylus
          Transform.rotate(
            angle: angle,
            origin: const Offset(8, 28), // Pivot right at the bristle contact tip
            child: SizedBox(
              width: 30,
              height: 34,
              child: CustomPaint(
                painter: _ElegantBrushPainter(sweep: sweepValue),
              ),
            ),
          ),

          // 4. Floating Celestial Diamond Sparkles (Delicate, sparkling stardust)
          Positioned(
            top: -4,
            right: -2,
            child: _SparkleDiamond(
              size: 7 + (sweepValue * 2.5),
              color: Colors.white,
              opacity: 0.9 + (sweepValue * 0.1),
            ),
          ),
          Positioned(
            bottom: 8,
            left: -8,
            child: _SparkleDiamond(
              size: 5 + ((1.0 - sweepValue) * 2.5),
              color: const Color(0xFF38BDF8),
              opacity: 0.8 + ((1.0 - sweepValue) * 0.2),
            ),
          ),
          Positioned(
            top: 6,
            left: -4,
            child: _SparkleDiamond(
              size: 4 + (sweepValue * 2),
              color: const Color(0xFFFDE68A), // Champagne gold sparkle
              opacity: 0.7 + (sweepValue * 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trailing plume of radiant light (the "rush" of clean illumination)
class _LightRushTrail extends StatelessWidget {
  const _LightRushTrail({required this.sweep});
  final double sweep;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFF38BDF8).withValues(alpha: 0.85),
            const Color(0xFF1E52A8).withValues(alpha: 0.40),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
            blurRadius: 10,
            spreadRadius: 1.5,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Ultra-slender luxury brush painter with champagne gold collar & sable bristles
class _ElegantBrushPainter extends CustomPainter {
  const _ElegantBrushPainter({required this.sweep});
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Bristles: Smooth flowing sable brush curve kissing the track
    final bristlePath = Path();
    bristlePath.moveTo(13.0, 14.0); // top-left at ferrule
    bristlePath.lineTo(18.0, 15.5); // top-right at ferrule
    // Outer curve down to tip
    bristlePath.quadraticBezierTo(21.5, 22.0, 20.0, 28.0);
    // Sweeping contact edge
    bristlePath.quadraticBezierTo(13.0, 29.0, 7.5, 27.5);
    // Inner curve back to ferrule
    bristlePath.quadraticBezierTo(9.5, 21.0, 13.0, 14.0);
    bristlePath.close();

    final bristleShader = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white,
        Color(0xFFF0F6FF),
        Color(0xFFDBEAFE),
        Color(0xFF93C5FD),
      ],
      stops: [0.0, 0.4, 0.75, 1.0],
    ).createShader(const Rect.fromLTWH(7, 14, 15, 15));

    final bristlePaint = Paint()
      ..shader = bristleShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(bristlePath, bristlePaint);

    // Fine delicate bristle lines (silky texture)
    final strandPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final strand1 = Path()
      ..moveTo(14.5, 15.0)
      ..quadraticBezierTo(14.0, 22.0, 10.5, 27.5);
    canvas.drawPath(strand1, strandPaint);

    final strand2 = Path()
      ..moveTo(16.5, 15.2)
      ..quadraticBezierTo(17.5, 22.5, 15.5, 28.0);
    canvas.drawPath(strand2, strandPaint);

    // 2. Luxury Champagne Gold Ferrule (twin micro-bands)
    final goldShader = const LinearGradient(
      colors: [
        Color(0xFFD4AF37),
        Color(0xFFFFF2C2),
        Color(0xFFB8860B),
        Color(0xFFFFF7DB),
      ],
    ).createShader(const Rect.fromLTWH(11.5, 11.5, 8.5, 4.0));

    final ferrulePaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.fill;

    // Upper gold ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13.0, 11.5, 6.0, 1.6),
        const Radius.circular(0.8),
      ),
      ferrulePaint,
    );
    // Lower gold ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12.0, 13.5, 7.5, 1.6),
        const Radius.circular(0.8),
      ),
      ferrulePaint,
    );

    // 3. Slender Tapered Platinum / Titanium Stylus Handle
    final handlePath = Path();
    handlePath.moveTo(14.5, 11.5);
    handlePath.lineTo(17.0, 11.5);
    handlePath.lineTo(25.5, 2.5); // Tapering upward to finial
    handlePath.lineTo(24.2, 1.8);
    handlePath.close();

    final handleShader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Colors.white,
        Color(0xFFF1F5F9),
        Color(0xFFE2E8F0),
        Colors.white,
      ],
    ).createShader(const Rect.fromLTWH(14, 2, 12, 10));

    final handlePaint = Paint()
      ..shader = handleShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(handlePath, handlePaint);

    // Specular light edge along handle
    final glintPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(14.8, 11.0), const Offset(24.5, 2.0), glintPaint);

    // Finial Jewel at the top of handle (gold pearl)
    final jewelPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(25.0, 2.0), 1.5, jewelPaint);

    // Subtle glint on jewel
    final jewelGlint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(24.7, 1.7), 0.5, jewelGlint);
  }

  @override
  bool shouldRepaint(covariant _ElegantBrushPainter oldDelegate) => oldDelegate.sweep != sweep;
}

class _SparkleDiamond extends StatelessWidget {
  const _SparkleDiamond({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: CustomPaint(
        size: Size(size, size),
        painter: _SparkleDiamondPainter(color: color),
      ),
    );
  }
}

class _SparkleDiamondPainter extends CustomPainter {
  _SparkleDiamondPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2;

    final path = Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx, cy, cx + r, cy)
      ..quadraticBezierTo(cx, cy, cx, cy + r)
      ..quadraticBezierTo(cx, cy, cx - r, cy)
      ..quadraticBezierTo(cx, cy, cx, cy - r)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
