import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_state.dart';
import 'settings.dart';
import 'sparkles.dart';
import 'theme.dart';

/// Full-screen "clean complete" celebration shown after items are removed.
class CleanSuccessScreen extends StatefulWidget {
  const CleanSuccessScreen({super.key, required this.freedBytes, required this.count});
  final int freedBytes, count;

  @override
  State<CleanSuccessScreen> createState() => _CleanSuccessScreenState();
}

class _CleanSuccessScreenState extends State<CleanSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Hap.heavy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Lux.bg,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.2), radius: 1.0, colors: [Color(0xFFDDE9FF), Lux.bg]),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(child: Padding(padding: EdgeInsets.all(20), child: SparkleField(count: 28, seed: 3, burst: true))),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: Lux.brandGradient,
                        boxShadow: [BoxShadow(color: Lux.blue.withValues(alpha: .45), blurRadius: 48, spreadRadius: 4)],
                      ),
                      child: const Icon(CupertinoIcons.checkmark_alt, color: Lux.bg, size: 60),
                    ).animate().scale(begin: const Offset(.3, .3), duration: 650.ms, curve: Curves.elasticOut).fadeIn(),
                    const SizedBox(height: 36),
                    Text('Beautifully clean', style: Lux.serif(40, w: FontWeight.w600))
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: .2),
                    const SizedBox(height: 10),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: widget.freedBytes.toDouble()),
                      duration: 1400.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Text(
                        formatBytes(v.round()),
                        style: Lux.serif(54, w: FontWeight.w700, c: Lux.blue),
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                    const SizedBox(height: 4),
                    Text('FREED · ${widget.count} ITEMS REMOVED',
                            style: Lux.sans(11, c: Lux.muted, ls: 3, w: FontWeight.w500))
                        .animate()
                        .fadeIn(delay: 600.ms),
                    const SizedBox(height: 14),
                    Text(
                      'Total freed with Doctor AI: ${formatBytes(AppSettings.i.freedBytes)}',
                      style: Lux.sans(12, c: Lux.muted),
                    ).animate().fadeIn(delay: 800.ms),
                    const SizedBox(height: 48),
                    BrandButton(label: 'DONE', onTap: () => Navigator.pop(context)).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
