import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import 'settings.dart';
import 'theme.dart';

class AppIconsScreen extends StatefulWidget {
  const AppIconsScreen({super.key});

  @override
  State<AppIconsScreen> createState() => _AppIconsScreenState();
}

class _AppIconsScreenState extends State<AppIconsScreen> {
  static const _icons = [
    (
      id: 'midnight',
      name: 'Dark Blue Signature',
      subtitle: 'Rich dark blue with a gleaming white crest',
      bgGradient: [Lux.blueLight, Lux.blueDark],
      emblemColor: Colors.white,
      borderColor: Lux.blueLight,
    ),
    (
      id: 'pearl',
      name: 'Pearl White',
      subtitle: 'Clean white finish with a dark blue emblem',
      bgGradient: [Color(0xFFFFFFFF), Color(0xFFE5ECF6)],
      emblemColor: Lux.blue,
      borderColor: Lux.blue,
    ),
    (
      id: 'ocean',
      name: 'Deep Navy',
      subtitle: 'Midnight navy with a pure white seal',
      bgGradient: [Color(0xFF0F3E8A), Color(0xFF0A192F)],
      emblemColor: Colors.white,
      borderColor: Lux.blueDark,
    ),
    (
      id: 'sky',
      name: 'Sky Mist',
      subtitle: 'Soft steel blue with a dark blue emblem',
      bgGradient: [Color(0xFFD6E3F8), Color(0xFFBFD2F2)],
      emblemColor: Lux.blueDark,
      borderColor: Lux.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeId = AppSettings.i.currentAppIcon;

    return Scaffold(
      backgroundColor: Lux.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.chevron_left, color: Lux.blue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CUSTOMIZATION', style: Lux.sans(11, c: Lux.blue, w: FontWeight.w600, ls: 4)),
                        Text('App Icons', style: Lux.serif(28, w: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Mockup Preview on Home Screen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.4),
                    radius: 1.2,
                    colors: [Color(0xFFDDE9FF), Color(0xFFDDE9FF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Lux.blue.withValues(alpha: .2)),
                ),
                child: Column(
                  children: [
                    Text('HOME SCREEN PREVIEW', style: Lux.sans(10, c: Lux.muted, ls: 2.5, w: FontWeight.w500)),
                    const SizedBox(height: 20),
                    _buildIconItem(_icons.firstWhere((e) => e.id == activeId, orElse: () => _icons.first), size: 84),
                    const SizedBox(height: 12),
                    Text('Doctor AI', style: Lux.sans(13, c: Lux.text, w: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                itemCount: _icons.length,
                itemBuilder: (_, i) {
                  final item = _icons[i];
                  final isSelected = item.id == activeId;
                  return GestureDetector(
                    onTap: () {
                      Hap.medium();
                      AppSettings.i.setAppIcon(item.id);
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Lux.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Lux.blue : Lux.blue.withValues(alpha: .18),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildIconItem(item, size: 54),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: Lux.serif(20, w: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(item.subtitle, style: Lux.sans(11, c: Lux.muted)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(CupertinoIcons.checkmark_circle_fill, color: Lux.blue, size: 22)
                          else
                            const Icon(CupertinoIcons.circle, color: Lux.muted, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconItem(
    ({String id, String name, String subtitle, List<Color> bgGradient, Color emblemColor, Color borderColor}) item, {
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.bgGradient,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: item.borderColor.withValues(alpha: .6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .6),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.sparkles,
          color: item.emblemColor,
          size: size * 0.45,
        ),
      ),
    );
  }
}
