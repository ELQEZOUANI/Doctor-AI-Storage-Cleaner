import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_state.dart';
import 'settings.dart';
import 'settings_screen.dart';
import 'theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 0; // 0: Annual, 1: Lifetime, 2: Monthly

  static const _plans = [
    (title: 'Annual Membership', price: '\$29.99 / year', badge: '3 DAYS FREE TRIAL', perMonth: '\$2.49 / mo'),
    (title: 'Lifetime Concierge', price: '\$49.99 one-time', badge: 'BEST VALUE', perMonth: 'Pay once, own forever'),
    (title: 'Monthly Pass', price: '\$4.99 / month', badge: 'FLEXIBLE', perMonth: 'Cancel anytime'),
  ];

  static const _perks = [
    (icon: CupertinoIcons.sparkles, title: 'Unlimited Deep AI Scan', subtitle: 'Analyze 50,000+ photos with on-device intelligence'),
    (icon: CupertinoIcons.videocam_circle, title: '4K Video Compressor', subtitle: 'Reclaim up to 80% storage preserving high visual clarity'),
    (icon: CupertinoIcons.lock_shield, title: 'Biometric Face ID Vault', subtitle: 'Hide sensitive photos & videos behind encrypted security'),
    (icon: CupertinoIcons.person_2, title: 'Contacts Duplicate Merge', subtitle: 'Eliminate duplicate address entries with 1 tap'),
    (icon: CupertinoIcons.app_badge, title: 'Luxury App Icons', subtitle: 'Exclusive handcrafted blue & white icons'),
  ];

  void _subscribe() {
    Hap.heavy();
    AppSettings.i.setVip(true);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Lux.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Lux.blue, width: 1.5),
        ),
        title: Center(
          child: Column(
            children: [
              const Icon(CupertinoIcons.star_circle_fill, color: Lux.blue, size: 48),
              const SizedBox(height: 12),
              Text('Welcome to Doctor AI VIP', style: Lux.serif(26, w: FontWeight.w700)),
            ],
          ),
        ),
        content: Text(
          'Your VIP status is active. All premium features, unlimited deep scan, biometric vault, and video compressor are unlocked.',
          textAlign: TextAlign.center,
          style: Lux.sans(13, c: Lux.muted),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // paywall
              },
              child: Text('BEGIN EXPERIENCE', style: Lux.sans(14, c: Lux.blue, w: FontWeight.w800, ls: 2)),
            ),
          ),
        ],
      ),
    );
  }

  void _restore() {
    Hap.light();
    AppSettings.i.setVip(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Lux.surface2,
        content: Text('Purchases restored successfully. VIP active.', style: Lux.sans(13, c: Lux.blue)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Lux.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.65),
            radius: 1.3,
            colors: [Color(0xFFDDE9FF), Lux.bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Lux.muted),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      onPressed: _restore,
                      child: Text('RESTORE', style: Lux.sans(11, c: Lux.muted, w: FontWeight.w600, ls: 1.5)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  children: [
                    // Brand crest
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Lux.blue, width: 2),
                          boxShadow: [
                            BoxShadow(color: Lux.blue.withValues(alpha: .3), blurRadius: 28, spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(CupertinoIcons.shield_fill, color: Lux.blue, size: 38),
                      ),
                    ).animate().fadeIn().scale(),
                    const SizedBox(height: 16),
                    Text(
                      'DOCTOR AI VIP',
                      textAlign: TextAlign.center,
                      style: Lux.sans(13, c: Lux.blue, w: FontWeight.w700, ls: 5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The Sovereign Standard\nof Clean Storage.',
                      textAlign: TextAlign.center,
                      style: Lux.serif(34, w: FontWeight.w600).copyWith(height: 1.1),
                    ),
                    const SizedBox(height: 28),
                    // Perks
                    for (final p in _perks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Lux.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: Lux.blue.withValues(alpha: .3)),
                              ),
                              child: Icon(p.icon, color: Lux.blue, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.title, style: Lux.sans(13, w: FontWeight.w600)),
                                  Text(p.subtitle, style: Lux.sans(11, c: Lux.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Pricing Options
                    for (var i = 0; i < _plans.length; i++)
                      _planCard(
                        index: i,
                        plan: _plans[i],
                        isSelected: _selectedPlan == i,
                        onTap: () {
                          Hap.light();
                          setState(() => _selectedPlan = i);
                        },
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Recurring billing. Cancel anytime in Apple App Store subscriptions.',
                      textAlign: TextAlign.center,
                      style: Lux.sans(11, c: Lux.muted),
                    ),
                  ],
                ),
              ),
              // CTA Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: BrandButton(
                  label: _selectedPlan == 0 ? 'START 3-DAY FREE TRIAL' : 'UNLOCK DOCTOR AI VIP',
                  onTap: _subscribe,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => SettingsScreen.openPolicyUrl(context),
                      child: Text('Terms & Legacy', style: Lux.sans(11, c: Lux.muted).copyWith(decoration: TextDecoration.underline)),
                    ),
                    Text('  •  ', style: Lux.sans(11, c: Lux.muted)),
                    GestureDetector(
                      onTap: () => SettingsScreen.openPolicyUrl(context),
                      child: Text('Privacy Policy', style: Lux.sans(11, c: Lux.muted).copyWith(decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required int index,
    required ({String title, String price, String badge, String perMonth}) plan,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Lux.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Lux.blue : Lux.blue.withValues(alpha: .2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Lux.blue.withValues(alpha: .2), blurRadius: 18, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Lux.blue : Colors.transparent,
                border: Border.all(color: isSelected ? Lux.blue : Lux.muted, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Lux.bg) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.title, style: Lux.sans(14, w: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Lux.blueDark.withValues(alpha: .4) : Lux.surface2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Lux.blue.withValues(alpha: .4)),
                        ),
                        child: Text(plan.badge, style: Lux.sans(9, c: Lux.blue, w: FontWeight.w700, ls: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(plan.perMonth, style: Lux.sans(12, c: Lux.muted)),
                ],
              ),
            ),
            Text(plan.price.split(' ').first, style: Lux.serif(20, w: FontWeight.w700, c: Lux.blue)),
          ],
        ),
      ),
    );
  }
}
