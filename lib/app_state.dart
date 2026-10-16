import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'scanner.dart';
import 'settings.dart';
import 'theme.dart';

/// Shared scan state used by every tab.
class AppState extends ChangeNotifier {
  AppState._();
  static final i = AppState._();

  ScanResult? result;
  bool scanning = false, denied = false;
  double progress = 0;

  Future<void> scan() async {
    if (scanning) return;
    Hap.medium();
    scanning = true;
    denied = false;
    progress = 0;
    notifyListeners();
    try {
      if (!await Scanner.requestAccess()) {
        denied = true;
        return;
      }
      result = await Scanner.scan((p) {
        progress = p;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Scan error: $e');
      result ??= Scanner.empty();
    } finally {
      scanning = false;
      notifyListeners();
    }
  }
}

class BrandButton extends StatelessWidget {
  const BrandButton({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? .6 : 1,
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: Lux.brandGradient,
              borderRadius: BorderRadius.circular(29),
              boxShadow: [BoxShadow(color: Lux.blue.withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Text(label, style: Lux.sans(13, c: Colors.white, w: FontWeight.w700, ls: 3)),
          ),
        ),
      );
}

class LuxCard extends StatelessWidget {
  const LuxCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: padding,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Lux.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Lux.blue.withValues(alpha: .18)),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4, top: 8),
        child: Text(text.toUpperCase(), style: Lux.sans(11, c: Lux.blue, w: FontWeight.w600, ls: 3)),
      );
}

class AssetThumb extends StatelessWidget {
  const AssetThumb(this.asset, {super.key, this.size = 300});
  final AssetEntity asset;
  final int size;
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(ThumbnailSize.square(size)),
        builder: (_, s) => s.data == null
            ? Container(color: Lux.surface2)
            : Image.memory(s.data!, fit: BoxFit.cover, gaplessPlayback: true),
      );
}
