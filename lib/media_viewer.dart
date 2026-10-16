import 'dart:typed_data';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import 'gemini_service.dart';
import 'settings.dart';
import 'theme.dart';

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.isBest,
    required this.onToggleSelected,
  });

  final AssetEntity asset;
  final bool isSelected;
  final bool isBest;
  final VoidCallback onToggleSelected;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.isSelected;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: FutureBuilder<Uint8List?>(
                future: a.thumbnailDataWithSize(const ThumbnailSize(1200, 1200)),
                builder: (_, s) {
                  if (s.data == null) {
                    return const Center(child: CircularProgressIndicator(color: Lux.blue));
                  }
                  return Image.memory(s.data!, fit: BoxFit.contain);
                },
              ),
            ),
          ),
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context, _selected),
                  ),
                  Column(
                    children: [
                      Text(
                        '${a.width} × ${a.height}',
                        style: Lux.sans(13, w: FontWeight.w600, c: Lux.text),
                      ),
                      Text(
                        '${a.createDateTime.year}-${a.createDateTime.month.toString().padLeft(2, '0')}-${a.createDateTime.day.toString().padLeft(2, '0')}',
                        style: Lux.sans(11, c: Lux.muted),
                      ),
                    ],
                  ),
                  if (widget.isBest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(gradient: Lux.brandGradient, borderRadius: BorderRadius.circular(12)),
                      child: Text('AI BEST', style: Lux.sans(10, c: Lux.bg, w: FontWeight.w800, ls: 1.5)),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          // Bottom Bar Action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Hap.medium();
                      setState(() => _selected = !_selected);
                      widget.onToggleSelected();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _selected ? Lux.brandGradient : null,
                        color: _selected ? null : Lux.surface2,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Lux.blue.withValues(alpha: .5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: _selected ? Lux.bg : Lux.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selected ? 'MARKED TO REMOVE' : 'KEEP PHOTO',
                            style: Lux.sans(12, c: _selected ? Lux.bg : Lux.text, w: FontWeight.w700, ls: 1.5),
                          ),
                        ],
                      ),
                    ),
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

class VideoViewerScreen extends StatefulWidget {
  const VideoViewerScreen({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.onToggleSelected,
  });

  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onToggleSelected;

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.isSelected;
    _initVideo();
  }

  Future<void> _initVideo() async {
    final file = await widget.asset.file;
    if (file != null) {
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _controller?.play();
            _controller?.setLooping(true);
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _initialized && _controller != null
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : const CircularProgressIndicator(color: Lux.blue),
          ),
          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context, _selected),
                  ),
                  Text(
                    '${a.duration ~/ 60}:${(a.duration % 60).toString().padLeft(2, '0')}',
                    style: Lux.sans(14, w: FontWeight.w600, c: Lux.text),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_initialized && _controller != null)
                    ValueListenableBuilder(
                      valueListenable: _controller!,
                      builder: (_, VideoPlayerValue val, _) => Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              val.isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                              color: Lux.blue,
                            ),
                            onPressed: () {
                              val.isPlaying ? _controller?.pause() : _controller?.play();
                            },
                          ),
                          Expanded(
                            child: VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: Lux.blue,
                                bufferedColor: Lux.blueDark.withValues(alpha: .4),
                                backgroundColor: Lux.surface2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Hap.medium();
                      setState(() => _selected = !_selected);
                      widget.onToggleSelected();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _selected ? Lux.brandGradient : null,
                        color: _selected ? null : Lux.surface2,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Lux.blue.withValues(alpha: .5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: _selected ? Lux.bg : Lux.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selected ? 'MARKED TO REMOVE' : 'KEEP VIDEO',
                            style: Lux.sans(12, c: _selected ? Lux.bg : Lux.text, w: FontWeight.w700, ls: 1.5),
                          ),
                        ],
                      ),
                    ),
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

/// Signature Luxury Side-by-Side split screen comparison with draggable divider.
class CompareScreen extends StatefulWidget {
  const CompareScreen({
    super.key,
    required this.assetA,
    required this.assetB,
    required this.isBestA,
    required this.isBestB,
    required this.isSelectedA,
    required this.isSelectedB,
    required this.onToggleA,
    required this.onToggleB,
  });

  final AssetEntity assetA;
  final AssetEntity assetB;
  final bool isBestA;
  final bool isBestB;
  final bool isSelectedA;
  final bool isSelectedB;
  final VoidCallback onToggleA;
  final VoidCallback onToggleB;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  double _splitFraction = 0.5; // Center split line
  late bool _selA;
  late bool _selB;
  bool _analyzingAi = false;
  String? _aiDecision;
  String? _aiReason;

  @override
  void initState() {
    super.initState();
    _selA = widget.isSelectedA;
    _selB = widget.isSelectedB;
  }

