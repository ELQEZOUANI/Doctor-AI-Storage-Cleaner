import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark Blue & White brand palette.
class Lux {
  static const bg = Color(0xFFF6F8FC); // page background (crisp soft ice)
  static const surface = Color(0xFFFFFFFF); // pure white cards
  static const surface2 = Color(0xFFE5ECF6); // subtle fills, tracks, dividers
  static const blue = Color(0xFF0F3E8A); // primary dark blue (midnight sapphire)
  static const blueLight = Color(0xFF1E52A8); // luminous dark blue highlight
  static const blueDark = Color(0xFF0A2350); // deep midnight navy
  static const text = Color(0xFF0A192F); // ultra deep navy for text
  static const muted = Color(0xFF5A6E8C); // refined steel blue-gray

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueLight, blue, blueDark],
  );

  static TextStyle serif(double size, {FontWeight w = FontWeight.w500, Color c = text}) =>
      GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: w, color: c, letterSpacing: 0.5);

  static TextStyle sans(double size, {FontWeight w = FontWeight.w400, Color c = text, double ls = 0.2}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: c, letterSpacing: ls);

  static ThemeData theme() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.light(primary: blue, surface: surface),
        useMaterial3: true,
      );
}

String formatBytes(int b) {
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
