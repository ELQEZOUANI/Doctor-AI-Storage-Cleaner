import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:photo_manager/photo_manager.dart';

import 'settings.dart';

/// A set of photos/videos presented together. [best] is the one the on-device
/// ranking recommends keeping (null for non-similarity groups).
class CleanGroup {
  CleanGroup(this.assets, {this.best, this.aiReason});
  final List<AssetEntity> assets;
  AssetEntity? best;
  String? aiReason;
}

class LibraryStats {
  LibraryStats({
    required this.photoCount,
    required this.videoCount,
    required this.screenshotCount,
    required this.liveCount,
    required this.photoBytes,
    required this.screenshotBytes,
    required this.liveBytes,
    required this.videoBytes,
    required this.monthBytes,
    required this.topVideos,
  });
  final int photoCount, videoCount, screenshotCount, liveCount;
  final int photoBytes, screenshotBytes, liveBytes, videoBytes;

  /// Keyed by 'yyyy-MM'.
  final Map<String, int> monthBytes;
  final List<AssetEntity> topVideos;

  int get totalBytes => photoBytes + screenshotBytes + liveBytes + videoBytes;
}

class ScanResult {
  ScanResult({
    required this.similar,
    required this.screenshots,
    required this.largeVideos,
    required this.blurry,
    required this.livePhotos,
    required this.sizes,
    required this.stats,
  });
  final List<CleanGroup> similar, screenshots, largeVideos, blurry, livePhotos;

  /// Byte size per asset id (estimated for photos, exact for scanned videos).
  final Map<String, int> sizes;
  final LibraryStats stats;

  int bytesOf(Iterable<AssetEntity> a) => a.fold(0, (s, e) => s + (sizes[e.id] ?? 0));
  Iterable<AssetEntity> flat(List<CleanGroup> g) => g.expand((x) => x.assets);
  int count(List<CleanGroup> g) => g.fold(0, (s, x) => s + x.assets.length);

  Iterable<AssetEntity> get similarRemovable =>
      similar.expand((g) => g.assets.where((a) => a.id != g.best?.id));

  /// Bytes the one-tap "smart clean" would free (similar extras + screenshots + blurry).
  int get smartCleanBytes =>
      bytesOf(similarRemovable) + bytesOf(flat(screenshots)) + bytesOf(flat(blurry));

  int get reclaimable =>
      bytesOf(similarRemovable) +
      bytesOf(flat(screenshots)) +
      bytesOf(flat(blurry)) +
      bytesOf(flat(largeVideos)) +
      bytesOf(flat(livePhotos));
}

class Scanner {
  static Future<bool> requestAccess() async {
    final p = await PhotoManager.requestPermissionExtend();
    return p.hasAccess;
  }

  static int _estimate(AssetEntity a) => (a.width * a.height * 0.45).round();
  static ScanResult empty() => ScanResult(
        similar: [],
        screenshots: [],
        largeVideos: [],
        blurry: [],
        livePhotos: [],
        sizes: {},
        stats: LibraryStats(
            photoCount: 0, videoCount: 0, screenshotCount: 0, liveCount: 0, photoBytes: 0,
            screenshotBytes: 0, liveBytes: 0, videoBytes: 0, monthBytes: {}, topVideos: []),
      );

  static Future<ScanResult> scan(void Function(double) onProgress) async {
    final s = AppSettings.i;
    final maxImages = s.maxPhotos;
    final largeBytes = s.largeVideoMb * 1024 * 1024;
    final sizes = <String, int>{};

    final paths = await PhotoManager.getAssetPathList(onlyAll: true);
    if (paths.isEmpty) return empty();
    final all = paths.first;
    final total = await all.assetCountAsync;
    if (total <= 0) return empty();
    final assets = await all.getAssetListRange(start: 0, end: total.clamp(1, maxImages * 2));

    final images = assets.where((a) => a.type == AssetType.image).take(maxImages).toList();
    final videos = assets.where((a) => a.type == AssetType.video).toList();
    for (final a in images) {
      sizes[a.id] = _estimate(a);
    }

    final shots = images.where((a) => (a.subtype & 4) != 0).toList();
    final live = images.where((a) => a.isLivePhoto).toList();

    // Videos: exact size for the first 300, duration-based estimate beyond.
    final large = <AssetEntity>[];
    for (var i = 0; i < videos.length; i++) {
      if (i < 300) {
        final f = await videos[i].originFile;
        sizes[videos[i].id] = f != null ? await f.length() : videos[i].duration * 2500000;
        if (i % 10 == 0) onProgress(0.1 * (i / videos.length.clamp(1, 300)));
      } else {
        sizes[videos[i].id] = videos[i].duration * 2500000;
      }
      if (sizes[videos[i].id]! >= largeBytes) large.add(videos[i]);
    }
    large.sort((a, b) => sizes[b.id]!.compareTo(sizes[a.id]!));

    // Single thumbnail pass: perceptual hash + sharpness.
    final hashes = <String, BigInt>{};
    final blurry = <AssetEntity>[];
    for (var i = 0; i < images.length; i++) {
      final r = await _analyse(images[i]);
      if (r != null) {
        hashes[images[i].id] = r.hash;
        if (r.sharpness < 30 && (images[i].subtype & 4) == 0) blurry.add(images[i]);
      }
      if (i % 20 == 0) onProgress(0.1 + 0.9 * (i / images.length));
    }
    final similar = _group(images.where((a) => hashes.containsKey(a.id)).toList(), hashes);
    onProgress(1);

    // Library analytics (extrapolated to full counts).
    final photoTotal = await PhotoManager.getAssetCount(type: RequestType.image);
    final videoTotal = await PhotoManager.getAssetCount(type: RequestType.video);
    final shotIds = shots.map((e) => e.id).toSet();
    final liveIds = live.map((e) => e.id).toSet();
    var photoB = 0, shotB = 0, liveB = 0, vidB = 0;
    final months = <String, int>{};
    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
    for (final a in images) {
      final b = sizes[a.id]!;
      if (shotIds.contains(a.id)) {
        shotB += b;
      } else if (liveIds.contains(a.id)) {
        liveB += b;
      } else {
        photoB += b;
      }
      months.update(key(a.createDateTime), (v) => v + b, ifAbsent: () => b);
    }
    for (final v in videos) {
      vidB += sizes[v.id]!;
      months.update(key(v.createDateTime), (x) => x + sizes[v.id]!, ifAbsent: () => sizes[v.id]!);
    }
    // Extrapolate image totals beyond the scan window.
    final scale = images.isEmpty ? 1.0 : (photoTotal / images.length).clamp(1.0, 1000.0);
    final top = [...videos]..sort((a, b) => sizes[b.id]!.compareTo(sizes[a.id]!));

    return ScanResult(
      similar: similar,
      screenshots: shots.isEmpty ? [] : [CleanGroup(shots)],
      largeVideos: large.isEmpty ? [] : [CleanGroup(large)],
      blurry: blurry.isEmpty ? [] : [CleanGroup(blurry)],
      livePhotos: live.isEmpty ? [] : [CleanGroup(live)],
      sizes: sizes,
      stats: LibraryStats(
        photoCount: photoTotal,
        videoCount: videoTotal,
        screenshotCount: (shots.length * scale).round(),
        liveCount: (live.length * scale).round(),
        photoBytes: (photoB * scale).round(),
        screenshotBytes: (shotB * scale).round(),
        liveBytes: (liveB * scale).round(),
        videoBytes: vidB,
        monthBytes: months,
        topVideos: top.take(5).toList(),
      ),
    );
  }