  Future<void> _runDoctorAiComparison() async {
    setState(() => _analyzingAi = true);
    Hap.medium();

    try {
      final res = await GeminiService.i.analyzeBestShot([widget.assetA, widget.assetB]);
      if (!mounted) return;
      final recommendedSide = res.bestIndex == 0 ? 'LEFT' : 'RIGHT';
      setState(() {
        _aiDecision = recommendedSide;
        _aiReason = res.reason;
        if (res.bestIndex == 0) {
          if (_selA != false) {
            _selA = false;
            widget.onToggleA();
          }
          if (_selB != true) {
            _selB = true;
            widget.onToggleB();
          }
        } else {
          if (_selA != true) {
            _selA = true;
            widget.onToggleA();
          }
          if (_selB != false) {
            _selB = false;
            widget.onToggleB();
          }
        }
      });
      Hap.heavy();
    } catch (e) {
      debugPrint('Error in AI comparison: $e');
    } finally {
      if (mounted) setState(() => _analyzingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dividerX = size.width * _splitFraction;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Asset B (Right side)
          Positioned.fill(
            child: FutureBuilder<Uint8List?>(
              future: widget.assetB.thumbnailDataWithSize(const ThumbnailSize(1200, 1200)),
              builder: (_, s) => s.data == null
                  ? const Center(child: CircularProgressIndicator(color: Lux.blue))
                  : Image.memory(s.data!, fit: BoxFit.cover),
            ),
          ),
          // Foreground Clipped Asset A (Left side)
          Positioned.fill(
            child: ClipRect(
              clipper: _LeftSplitClipper(dividerX),
              child: FutureBuilder<Uint8List?>(
                future: widget.assetA.thumbnailDataWithSize(const ThumbnailSize(1200, 1200)),
                builder: (_, s) => s.data == null
                    ? const SizedBox()
                    : Image.memory(s.data!, fit: BoxFit.cover),
              ),
            ),
          ),
          // Draggable Split Divider Line
          Positioned(
            left: dividerX - 16,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _splitFraction = (_splitFraction + d.primaryDelta! / size.width).clamp(0.08, 0.92);
                });
              },
              child: SizedBox(
                width: 32,
                child: Center(
                  child: Container(
                    width: 3,
                    color: Lux.blue,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Lux.bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Lux.blue, width: 2),
                        ),
                        child: const Icon(CupertinoIcons.arrow_left_right, size: 14, color: Lux.blue),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Top Bar with AI Comparison Action
          // Top Navigation Bar: Close Button + Centered AI Action
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(CupertinoIcons.xmark, size: 18, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: _analyzingAi ? null : _runDoctorAiComparison,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _aiDecision != null ? Lux.brandGradient : null,
                      color: _aiDecision != null ? null : Colors.black87,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Lux.blue.withValues(alpha: _aiDecision != null ? 0 : 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Lux.blue.withValues(alpha: .25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_analyzingAi)
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 1.6, color: Lux.blue),
                          )
                        else
                          Icon(CupertinoIcons.sparkles,
                              size: 14,
                              color: _aiDecision != null ? Lux.bg : Lux.blue),
                        const SizedBox(width: 7),
                        Text(
                          _analyzingAi
                              ? 'ANALYZING...'
                              : (_aiDecision != null ? 'DOCTOR AI: $_aiDecision' : 'AI BEST SHOT'),
                          style: Lux.sans(12,
                              c: _aiDecision != null ? Lux.bg : Lux.blue,
                              w: FontWeight.w800,
                              ls: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 38), // Balances close button perfectly
              ],
            ),
          ),
          // Floating Side Badges: LEFT & RIGHT
          Positioned(
            top: MediaQuery.of(context).padding.top + 54,
            left: 16,
            child: _labelBadge('LEFT', widget.isBestA || _aiDecision == 'LEFT'),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 54,
            right: 16,
            child: _labelBadge('RIGHT', widget.isBestB || _aiDecision == 'RIGHT'),
          ),
          // AI Reasoning Card (if available)
          if (_aiReason != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 84,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Lux.surface.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Lux.blue.withValues(alpha: .4)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: Lux.brandGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(CupertinoIcons.sparkles, size: 14, color: Lux.bg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Doctor AI Selected: $_aiDecision',
                              style: Lux.sans(12, c: Lux.blue, w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_aiReason!,
                              style: Lux.sans(11, c: Lux.muted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bottom Selection Buttons
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: _choiceButton(
                    label: _selA ? 'REMOVE LEFT' : 'KEEP LEFT',
                    selected: _selA,
                    onTap: () {
                      Hap.light();
                      setState(() => _selA = !_selA);
                      widget.onToggleA();
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _choiceButton(
                    label: _selB ? 'REMOVE RIGHT' : 'KEEP RIGHT',
                    selected: _selB,
                    onTap: () {
                      Hap.light();
                      setState(() => _selB = !_selB);
                      widget.onToggleB();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelBadge(String side, bool isBest) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isBest ? Lux.blue : Colors.white24, width: isBest ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBest) ...[
              const Icon(CupertinoIcons.star_fill, size: 11, color: Lux.blue),
              const SizedBox(width: 5),
            ],
            Text(
              isBest ? '$side (AI BEST)' : side,
              style: Lux.sans(11, c: isBest ? Lux.blue : Colors.white, w: FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _choiceButton({required String label, required bool selected, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? Lux.brandGradient : null,
            color: selected ? null : Colors.black87,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Lux.blue.withValues(alpha: .5)),
          ),
          child: Text(
            label,
            style: Lux.sans(11, c: selected ? Lux.bg : Colors.white, w: FontWeight.w700, ls: 1),
          ),
        ),
      );
}

class _LeftSplitClipper extends CustomClipper<Rect> {
  _LeftSplitClipper(this.splitX);
  final double splitX;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, splitX, size.height);
  @override
  bool shouldReclip(_LeftSplitClipper oldClipper) => oldClipper.splitX != splitX;
}
