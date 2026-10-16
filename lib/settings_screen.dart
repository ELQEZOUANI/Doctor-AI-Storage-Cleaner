import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'contacts_screen.dart';
import 'onboarding_screen.dart';
import 'settings.dart';
import 'theme.dart';
import 'vault_screen.dart';
import 'video_compressor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _privacyPolicyText = '''DOCTOR AI: STORAGE CLEANER PRIVACY POLICY
Effective Date: October 2026

1. PRIVACY-FIRST COMMITMENT
Doctor AI: Storage Cleaner is engineered from the ground up with a strict Privacy-First architecture. We believe your personal photos, videos, contacts, and biometric credentials belong solely to you.

2. 100% ON-DEVICE PROCESSING
All computational intelligence — including similar photo detection, blur scoring, screenshot filtering, video compression, and duplicate contact identification — is processed entirely on your local iOS hardware using Apple Neural Engine and local frameworks.

3. ZERO CLOUD UPLOADS
We do not operate remote processing servers. Your media, contacts, and files are NEVER uploaded, transmitted, sold, or shared with third parties.

4. PERMISSIONS & DATA CONTROL
• Photos Library: Used only to scan and organize media in accordance with your explicit permission. Deleted photos are safely placed in iOS "Recently Deleted" for 30 days.
• Contacts: Used only when accessing Contacts Cleaner to detect duplicates. Backups are exported locally by you.
• Face ID / Biometrics: Handled exclusively by Apple LocalAuthentication framework; Doctor AI never stores or accesses your biometric keys.

5. ZERO ANALYTICS OR TRACKING
We do not employ ad trackers, third-party analytics SDKs, or invasive fingerprinting.''';

  static const String _termsOfServiceText = '''DOCTOR AI: STORAGE CLEANER TERMS OF SERVICE & LEGACY POLICY
Effective Date: October 2026

1. ACCEPTANCE OF TERMS
By downloading and using Doctor AI: Storage Cleaner, you agree to these Terms and Conditions. Doctor AI: Storage Cleaner is provided for storage optimization and media management on iOS devices.

2. USER CONTROL & DELETION SAFETY
Doctor AI provides intelligent recommendations for space reclamation. You maintain ultimate control over which files and contacts are pruned. When items are removed, they follow native iOS deletion rules (remaining in "Recently Deleted" for up to 30 days unless permanently purged).

3. HARDWARE ACCELERATION & COMPRESSION
Video compression optimizes file sizes using native iOS hardware codecs. Always ensure you are satisfied with compressed results before removing original files.

4. INTELLECTUAL PROPERTY
Doctor AI: Storage Cleaner, including its luxury interface, branding, and proprietary algorithms, is protected by copyright and intellectual property laws.

