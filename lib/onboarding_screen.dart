import 'dart:async';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'settings.dart';
import 'sparkles.dart';
import 'theme.dart';

/// Luxury, high-end Onboarding Screen explaining Doctor AI: Storage Cleaner's
/// clinical storage diagnosis, Gemini AI Best Shot curation, utility tools,
/// and Zero-Knowledge privacy model.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onComplete,
    this.initialPage = 0,
    this.autoCycle = false,
  });
  final VoidCallback? onComplete;
  final int initialPage;
  final bool autoCycle;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late int _currentPage;
  static const int _totalPages = 4;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);

    if (widget.autoCycle) {
      _cycleTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted) return;
        if (_currentPage < _totalPages - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _nextPage() {
    Hap.light();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _complete() {
    Hap.light();
    AppSettings.i.finishOnboarding();
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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
            radius: 1.3,
            colors: [
              Color(0xFF13366B),
              Color(0xFF0A192F),
              Color(0xFF040B14),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient Floating Sparkles
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: SparkleField(count: 14),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar (Badge & Skip)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Luxury Brand Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.sparkles, size: 12, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Text(
                                'DOCTOR AI GUIDE',
                                style: Lux.sans(10, c: const Color(0xFFDCE7F8), w: FontWeight.w700, ls: 1.5),
                              ),
                            ],
                          ),
                        ),

                        // Skip Button
                        TextButton(
                          onPressed: _complete,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF94A3B8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          ),
                          child: Text(
                            'Skip',
                            style: Lux.sans(13, c: const Color(0xFF94A3B8), w: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Interactive Page View
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) {
                        Hap.light();
                        setState(() => _currentPage = page);
                      },
                      children: [
                        _buildSlide1(),
                        _buildSlide2(),
                        _buildSlide3(),
                        _buildSlide4(),
                      ],
                    ),
                  ),

                  // Bottom Controls (Dots & Action Button)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Page Dots Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_totalPages, (index) {
                            final isActive = _currentPage == index;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Hap.light();
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  height: 6,
                                  width: isActive ? 28 : 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: isActive
                                        ? const LinearGradient(
                                            colors: [Color(0xFF38BDF8), Colors.white],
                                          )
                                        : null,
                                    color: isActive ? null : Colors.white.withValues(alpha: 0.22),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 22),

                        // Primary Action Button
                        GestureDetector(
                          onTap: _nextPage,
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF0F3E8A), Color(0xFF0A2350)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _totalPages - 1 ? 'START CLINICAL SCAN' : 'CONTINUE',
                                  style: Lux.sans(13, c: Colors.white, w: FontWeight.w700, ls: 2.2),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _totalPages - 1 ? CupertinoIcons.sparkles : CupertinoIcons.arrow_right,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SLIDE 1: CLINICAL STORAGE DIAGNOSIS
  // ===========================================================================
  Widget _buildSlide1() {
    return _SlideContainer(
      pillText: 'CLINICAL STORAGE MEDICINE',
      title: 'Diagnose Your Storage Health',
      subtitle:
          'Doctor AI treats digital clutter like a physician. We compute your Storage Vitality Grade, detect acute symptoms, and prescribe targeted cures.',
      visual: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: _glassCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Diagnosis Block: Left circular vitality ring, Right diagnosis details
            Row(
              children: [
                // Glowing Vitality Score Ring
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.22),
                        const Color(0xFF0F3E8A).withValues(alpha: 0.35),
                      ],
                    ),
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.30),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '92',
                          style: Lux.serif(30, c: Colors.white, w: FontWeight.w700),
                        ),
                        Text(
                          '/ 100',
                          style: Lux.sans(8, c: const Color(0xFF94A3B8), w: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Health Diagnostic Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '● OPTIMAL VITALITY · GRADE A',
                          style: Lux.sans(8.5, c: const Color(0xFF34D399), w: FontWeight.w700, ls: 0.8),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Storage Health Report',
                        style: Lux.sans(14, c: Colors.white, w: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '3 acute digital symptoms identified',
                        style: Lux.sans(11, c: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: Colors.white12, height: 1),
            ),

            // Diagnostic Vitals List (clean, aligned, professional rows)
            _symptomRow(
              icon: CupertinoIcons.square_on_square,
              iconColor: const Color(0xFF38BDF8),
              title: 'Duplicate Bursts',
              desc: 'Identical photos & bursts',
              stat: '1,420 items',
            ),
            const SizedBox(height: 10),
            _symptomRow(
              icon: CupertinoIcons.eye_slash,
              iconColor: const Color(0xFFF59E0B),
              title: 'Blurry & Dark Media',
              desc: 'Low clarity & failed shots',
              stat: '310 photos',
            ),
            const SizedBox(height: 10),
            _symptomRow(
              icon: CupertinoIcons.videocam,
              iconColor: const Color(0xFFA78BFA),
              title: 'Heavy 4K Videos',
              desc: 'High bitrate recordings',
              stat: '4.2 GB',
            ),

            const SizedBox(height: 14),

            // Clinical Prescription Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3E8A), Color(0xFF13366B)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.checkmark_alt, size: 14, color: Color(0xFF0A192F)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescribed Cure',
                          style: Lux.sans(11.5, c: Colors.white, w: FontWeight.w700),
                        ),
                        Text(
                          '1-Tap Reclaim 5.8 GB · 100% Safe Recovery',
                          style: Lux.sans(10, c: const Color(0xFF93C5FD)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SLIDE 2: GEMINI AI BEST SHOT PICKER
  // ===========================================================================
  Widget _buildSlide2() {
    return _SlideContainer(
      pillText: 'DOCTOR AI · MULTIMODAL VISION',
      title: 'Smart Best Shot Curation',
      subtitle:
          'Never waste hours comparing bursts. Powered by Doctor AI, our neural vision scores smiles, clarity, and focus to crown the best hero shot and discard the rest.',
      visual: Container(
        padding: const EdgeInsets.all(20),
        decoration: _glassCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Best Shot Candidate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3E8A).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '✦ AI BEST SHOT',
                            style: Lux.sans(8.5, c: const Color(0xFF0A192F), w: FontWeight.w800, ls: 1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Icon(CupertinoIcons.photo, size: 36, color: Colors.white),
                        const SizedBox(height: 8),
                        Text('Crisp Focus', style: Lux.sans(11, c: Colors.white, w: FontWeight.w600)),
                        Text('Open Eyes · Smiles', style: Lux.sans(9, c: const Color(0xFF94A3B8))),
                        const SizedBox(height: 8),
                        Text('✓ PRESERVE', style: Lux.sans(10, c: const Color(0xFF34D399), w: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Redundant Candidate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'REDUNDANT SHOT',
                            style: Lux.sans(8.5, c: const Color(0xFF94A3B8), w: FontWeight.w700, ls: 1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Icon(CupertinoIcons.photo, size: 36, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Motion Blur', style: Lux.sans(11, c: const Color(0xFFCBD5E1))),
                        Text('Duplicate Burst', style: Lux.sans(9, c: const Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        Text('🗑 SAFE PURGE', style: Lux.sans(10, c: const Color(0xFFF87171), w: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.sparkles, size: 13, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'AI pre-selects redundant shots for review',
                      style: Lux.sans(11, c: const Color(0xFFE2E8F0)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SLIDE 3: COMPLETE RECLAMATION SUITE
  // ===========================================================================
  Widget _buildSlide3() {
    return _SlideContainer(
      pillText: 'POWER SUITE · HARDWARE TOOLS',
      title: 'Triple Storage Recovery',
      subtitle:
          'Beyond photos: three dedicated hardware tools engineered to reclaim maximum gigabytes across your entire iPhone.',
      visual: Container(
        padding: const EdgeInsets.all(18),
        decoration: _glassCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolRow(
              icon: CupertinoIcons.videocam_circle_fill,
              color: const Color(0xFF38BDF8),
              title: 'HEVC Video Compressor',
              desc: 'Compress 4K & large videos up to 80% with native Apple hardware encoders.',
              badge: 'UP TO -80%',
            ),
            const Divider(color: Colors.white12, height: 20),
            _toolRow(
              icon: CupertinoIcons.person_2_fill,
              color: const Color(0xFF34D399),
              title: 'Contacts Surgery',
              desc: 'Clean duplicate address cards with automatic local VCF backup export.',
              badge: 'ZERO LOSS',
            ),
            const Divider(color: Colors.white12, height: 20),
            _toolRow(
              icon: CupertinoIcons.lock_shield_fill,
              color: const Color(0xFFFBBF24),
              title: 'Biometric Secret Vault',
              desc: 'Protect confidential photos & media with Face ID / Touch ID hardware encryption.',
              badge: 'FACE ID',
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SLIDE 4: ZERO-KNOWLEDGE PRIVACY & SAFETY
  // ===========================================================================
  Widget _buildSlide4() {
    return _SlideContainer(
      pillText: 'ZERO-KNOWLEDGE PRIVACY · 30-DAY SAFETY',
      title: 'Private & 100% Reversible',
      subtitle:
          'Your personal memories never leave your iPhone. Zero cloud uploads, zero tracking, and a safe 30-day recovery window in Apple Photos.',
      visual: Container(
        padding: const EdgeInsets.all(22),
        decoration: _glassCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield Emblem
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E52A8), Color(0xFF0F3E8A)],
                ),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(CupertinoIcons.shield_fill, size: 26, color: Colors.white),
            ),

            const SizedBox(height: 16),

            _privacyBullet(
              icon: CupertinoIcons.gear_alt_fill,
              title: '100% On-Device Neural Engine',
              desc: 'All computer vision and blur detection runs locally on your Apple chip.',
            ),
            const SizedBox(height: 12),
            _privacyBullet(
              icon: CupertinoIcons.lock_shield_fill,
              title: 'Zero Remote Cloud Uploads',
              desc: 'No personal photos, videos, or contacts are ever uploaded or sold.',
            ),
            const SizedBox(height: 12),
            _privacyBullet(
              icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
              title: '30-Day Safe Recovery Window',
              desc: 'Removed items rest safely in Apple Photos "Recently Deleted" album.',
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER STYLING WIDGETS
  // ===========================================================================
  BoxDecoration _glassCardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _symptomRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String stat,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Lux.sans(12.5, c: Colors.white, w: FontWeight.w600),
              ),
              Text(
                desc,
                style: Lux.sans(10, c: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            stat,
            style: Lux.sans(10.5, c: const Color(0xFFE2E8F0), w: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _toolRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required String badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Lux.sans(13, c: Colors.white, w: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(badge, style: Lux.sans(8.5, c: color, w: FontWeight.w700, ls: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(desc, style: Lux.sans(11, c: const Color(0xFF94A3B8)).copyWith(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _privacyBullet({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Lux.sans(12.5, c: Colors.white, w: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: Lux.sans(10.5, c: const Color(0xFF94A3B8)).copyWith(height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlideContainer extends StatelessWidget {
  const _SlideContainer({
    required this.pillText,
    required this.title,
    required this.subtitle,
    required this.visual,
  });

  final String pillText;
  final String title;
  final String subtitle;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 6),

          // Pill Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: Text(
              pillText,
              style: Lux.sans(9.5, c: const Color(0xFF38BDF8), w: FontWeight.w700, ls: 1.5),
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),

          const SizedBox(height: 8),

          // Luxury Serif Headline
          Text(
            title,
            textAlign: TextAlign.center,
            style: Lux.serif(26, c: Colors.white, w: FontWeight.w700),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut),

          const SizedBox(height: 6),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Lux.sans(12, c: const Color(0xFFCBD5E1)).copyWith(height: 1.4),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
          ),

          const SizedBox(height: 14),

          // Visual demonstration card with responsive auto-scaling
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 350,
                  child: visual,
                ),
              )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1), curve: Curves.easeOutBack),
            ),
          ),
        ],
      ),
    );
  }
}
