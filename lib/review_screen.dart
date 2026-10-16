import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'ad_service.dart';
import 'app_state.dart';
import 'clean_success_screen.dart';
import 'gemini_service.dart';
import 'media_viewer.dart';
import 'scanner.dart';
import 'settings.dart';
import 'theme.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.groups,
    required this.sizes,
    required this.preselect,
  });
  final String title, subtitle;
  final List<CleanGroup> groups;
  final Map<String, int> sizes;
  final bool preselect;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final Set<String> selected;
  final Set<int> _loadingAiIndices = {};

  @override
  void initState() {
    super.initState();
    selected = widget.preselect
        ? {for (final g in widget.groups) for (final a in g.assets) if (a.id != g.best?.id) a.id}
        : <String>{};
  }

  int get selectedBytes => widget.groups
      .expand((g) => g.assets)
      .where((a) => selected.contains(a.id))
      .fold(0, (s, a) => s + (widget.sizes[a.id] ?? 0));

  Future<void> _runAiBestShot(int index, CleanGroup g) async {
    if (g.assets.length < 2) return;
    setState(() => _loadingAiIndices.add(index));
    Hap.medium();

    try {
      final res = await GeminiService.i.analyzeBestShot(g.assets);
      if (!mounted) return;
      setState(() {
        g.best = g.assets[res.bestIndex];
        g.aiReason = res.reason;
        for (final a in g.assets) {
          if (a.id == g.best?.id) {
            selected.remove(a.id);
          } else {
            selected.add(a.id);
          }
        }
      });
      Hap.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Lux.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Lux.blue.withValues(alpha: .3)),
            ),
            content: Row(
              children: [
                const Icon(CupertinoIcons.sparkles, color: Lux.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Doctor AI Vision Picked: ${res.reason}',
                    style: Lux.sans(12, c: Lux.text, w: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error running AI Best Shot: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingAiIndices.remove(index));
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Lux.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Lux.blue.withValues(alpha: .3))),
        title: Text('Remove ${selected.length} items?', style: Lux.serif(26, w: FontWeight.w600)),
        content: Text('They move to Recently Deleted for 30 days, so you can still recover them.', style: Lux.sans(13, c: Lux.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: Lux.sans(14, c: Lux.muted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Remove', style: Lux.sans(14, c: Lux.blue, w: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    Hap.heavy();
    final bytes = selectedBytes;
    final removed = await Scanner.delete(selected.toList());
    if (removed.isNotEmpty) {
      final frac = removed.length / selected.length;
      final freed = (bytes * frac).round();
      AppSettings.i.addFreed(freed, removed.length);
      if (!mounted) return;

      // Show Interstitial ad before presenting CleanSuccessScreen
      AdService.i.showInterstitialAdIfAvailable(
        ignoreCooldown: true,
        onDismissed: () async {
          if (!mounted) return;
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => CleanSuccessScreen(freedBytes: freed, count: removed.length),
              transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
          if (mounted) Navigator.pop(context, true);
        },
      );
      return;
    }
    if (mounted && removed.isNotEmpty) Navigator.pop(context, true);
  }

  void _openCompare(CleanGroup g) {
    if (g.assets.length < 2) return;
    Hap.medium();
    final aA = g.best ?? g.assets[0];
    final aB = g.assets.firstWhere((e) => e.id != aA.id, orElse: () => g.assets[1]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareScreen(
          assetA: aA,
          assetB: aB,
          isBestA: aA.id == g.best?.id,
          isBestB: aB.id == g.best?.id,
          isSelectedA: selected.contains(aA.id),
          isSelectedB: selected.contains(aB.id),
          onToggleA: () => setState(() {
            selected.contains(aA.id) ? selected.remove(aA.id) : selected.add(aA.id);
          }),
          onToggleB: () => setState(() {
            selected.contains(aB.id) ? selected.remove(aB.id) : selected.add(aB.id);
          }),
        ),
      ),
    );
  }

  void _openDetail(AssetEntity a, bool isBest) {
    Hap.light();
    if (a.type == AssetType.video) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoViewerScreen(
            asset: a,
            isSelected: selected.contains(a.id),
            onToggleSelected: () => setState(() {
              selected.contains(a.id) ? selected.remove(a.id) : selected.add(a.id);
            }),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoViewerScreen(
            asset: a,
            isBest: isBest,
            isSelected: selected.contains(a.id),
            onToggleSelected: () => setState(() {
              selected.contains(a.id) ? selected.remove(a.id) : selected.add(a.id);
            }),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiGroup = widget.groups.length > 1 || (widget.groups.isNotEmpty && widget.groups.first.best != null);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
            child: Row(children: [
              IconButton(icon: const Icon(CupertinoIcons.chevron_left, color: Lux.blue), onPressed: () => Navigator.pop(context)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: Lux.serif(30, w: FontWeight.w600)),
                  Text(widget.subtitle, style: Lux.sans(12, c: Lux.muted)),
                ]),
              ),
              if (widget.groups.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    final all = widget.groups.expand((g) => g.assets).map((a) => a.id);
                    selected.length >= all.length ? selected.clear() : selected.addAll(all);
                  }),
                  child: Text('All', style: Lux.sans(13, c: Lux.blue, w: FontWeight.w600)),
                ),
            ]),
          ),
          Expanded(
            child: widget.groups.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Lux.surface2,
                              border: Border.all(color: Lux.blue.withValues(alpha: .3)),
                            ),
                            child: const Icon(CupertinoIcons.checkmark_alt, size: 34, color: Lux.blue),
                          ),
                          const SizedBox(height: 18),
                          Text('Library Pristine', style: Lux.serif(22, w: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            'No items need cleaning in this category. Your photo library is operating at peak performance.',
                            textAlign: TextAlign.center,
                            style: Lux.sans(13, c: Lux.muted),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: Lux.brandGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('BACK', style: Lux.sans(12, c: Lux.bg, w: FontWeight.w700, ls: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: widget.groups.length,
                    itemBuilder: (_, i) {
                      final g = widget.groups[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (multiGroup)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('GROUP ${i + 1} · ${g.assets.length} ITEMS',
                                      style: Lux.sans(11, c: Lux.muted, ls: 2, w: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                if (g.assets.length >= 2)
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _loadingAiIndices.contains(i)
                                            ? null
                                            : () => _runAiBestShot(i, g),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: g.aiReason != null ? Lux.brandGradient : null,
                                            color: g.aiReason != null ? null : Lux.surface2,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Lux.blue.withValues(alpha: g.aiReason != null ? 0 : 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (_loadingAiIndices.contains(i))
                                                const SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Lux.blue),
                                                )
                                              else
                                                Icon(CupertinoIcons.sparkles,
                                                    size: 11,
                                                    color: g.aiReason != null ? Lux.bg : Lux.blue),
                                              const SizedBox(width: 5),
                                              Text(
                                                'AI BEST',
                                                style: Lux.sans(10,
                                                    c: g.aiReason != null ? Lux.bg : Lux.blue,
                                                    w: FontWeight.w800,
                                                    ls: 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _openCompare(g),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Lux.surface2,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Lux.blue.withValues(alpha: .4)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(CupertinoIcons.arrow_left_right, size: 12, color: Lux.blue),
                                              const SizedBox(width: 6),
                                              Text('COMPARE', style: Lux.sans(10, c: Lux.blue, w: FontWeight.w700, ls: 1)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (g.aiReason != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Lux.surface2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Lux.blue.withValues(alpha: .3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.sparkles, size: 13, color: Lux.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Doctor AI: ${g.aiReason}',
                                        style: Lux.sans(11, c: Lux.blue, w: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final a in g.assets)
                          _Tile(
                            asset: a,
                            isBest: a.id == g.best?.id,
                            selected: selected.contains(a.id),
                            onTap: () => _openDetail(a, a.id == g.best?.id),
                            onToggleSelect: () => setState(() {
                              Hap.light();
                              selected.contains(a.id) ? selected.remove(a.id) : selected.add(a.id);
                            }),
                          ),
                      ],
                    ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: selected.isEmpty ? 0 : 110,
        child: selected.isEmpty
            ? const SizedBox.shrink()
            : Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(color: Lux.surface, border: Border(top: BorderSide(color: Lux.blue.withValues(alpha: .2)))),
                child: GestureDetector(
                  onTap: _delete,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: Lux.brandGradient, borderRadius: BorderRadius.circular(28)),
                    child: Text('REMOVE ${selected.length} · FREE ${formatBytes(selectedBytes)}',
                        style: Lux.sans(13, c: Lux.bg, w: FontWeight.w700, ls: 2)),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.asset,
    required this.isBest,
    required this.selected,
    required this.onTap,
    required this.onToggleSelect,
  });

  final AssetEntity asset;
  final bool isBest, selected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          AssetThumb(asset),
          if (selected) Container(color: Colors.black.withValues(alpha: .45)),
          if (asset.type == AssetType.video)
            Positioned(left: 6, bottom: 6, child: Text(_dur(asset.duration), style: Lux.sans(11, w: FontWeight.w600, c: Colors.white))),
          if (isBest)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: Lux.brandGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Lux.blue.withValues(alpha: .35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.sparkles, size: 9, color: Lux.bg),
                    const SizedBox(width: 3),
                    Text('AI BEST', style: Lux.sans(9, c: Lux.bg, w: FontWeight.w800, ls: 1)),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleSelect,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Lux.blue : Colors.black45,
                    border: Border.all(color: selected ? Lux.blue : Colors.white70, width: 1.5),
                  ),
                  child: selected ? const Icon(Icons.check, size: 14, color: Lux.bg) : null,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _dur(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
