import 'dart:math' as math;

import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_state.dart';
import 'scanner.dart';
import 'settings.dart';
import 'theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double? total, free; // bytes

  @override
  void initState() {
    super.initState();
    _disk();
  }

  Future<void> _disk() async {
    try {
      final d = DiskSpacePlus();
      final t = await d.getTotalDiskSpace; // MB
      final f = await d.getFreeDiskSpace; // MB
      if (mounted && t != null && f != null) {
        setState(() {
          total = t * 1024 * 1024;
          free = f * 1024 * 1024;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([AppState.i, AppSettings.i]),
        builder: (context, _) {
          final r = AppState.i.result;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                Text('INSIGHTS', style: Lux.sans(12, c: Lux.blue, w: FontWeight.w600, ls: 6)),
                const SizedBox(height: 6),
                Text('Storage analytics', style: Lux.serif(36, w: FontWeight.w600)),
                const SizedBox(height: 24),
                _deviceCard(),
                if (r == null) _emptyCard() else ..._library(r),
                _lifetimeCard(),
              ].animate(interval: 60.ms).fadeIn().slideY(begin: .08),
            ),
          );
        },
      );

  Widget _deviceCard() {
    final t = total, f = free;
    final used = (t != null && f != null) ? t - f : null;
    final frac = (used != null && t! > 0) ? used / t : 0.0;
    return LuxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DEVICE STORAGE', style: Lux.sans(11, c: Lux.muted, ls: 2.5, w: FontWeight.w500)),
        const SizedBox(height: 10),
        if (used == null)
          Text('Unavailable', style: Lux.serif(28))
        else ...[
          RichText(
            text: TextSpan(children: [
              TextSpan(text: formatBytes(used.round()), style: Lux.serif(34, w: FontWeight.w600)),
              TextSpan(text: '  of ${formatBytes(t!.round())} used', style: Lux.sans(13, c: Lux.muted)),
            ]),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Container(height: 10, color: Lux.surface2),
              TweenAnimationBuilder<double>(
                tween: Tween(end: frac),
                duration: 900.ms,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FractionallySizedBox(
                  widthFactor: v.clamp(0, 1),
                  child: Container(height: 10, decoration: const BoxDecoration(gradient: Lux.brandGradient)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text('${formatBytes(f!.round())} free · ${(frac * 100).round()}% used', style: Lux.sans(12, c: Lux.muted)),
        ],
      ]),
    );
  }

  Widget _emptyCard() => LuxCard(
        child: Column(children: [
          Text('Scan to reveal your library', style: Lux.serif(24, w: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Photo and video breakdown, monthly growth and your largest files.',
              textAlign: TextAlign.center, style: Lux.sans(12, c: Lux.muted)),
          const SizedBox(height: 18),
          BrandButton(label: AppState.i.scanning ? 'ANALYSING…' : 'SCAN NOW', onTap: AppState.i.scanning ? null : AppState.i.scan),
        ]),
      );

  List<Widget> _library(ScanResult r) {
    final st = r.stats;
    final slices = <_Slice>[
      _Slice('Photos', st.photoBytes, Lux.blue, st.photoCount),
      _Slice('Videos', st.videoBytes, Lux.blueDark, st.videoCount),
      _Slice('Screenshots', st.screenshotBytes, Lux.blueLight, st.screenshotCount),
      _Slice('Live Photos', st.liveBytes, const Color(0xFF8BA6D8), st.liveCount),
    ];
    return [
      LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LIBRARY BREAKDOWN', style: Lux.sans(11, c: Lux.muted, ls: 2.5, w: FontWeight.w500)),
          const SizedBox(height: 20),
          Row(children: [
            SizedBox(
              width: 130,
              height: 130,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CustomPaint(painter: _DonutPainter(slices))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatBytes(st.totalBytes), style: Lux.serif(20, w: FontWeight.w600)),
                  Text('est.', style: Lux.sans(10, c: Lux.muted)),
                ]),
              ]),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(children: [
                for (final s in slices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Container(width: 9, height: 9, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${s.label} · ${s.count}', style: Lux.sans(12))),
                      Text(formatBytes(s.bytes), style: Lux.sans(12, c: Lux.blue, w: FontWeight.w600)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ]),
      ),
      LuxCard(child: _MonthChart(st.monthBytes)),
      LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('POTENTIAL SAVINGS', style: Lux.sans(11, c: Lux.muted, ls: 2.5, w: FontWeight.w500)),
          const SizedBox(height: 14),
          _saving('Similar photos', r.bytesOf(r.similarRemovable), r.reclaimable),
          _saving('Blurry photos', r.bytesOf(r.flat(r.blurry)), r.reclaimable),
          _saving('Screenshots', r.bytesOf(r.flat(r.screenshots)), r.reclaimable),
          _saving('Live Photos', r.bytesOf(r.flat(r.livePhotos)), r.reclaimable),
          _saving('Large videos', r.bytesOf(r.flat(r.largeVideos)), r.reclaimable),
        ]),
      ),
      if (st.topVideos.isNotEmpty)
        LuxCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LARGEST VIDEOS', style: Lux.sans(11, c: Lux.muted, ls: 2.5, w: FontWeight.w500)),
            const SizedBox(height: 14),
            for (final v in st.topVideos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 52, height: 52, child: AssetThumb(v, size: 120))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('${v.duration ~/ 60}:${(v.duration % 60).toString().padLeft(2, '0')} · ${v.createDateTime.year}-${v.createDateTime.month.toString().padLeft(2, '0')}',
                        style: Lux.sans(13)),
                  ),
                  Text(formatBytes(r.sizes[v.id] ?? 0), style: Lux.sans(13, c: Lux.blue, w: FontWeight.w600)),
                ]),
              ),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          'Photo sizes are estimated from resolution; scan covers your ${AppSettings.i.maxPhotos} most recent photos and is extrapolated.',
          style: Lux.sans(11, c: Lux.muted),
        ),
      ),
    ];
  }

  Widget _saving(String label, int bytes, int total) {
    final f = total == 0 ? 0.0 : bytes / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(label, style: Lux.sans(13))),
          Text(formatBytes(bytes), style: Lux.sans(13, c: Lux.blue, w: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: f, minHeight: 5, backgroundColor: Lux.surface2, color: Lux.blue),
        ),
      ]),
    );
  }

  Widget _lifetimeCard() {
    final s = AppSettings.i;
    return LuxCard(
      child: Row(children: [
        Expanded(child: _stat(formatBytes(s.freedBytes), 'FREED SO FAR')),
        Container(width: 1, height: 44, color: Lux.blue.withValues(alpha: .25)),
        Expanded(child: _stat('${s.removedCount}', 'ITEMS REMOVED')),
      ]),
    );
  }

  Widget _stat(String v, String l) => Column(children: [
        Text(v, style: Lux.serif(30, w: FontWeight.w600, c: Lux.blue)),
        const SizedBox(height: 2),
        Text(l, style: Lux.sans(10, c: Lux.muted, ls: 2.5, w: FontWeight.w500)),
      ]);
}

