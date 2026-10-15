import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'ad_service.dart';
import 'gemini_service.dart';
import 'paywall_screen.dart';
import 'scanner.dart';
import 'settings.dart';
import 'theme.dart';

class DoctorPrescriptionCard extends StatefulWidget {
  const DoctorPrescriptionCard({
    super.key,
    required this.scanResult,
    required this.onSmartClean,
    this.onOpenCategory,
  });

  final ScanResult scanResult;
  final VoidCallback onSmartClean;
  final void Function(String category)? onOpenCategory;

  @override
  State<DoctorPrescriptionCard> createState() => _DoctorPrescriptionCardState();
}

class _DoctorPrescriptionCardState extends State<DoctorPrescriptionCard> {
  DoctorPrescription? _prescription;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchPrescription();
  }

  @override
  void didUpdateWidget(covariant DoctorPrescriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scanResult != widget.scanResult) {
      _fetchPrescription();
    }
  }

  Future<void> _fetchPrescription() async {
    setState(() => _loading = true);
    final p = await GeminiService.i.getPrescription(widget.scanResult);
    if (mounted) {
      setState(() {
        _prescription = p;
        _loading = false;
      });
    }
  }

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981); // Emerald Green
    if (score >= 70) return Lux.blue; // Royal Blue
    return const Color(0xFFF59E0B); // Amber Warning
  }

  void _watchAdToUnlock(BuildContext context) {
    Hap.medium();
    if (AdService.i.isRewardedAdAvailable) {
      AdService.i.showRewardedAd(
        onUserEarnedReward: (reward) {
          Hap.heavy();
          AppSettings.i.unlockDiagnostic();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Doctor AI Diagnostic Unlocked!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        },
        onDismissed: () {},
        onFailed: () {
          AppSettings.i.unlockDiagnostic();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor AI Diagnostic Unlocked!'),
            ),
          );
        },
      );
    } else {
      // Trigger preload
      AdService.i.loadRewardedAd();
      // Provide graceful fallback action so user is never permanently blocked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connecting to ad sponsor... Tap again to view or unlock now.'),
          action: SnackBarAction(
            label: 'UNLOCK NOW',
            textColor: Lux.blue,
            onPressed: () {
              Hap.heavy();
              AppSettings.i.unlockDiagnostic();
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.i,
      builder: (context, _) {
        final isUnlocked = AppSettings.i.isDoctorAiUnlocked;
        final p = _prescription;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Lux.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Lux.blue.withValues(alpha: .30), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Lux.blue.withValues(alpha: .08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Title + Status Badges
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Lux.blue.withValues(alpha: .12),
                      border: Border.all(color: Lux.blue.withValues(alpha: .3)),
                    ),
                    child: Icon(
                      isUnlocked ? CupertinoIcons.heart_fill : CupertinoIcons.lock_shield_fill,
                      color: Lux.blue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCTOR AI DIAGNOSIS',
                          style: Lux.sans(10, c: Lux.blue, w: FontWeight.w800, ls: 1.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isUnlocked ? 'Storage Health Prescription' : 'Storage Health · Locked',
                          style: Lux.sans(12, c: Lux.muted, w: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: .3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.lock_fill, size: 10, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            'LOCKED',
                            style: Lux.sans(9, c: const Color(0xFFF59E0B), w: FontWeight.w800, ls: 0.8),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (p?.isGeminiGenerated ?? false)
                                ? Lux.blue.withValues(alpha: .15)
                                : Lux.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (p?.isGeminiGenerated ?? false)
                                  ? Lux.blue
                                  : Lux.blue.withValues(alpha: .2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (p?.isGeminiGenerated ?? false) ? CupertinoIcons.sparkles : CupertinoIcons.checkmark_seal,
                                size: 11,
                                color: Lux.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (p?.isGeminiGenerated ?? false) ? 'DOCTOR AI' : 'ON-DEVICE',
                                style: Lux.sans(9, c: Lux.blue, w: FontWeight.w700, ls: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: .3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.lock_open_fill, size: 10, color: Color(0xFF10B981)),
                              const SizedBox(width: 3),
                              Text(
                                'UNLOCKED',
                                style: Lux.sans(8, c: const Color(0xFF10B981), w: FontWeight.w800, ls: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1, color: Lux.surface2),
              const SizedBox(height: 18),

              if (!isUnlocked)
                _buildLockedView(context)
              else if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: Lux.blue, strokeWidth: 2.5),
                        const SizedBox(height: 14),
                        Text(
                          'Doctor AI analyzing library...',
                          style: Lux.sans(12, c: Lux.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else if (p != null) ...[
                // Score + Diagnosis Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Health Score Ring
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _scoreColor(p.healthScore).withValues(alpha: .12),
                        border: Border.all(color: _scoreColor(p.healthScore), width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${p.healthScore}',
                              style: Lux.sans(18, c: _scoreColor(p.healthScore), w: FontWeight.w800),
                            ),
                            Text(
                              p.healthGrade,
                              style: Lux.sans(10, c: _scoreColor(p.healthScore), w: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.diagnosis,
                            style: Lux.serif(20, w: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.summary,
                            style: Lux.sans(13, c: Lux.muted).copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Key Symptoms (interactive tap to view)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Lux.surface2.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'DETECTED SYMPTOMS',
                              style: Lux.sans(10, c: Lux.muted, w: FontWeight.w600, ls: 1.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TAP TO REVIEW',
                            style: Lux.sans(9, c: Lux.blue, w: FontWeight.w700, ls: 0.8),
                          ),
                          const SizedBox(width: 2),
                          const Icon(CupertinoIcons.chevron_right, size: 9, color: Lux.blue),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final symptom in p.symptoms)
                        GestureDetector(
                          onTap: () {
                            Hap.light();
                            final s = symptom.toLowerCase();
                            if (s.contains('screenshot')) {
                              widget.onOpenCategory?.call('screenshots');
                            } else if (s.contains('blur')) {
                              widget.onOpenCategory?.call('blurry');
                            } else if (s.contains('video')) {
                              widget.onOpenCategory?.call('videos');
                            } else if (s.contains('cluster') || s.contains('duplicate') || s.contains('similar')) {
                              widget.onOpenCategory?.call('similar');
                            } else {
                              widget.onSmartClean();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Lux.blue.withValues(alpha: .2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.photo_on_rectangle, size: 14, color: Lux.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    symptom,
                                    style: Lux.sans(12, c: Lux.text, w: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(CupertinoIcons.chevron_right, size: 12, color: Lux.blue),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Prescribed Cure Banner (interactive tap to review)
                Builder(
                  builder: (context) {
                    final hasClutter = widget.scanResult.smartCleanBytes > 0;
                    return GestureDetector(
                      onTap: () {
                        Hap.medium();
                        if (hasClutter) {
                          widget.onSmartClean();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Lux.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Lux.blue.withValues(alpha: .3)),
                              ),
                              content: Row(
                                children: [
                                  const Icon(CupertinoIcons.checkmark_seal_fill, color: Lux.blue, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Your storage is in pristine condition! No clutter to clean.',
                                      style: Lux.sans(12, c: Lux.text, w: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEAF2FF),
                              Color(0xFFD6E6FE),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Lux.blue.withValues(alpha: .3)),
                          boxShadow: [
                            BoxShadow(
                              color: Lux.blue.withValues(alpha: .10),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.bandage_fill, color: Lux.blue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PRESCRIBED CURE',
                                    style: Lux.sans(10, c: Lux.blue, w: FontWeight.w800, ls: 1.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.prescription,
                                    style: Lux.sans(12, c: Lux.blueDark, w: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: hasClutter ? Lux.brandGradient : null,
                                color: hasClutter ? null : Lux.surface2,
                                borderRadius: BorderRadius.circular(12),
                                border: hasClutter ? null : Border.all(color: Lux.blue.withValues(alpha: .3)),
                                boxShadow: hasClutter
                                    ? [
                                        BoxShadow(
                                          color: Lux.blue.withValues(alpha: .3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    hasClutter ? 'REVIEW' : 'PRISTINE',
                                    style: Lux.sans(10, c: hasClutter ? Lux.bg : Lux.blue, w: FontWeight.w800, ls: 1),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    hasClutter ? CupertinoIcons.chevron_right : CupertinoIcons.checkmark_alt,
                                    size: 10,
                                    color: hasClutter ? Lux.bg : Lux.blue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Footer / API Key notice or re-run
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.isGeminiGenerated
                          ? 'Evaluated in real-time by Doctor AI'
                          : 'Evaluated by Doctor AI Clinical Engine',
                      style: Lux.sans(11, c: Lux.muted),
                    ),
                    IconButton(
                      tooltip: 'Re-evaluate Diagnosis',
                      icon: const Icon(CupertinoIcons.arrow_clockwise, size: 16, color: Lux.blue),
                      onPressed: _fetchPrescription,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: .08);
      },
    );
  }

  Widget _buildLockedView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: Lux.surface2.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Lux.blue.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Lux.blue.withValues(alpha: .12),
              border: Border.all(color: Lux.blue.withValues(alpha: .35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Lux.blue.withValues(alpha: .15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(CupertinoIcons.lock_shield_fill, color: Lux.blue, size: 28),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Doctor AI Diagnostic Locked',
            style: Lux.serif(22, w: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Doctor AI has evaluated your photo library. Watch a short sponsor message to unlock your Storage Health Grade, detected bloat symptoms, and customized prescription.',
            style: Lux.sans(12, c: Lux.muted).copyWith(height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _watchAdToUnlock(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
              decoration: BoxDecoration(
                gradient: Lux.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Lux.blue.withValues(alpha: .35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.play_circle_fill, color: Lux.bg, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      'WATCH AD TO UNLOCK',
                      style: Lux.sans(12, c: Lux.bg, w: FontWeight.w800, ls: 1.0),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'REWARD',
                        style: Lux.sans(9, c: Colors.black, w: FontWeight.w900, ls: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Hap.light();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.sparkles, size: 14, color: Lux.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Unlock Permanently with VIP · Ad-Free',
                    style: Lux.sans(12, c: Lux.blue, w: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
