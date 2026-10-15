import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_manager/photo_manager.dart';

import 'app_state.dart';
import 'contacts_screen.dart';
import 'prescription_card.dart';
import 'review_screen.dart';
import 'scanner.dart';
import 'settings.dart';
import 'sparkles.dart';
import 'theme.dart';
import 'vault_screen.dart';
import 'video_compressor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _open(BuildContext context, String title, String subtitle, List<CleanGroup> groups,
      {required bool preselect}) async {
    final s = AppState.i;
    final deleted = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            ReviewScreen(title: title, subtitle: subtitle, groups: groups, sizes: s.result!.sizes, preselect: preselect),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
    if (deleted == true) s.scan();
  }

  void _smartClean(BuildContext context, ScanResult r) {
    final groups = <CleanGroup>[
      ...r.similar,
      ...r.screenshots,
      ...r.blurry,
    ];
    final seen = <String>{};
    final merged = <CleanGroup>[];
    for (final g in groups) {
      final assets = g.assets.where((a) => seen.add(a.id) || a.id == g.best?.id).toList();
      if (assets.isNotEmpty) merged.add(CleanGroup(assets, best: g.best));
    }
    if (merged.isEmpty) {
      Hap.light();
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
                  'Your storage is in pristine condition! No items need cleaning.',
                  style: Lux.sans(12, c: Lux.text, w: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    _open(context, 'Smart Clean', 'Best shots kept · review before removing', merged, preselect: true);
  }

  static String _phase(double p) {
    if (p < .1) return 'MEASURING VIDEOS';
    if (p < .55) return 'SWEEPING SIMILAR SHOTS';
    if (p < .9) return 'DUSTING OFF BLURRY PHOTOS';
    return 'POLISHING';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppState.i,
        builder: (context, _) {
          final s = AppState.i;
          final r = s.result;
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.2, colors: [Color(0xFFDDE9FF), Lux.bg]),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Lux.blue.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Lux.blue.withValues(alpha: .22)),
                        ),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          color: Lux.blue,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Doctor AI: Storage Cleaner',
                          style: Lux.sans(13, c: Lux.blue, w: FontWeight.w700, ls: 1.2),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 6),
                  Text('Your library,\nelegantly curated.',
                          style: Lux.serif(38, w: FontWeight.w600).copyWith(height: 1.05))
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: .1),
                  const SizedBox(height: 32),
                  Center(
                    child: _Ring(
                      progress: s.scanning ? s.progress : (r == null ? 0 : 1),
                      label: s.scanning ? '${(s.progress * 100).round()}%' : r != null ? formatBytes(r.reclaimable) : '—',
                      caption: s.scanning ? _phase(s.progress) : r != null ? 'READY TO RECLAIM' : 'NOT YET SCANNED',
                      scanning: s.scanning,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (s.denied)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(children: [
                        Text('Photo access is required to find clutter.',
                            textAlign: TextAlign.center, style: Lux.sans(13, c: Lux.muted)),
                        TextButton(
                          onPressed: PhotoManager.openSetting,
                          child: Text('Open Settings', style: Lux.sans(13, c: Lux.blue, w: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  if (r == null || s.scanning)
                    BrandButton(label: s.scanning ? 'ANALYSING…' : 'BEGIN SMART SCAN', onTap: s.scanning ? null : s.scan)
                  else ...[
                    DoctorPrescriptionCard(
                      scanResult: r,
                      onSmartClean: () => _smartClean(context, r),
                      onOpenCategory: (cat) {
                        void notifyEmpty(String label) {
                          Hap.light();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Lux.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Lux.blue.withValues(alpha: .3)),
                              ),
                              content: Row(
                                children: [
                                  const Icon(CupertinoIcons.checkmark_circle_fill, color: Lux.blue, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No $label detected in your library.',
                                      style: Lux.sans(12, c: Lux.text, w: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }

                        if (cat == 'similar') {
                          if (r.similar.isNotEmpty) {
                            _open(context, 'Similar Photos', 'Best shot kept automatically', r.similar, preselect: true);
                          } else {
                            notifyEmpty('similar photos');
                          }
                        } else if (cat == 'screenshots') {
                          if (r.screenshots.isNotEmpty) {
                            _open(context, 'Screenshots', 'Select what to remove', r.screenshots, preselect: false);
                          } else {
                            notifyEmpty('screenshots');
                          }
                        } else if (cat == 'blurry') {
                          if (r.blurry.isNotEmpty) {
                            _open(context, 'Blurry Photos', 'Select what to remove', r.blurry, preselect: false);
                          } else {
                            notifyEmpty('blurry photos');
                          }
                        } else if (cat == 'videos') {
                          if (r.largeVideos.isNotEmpty) {
                            _open(context, 'Large Videos', 'Largest first', r.largeVideos, preselect: false);
                          } else {
                            notifyEmpty('large videos');
                          }
                        } else {
                          _smartClean(context, r);
                        }
                      },
                    ),
                    if (r.smartCleanBytes > 0) ...[
                      BrandButton(
                          label: 'SMART CLEAN · ${formatBytes(r.smartCleanBytes)}',
                          onTap: () => _smartClean(context, r)),
                      const SizedBox(height: 24),
                    ],
                    const SectionLabel('Media Cleaners'),
                    _CategoryCard(
                      icon: CupertinoIcons.square_on_square,
                      title: 'Similar Photos',
                      detail: '${r.similar.length} groups · best shot kept',
                      size: r.bytesOf(r.similarRemovable),
                      onTap: r.similar.isEmpty
                          ? null
                          : () => _open(context, 'Similar Photos', 'Best shot kept automatically', r.similar, preselect: true),
                    ),
                    _CategoryCard(
                      icon: CupertinoIcons.eye_slash,
                      title: 'Blurry Photos',
                      detail: '${r.count(r.blurry)} out-of-focus shots',
                      size: r.bytesOf(r.flat(r.blurry)),
                      onTap: r.blurry.isEmpty ? null : () => _open(context, 'Blurry Photos', 'Select what to remove', r.blurry, preselect: false),
                    ),
                    _CategoryCard(
                      icon: CupertinoIcons.device_phone_portrait,
                      title: 'Screenshots',
                      detail: '${r.count(r.screenshots)} items',
                      size: r.bytesOf(r.flat(r.screenshots)),
                      onTap: r.screenshots.isEmpty ? null : () => _open(context, 'Screenshots', 'Select what to remove', r.screenshots, preselect: false),
                    ),
                    _CategoryCard(
                      icon: CupertinoIcons.circle_grid_hex,
                      title: 'Live Photos',
                      detail: '${r.count(r.livePhotos)} items',
                      size: r.bytesOf(r.flat(r.livePhotos)),
                      onTap: r.livePhotos.isEmpty ? null : () => _open(context, 'Live Photos', 'Select what to remove', r.livePhotos, preselect: false),
                    ),
                    _CategoryCard(
                      icon: CupertinoIcons.videocam,
                      title: 'Large Videos',
                      detail: '${r.count(r.largeVideos)} videos · largest first',
                      size: r.bytesOf(r.flat(r.largeVideos)),
                      onTap: r.largeVideos.isEmpty ? null : () => _open(context, 'Large Videos', 'Largest first', r.largeVideos, preselect: false),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const SectionLabel('Cleaning Suite & Tools'),
                  _toolTile(
                    icon: CupertinoIcons.person_2,
                    title: 'Contacts Cleaner',
                    subtitle: 'Merge duplicate address records & prune empty entries',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
                  ),
                  _toolTile(
                    icon: CupertinoIcons.videocam_circle,
                    title: 'Video Compressor',
                    subtitle: 'Reclaim gigabytes with hardware HEVC optimization',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoCompressorScreen())),
                  ),
                  _toolTile(
                    icon: CupertinoIcons.lock_shield,
                    title: 'Confidential Vault',
                    subtitle: 'Hide personal photos behind Face ID biometrics',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen())),
                  ),
                  if (r != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: s.scan,
                        child: Text('Rescan Library', style: Lux.sans(13, c: Lux.blue, w: FontWeight.w500, ls: 1.5)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );

  Widget _toolTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: () {
          Hap.light();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Lux.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Lux.blue.withValues(alpha: .2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Lux.surface2,
                  border: Border.all(color: Lux.blue.withValues(alpha: .3)),
                ),
                child: Icon(icon, color: Lux.blue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Lux.sans(14, w: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Lux.sans(11, c: Lux.muted)),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 16, color: Lux.muted),
            ],
          ),
        ),
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.label, required this.caption, this.scanning = false});
  final double progress;
  final String label, caption;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox(
      width: 230,
      height: 230,
      child: Stack(alignment: Alignment.center, children: [
        if (scanning) const Positioned.fill(child: SparkleField(count: 12, seed: 11)),
        SizedBox.expand(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: 400.ms,
            builder: (_, v, _) => CustomPaint(painter: RingPainter(v)),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: Lux.serif(46, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(caption, textAlign: TextAlign.center, style: Lux.sans(10, c: scanning ? Lux.blue : Lux.muted, ls: 2.5, w: FontWeight.w500)),
        ]),
      ]),
    );
    final entered = ring.animate().fadeIn(delay: 250.ms).scale(begin: const Offset(.95, .95));
    if (!scanning) return entered;
    return entered
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 900.ms, curve: Curves.easeInOut);
  }
}

class RingPainter extends CustomPainter {
  RingPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(8);
    canvas.drawArc(r, 0, 6.2832, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Lux.surface2);
    canvas.drawArc(
        r, -1.5708, 6.2832 * value, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(startAngle: -1.5708, endAngle: 4.7124, colors: [Lux.blueDark, Lux.blueLight, Lux.blue]).createShader(rect));
  }

  @override
  bool shouldRepaint(RingPainter o) => o.value != value;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, required this.detail, required this.size, this.onTap});
  final IconData icon;
  final String title, detail;
  final int size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .45 : 1,
        child: LuxCard(
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Lux.blue.withValues(alpha: .5))),
              child: Icon(icon, color: Lux.blue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Lux.serif(24, w: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail, style: Lux.sans(12, c: Lux.muted)),
              ]),
            ),
            Text(formatBytes(size), style: Lux.sans(13, c: Lux.blue, w: FontWeight.w600)),
          ]),
        ),
      ),
    ).animate().fadeIn().slideY(begin: .15);
  }
}