5. DISCLAIMER OF WARRANTIES
Doctor AI: Storage Cleaner is provided "as is" with the highest standards of reliability and safety.''';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppSettings.i,
        builder: (context, _) {
          final s = AppSettings.i;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                Text('PREFERENCES', style: Lux.sans(12, c: Lux.blue, w: FontWeight.w600, ls: 6)),
                const SizedBox(height: 6),
                Text('Settings', style: Lux.serif(36, w: FontWeight.w600)),
                const SizedBox(height: 20),

                // App Hero Card: Icon + Description
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Lux.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Lux.blue.withValues(alpha: .2)),
                    boxShadow: [
                      BoxShadow(
                        color: Lux.blue.withValues(alpha: .06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Lux.blue.withValues(alpha: .22),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(color: Lux.blue.withValues(alpha: .3), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset('assets/icon/icon_1024.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Doctor AI: Storage Cleaner', style: Lux.serif(22, w: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Lux.surface2,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Lux.blue.withValues(alpha: .2)),
                                  ),
                                  child: Text('Version 1.0.0 · AI Edition',
                                      style: Lux.sans(10, c: Lux.blue, w: FontWeight.w700, ls: 0.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your intelligent on-device iOS storage doctor. Diagnose library bloat, purge duplicate contacts, and optimize storage with total privacy.',
                        style: Lux.sans(13, c: Lux.muted).copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const SectionLabel('Share & Support'),
                LuxCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    children: [
                      _Row(
                        icon: CupertinoIcons.share,
                        title: 'Share Doctor AI',
                        subtitle: 'Recommend Doctor AI to friends & family',
                        onTap: () => _shareApp(),
                      ),
                      const Divider(color: Lux.surface2),
                      _Row(
                        icon: CupertinoIcons.star,
                        title: 'Rate App',
                        subtitle: 'Support Doctor AI with a review on the App Store',
                        onTap: () => _rateApp(context),
                      ),
                      const Divider(color: Lux.surface2),
                      _Row(
                        icon: CupertinoIcons.mail,
                        title: 'Contact Us',
                        subtitle: 'Concierge support: zaykarda@yahoo.com',
                        onTap: () => _contactUs(context),
                      ),
                    ],
                  ),
                ),

                const SectionLabel('Policy & Legacy'),
                LuxCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    children: [
                      _Row(
                        icon: CupertinoIcons.shield_lefthalf_fill,
                        title: 'Privacy Policy',
                        subtitle: 'Official Zero-Knowledge Privacy Policy',
                        onTap: () => openPolicyUrl(context),
                      ),
                      const Divider(color: Lux.surface2),
                      _Row(
                        icon: CupertinoIcons.doc_text,
                        title: 'Terms & Legacy Policy',
                        subtitle: 'Official End User Terms & Legacy Agreement',
                        onTap: () => openPolicyUrl(context),
                      ),
                    ],
                  ),
                ),

                const SectionLabel('Tools & Features'),
                LuxCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    children: [
                      _Row(
                        icon: CupertinoIcons.person_2,
                        title: 'Contacts Cleaner',
                        subtitle: 'Merge duplicate address records',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
                      ),
                      const Divider(color: Lux.surface2),
                      _Row(
                        icon: CupertinoIcons.videocam_circle,
                        title: 'Video Compressor',
                        subtitle: 'Reclaim storage with HEVC optimization',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoCompressorScreen())),
                      ),
                      const Divider(color: Lux.surface2),
                      _Row(
                        icon: CupertinoIcons.lock_shield,
                        title: 'Confidential Vault',
                        subtitle: 'Biometric Face ID hidden photo safe',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen())),
                      ),
                      const Divider(color: Lux.surface2),
                      _Row(
                        icon: CupertinoIcons.sparkles,
                        title: 'Clinical App Tour',
                        subtitle: 'Replay how Doctor AI neural vision works',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen())),
                      ),
                    ],
                  ),
                ),

                const SectionLabel('Scan depth'),
                LuxCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Recent photos to analyse', style: Lux.sans(14)),
                    const SizedBox(height: 4),
                    Text('Higher is more thorough but slower.', style: Lux.sans(12, c: Lux.muted)),
                    const SizedBox(height: 14),
                    _Chips<int>(values: const [1000, 2000, 5000], selected: s.maxPhotos, label: (v) => '$v', onSelect: s.setMaxPhotos),
                  ]),
                ),

                LuxCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Large video threshold', style: Lux.sans(14)),
                    const SizedBox(height: 4),
                    Text('Videos above this size are flagged.', style: Lux.sans(12, c: Lux.muted)),
                    const SizedBox(height: 14),
                    _Chips<int>(values: const [25, 50, 100, 200], selected: s.largeVideoMb, label: (v) => '$v MB', onSelect: s.setLargeVideoMb),
                  ]),
                ),

                const SectionLabel('Experience'),
                LuxCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: Lux.blue,
                    title: Text('Haptic feedback', style: Lux.sans(14)),
                    value: s.haptics,
                    onChanged: s.setHaptics,
                  ),
                ),

                const SectionLabel('Privacy & data'),
                LuxCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(children: [
                    const _Row(
                      icon: Icons.lock_outline,
                      title: 'On-device only',
                      subtitle: 'All analysis happens on your iPhone. No uploads, no accounts.',
                    ),
                  ]),
                ),

                Center(
                  child: TextButton(
                    onPressed: () => AppState.i.scan(),
                    child: Text('Run a fresh scan', style: Lux.sans(13, c: Lux.blue, w: FontWeight.w500, ls: 1.5)),
                  ),
                ),
              ],
            ),
          );
        },
      );

  static const String appId = '6822348721';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6822348721';
  static const String rateAppUrl = 'https://apps.apple.com/app/id6822348721?action=write-review';

  static Future<void> _shareApp() async {
    Hap.light();
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Reclaim gigabytes with Doctor AI: Storage Cleaner – intelligent on-device cleaner for iOS. Private, fast, and effortless: $appStoreUrl',
        subject: 'Doctor AI: Storage Cleaner for iOS',
      ),
    );
  }

  static Future<void> _rateApp(BuildContext context) async {
    Hap.light();
    final uri = Uri.parse(rateAppUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Lux.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(CupertinoIcons.star_fill, color: Lux.blue, size: 22),
              const SizedBox(width: 8),
              Text('Rate Doctor AI', style: Lux.serif(22, w: FontWeight.w600)),
            ],
          ),
          content: Text(
            'Enjoying Doctor AI: Storage Cleaner? Your review on the App Store helps support continuous updates and private storage diagnostics.',
            style: Lux.sans(13, c: Lux.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Later', style: Lux.sans(13, c: Lux.muted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final rateUri = Uri.parse(rateAppUrl);
                if (await canLaunchUrl(rateUri)) {
                  await launchUrl(rateUri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for supporting Doctor AI!')),
                    );
                  }
                }
              },
              child: Text('Rate 5 Stars ⭐', style: Lux.sans(13, c: Lux.blue, w: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
  }

  static const String contactEmail = 'zaykarda@yahoo.com';

  static Future<void> _contactUs(BuildContext context) async {
    Hap.light();
    final uri = Uri.parse('mailto:$contactEmail?subject=Doctor%20AI%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Lux.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text('Concierge Support', style: Lux.serif(22, w: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We are here to assist with any questions, feedback, or feature requests.',
                style: Lux.sans(13, c: Lux.muted),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Lux.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Lux.blue.withValues(alpha: .2)),
                ),
                child: SelectableText(
                  contactEmail,
                  style: Lux.sans(14, c: Lux.blue, w: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: contactEmail));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support email copied to clipboard!')),
                );
              },
              child: Text('Copy Email', style: Lux.sans(13, c: Lux.blue, w: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: Lux.sans(13, c: Lux.muted)),
            ),
          ],
        ),
      );
    }
  }

  static const String policyUrl = 'https://doctoraistoragecleaner.blogspot.com/2026/10/blog-post.html?m=0';

  static Future<void> openPolicyUrl(BuildContext context) async {
    Hap.light();
    final uri = Uri.parse(policyUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open policy link')),
        );
      }
    }
  }

  static void _showPolicySheet(BuildContext context, {required String title, required String content}) {
    Hap.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Lux.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Lux.surface2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Lux.serif(24, w: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Lux.muted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Lux.surface2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    content,
                    style: Lux.sans(14, c: Lux.text).copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Lux.blue,
                      side: const BorderSide(color: Lux.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 16),
                    label: Text('Open Online Official Policy', style: Lux.sans(13, w: FontWeight.w600, c: Lux.blue)),
                    onPressed: () => openPolicyUrl(context),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chips<T> extends StatelessWidget {
  const _Chips({required this.values, required this.selected, required this.label, required this.onSelect});
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, children: [
        for (final v in values)
          GestureDetector(
            onTap: () {
              Hap.light();
              onSelect(v);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: v == selected ? Lux.brandGradient : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: v == selected ? Colors.transparent : Lux.blue.withValues(alpha: .35)),
              ),
              child: Text(label(v), style: Lux.sans(13, c: v == selected ? Colors.white : Lux.text, w: FontWeight.w600)),
            ),
          ),
      ]);
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Lux.surface2,
            shape: BoxShape.circle,
            border: Border.all(color: Lux.blue.withValues(alpha: .2)),
          ),
          child: Icon(icon, color: Lux.blue, size: 18),
        ),
        title: Text(title, style: Lux.sans(14, w: FontWeight.w500)),
        subtitle: Text(subtitle, style: Lux.sans(12, c: Lux.muted)),
        trailing: onTap == null ? null : const Icon(CupertinoIcons.chevron_right, size: 14, color: Lux.muted),
      );
}