class _Slice {
  _Slice(this.label, this.bytes, this.color, this.count);
  final String label;
  final int bytes, count;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices);
  final List<_Slice> slices;
  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(8);
    final total = slices.fold<int>(0, (s, e) => s + e.bytes);
    final bg = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..color = Lux.surface2;
    canvas.drawArc(r, 0, math.pi * 2, false, bg);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.bytes / total * math.pi * 2;
      if (sweep <= 0) continue;
      canvas.drawArc(r, start, math.max(sweep - .04, .01), false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.butt..color = s.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => true;
}

class _MonthChart extends StatelessWidget {
  const _MonthChart(this.data);
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - 11 + i));
    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
    final values = [for (final m in months) data[key(m)] ?? 0];
    final maxV = values.fold<int>(1, math.max);
    const names = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GROWTH · LAST 12 MONTHS', style: Lux.sans(11, c: Lux.muted, ls: 2.5, w: FontWeight.w500)),
      const SizedBox(height: 18),
      SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 12; i++)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: values[i] / maxV),
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      height: 100 * v + 2,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: values[i] == maxV && maxV > 1
                            ? Lux.brandGradient
                            : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Lux.blue.withValues(alpha: .7), Lux.blueDark.withValues(alpha: .4)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(names[months[i].month - 1], style: Lux.sans(10, c: Lux.muted)),
                ]),
              ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text('Peak month: ${formatBytes(maxV)}', style: Lux.sans(12, c: Lux.muted)),
    ]);
  }
}