  static const _n = 96;

  static Future<({BigInt hash, double sharpness})?> _analyse(AssetEntity a) async {
    try {
      final data = await a.thumbnailDataWithSize(const ThumbnailSize(_n, _n));
      if (data == null) return null;
      final codec = await ui.instantiateImageCodec(data, targetWidth: _n, targetHeight: _n);
      final img = (await codec.getNextFrame()).image;
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) return null;
      final Uint8List px = bd.buffer.asUint8List();
      final g = List<double>.filled(_n * _n, 0);
      for (var i = 0; i < _n * _n; i++) {
        g[i] = 0.299 * px[i * 4] + 0.587 * px[i * 4 + 1] + 0.114 * px[i * 4 + 2];
      }

      // dHash on a 9x8 block-averaged grid.
      double block(int bx, int by) {
        final x0 = bx * _n ~/ 9, x1 = (bx + 1) * _n ~/ 9, y0 = by * _n ~/ 8, y1 = (by + 1) * _n ~/ 8;
        var sum = 0.0, c = 0;
        for (var y = y0; y < y1; y++) {
          for (var x = x0; x < x1; x++) {
            sum += g[y * _n + x];
            c++;
          }
        }
        return sum / c;
      }

      var bits = BigInt.zero;
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          bits = (bits << 1) | (block(x, y) > block(x + 1, y) ? BigInt.one : BigInt.zero);
        }
      }

      // Variance of the Laplacian = sharpness.
      var sum = 0.0, sumSq = 0.0, n = 0;
      for (var y = 1; y < _n - 1; y++) {
        for (var x = 1; x < _n - 1; x++) {
          final l = 4 * g[y * _n + x] - g[y * _n + x - 1] - g[y * _n + x + 1] - g[(y - 1) * _n + x] - g[(y + 1) * _n + x];
          sum += l;
          sumSq += l * l;
          n++;
        }
      }
      final mean = sum / n;
      return (hash: bits, sharpness: sumSq / n - mean * mean);
    } catch (_) {
      return null;
    }
  }

  static int _hamming(BigInt a, BigInt b) {
    var x = a ^ b;
    var c = 0;
    while (x > BigInt.zero) {
      if ((x & BigInt.one) == BigInt.one) c++;
      x >>= 1;
    }
    return c;
  }

  /// Photos are time-ordered; similar shots are taken close together, so each
  /// photo is only compared against a small window of neighbours.
  static List<CleanGroup> _group(List<AssetEntity> imgs, Map<String, BigInt> h) {
    const window = 25, threshold = 6;
    final used = <String>{};
    final groups = <CleanGroup>[];
    for (var i = 0; i < imgs.length; i++) {
      if (used.contains(imgs[i].id)) continue;
      final members = [imgs[i]];
      for (var j = i + 1; j < imgs.length && j <= i + window; j++) {
        if (used.contains(imgs[j].id)) continue;
        if (_hamming(h[imgs[i].id]!, h[imgs[j].id]!) <= threshold) members.add(imgs[j]);
      }
      if (members.length > 1) {
        used.addAll(members.map((m) => m.id));
        groups.add(CleanGroup(members, best: _pickBest(members)));
      }
    }
    return groups;
  }

  /// Smart pick: favourites first, then highest resolution.
  static AssetEntity _pickBest(List<AssetEntity> m) {
    final sorted = [...m]..sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return (b.width * b.height).compareTo(a.width * a.height);
      });
    return sorted.first;
  }

  static Future<List<String>> delete(List<String> ids) => PhotoManager.editor.deleteWithIds(ids);
}
