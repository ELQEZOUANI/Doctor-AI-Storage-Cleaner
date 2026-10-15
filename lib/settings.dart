import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings and lifetime statistics.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final i = AppSettings._();

  late SharedPreferences _p;
  int maxPhotos = 2000;
  int largeVideoMb = 50;
  bool haptics = true;
  bool onboarded = false;
  int freedBytes = 0;
  int removedCount = 0;
  bool isVip = false;
  bool isDiagnosticUnlocked = false;
  String currentAppIcon = 'ocean';

  /// Whether Doctor AI feature is unlocked (unlocked via VIP or rewarded ad).
  bool get isDoctorAiUnlocked => isVip || isDiagnosticUnlocked;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    maxPhotos = _p.getInt('maxPhotos') ?? 2000;
    largeVideoMb = _p.getInt('largeVideoMb') ?? 50;
    haptics = _p.getBool('haptics') ?? true;
    onboarded = _p.getBool('onboarded') ?? false;
    freedBytes = _p.getInt('freedBytes') ?? 0;
    removedCount = _p.getInt('removedCount') ?? 0;
    isVip = _p.getBool('isVip') ?? false;
    isDiagnosticUnlocked = _p.getBool('isDiagnosticUnlocked') ?? false;
    currentAppIcon = _p.getString('currentAppIcon') ?? 'ocean';
  }

  void setVip(bool v) {
    isVip = v;
    _p.setBool('isVip', v);
    notifyListeners();
  }

  void unlockDiagnostic() {
    isDiagnosticUnlocked = true;
    _p.setBool('isDiagnosticUnlocked', true);
    notifyListeners();
  }

  void setDiagnosticUnlocked(bool v) {
    isDiagnosticUnlocked = v;
    _p.setBool('isDiagnosticUnlocked', v);
    notifyListeners();
  }

  void setAppIcon(String icon) {
    currentAppIcon = icon;
    _p.setString('currentAppIcon', icon);
    notifyListeners();
  }

  void setMaxPhotos(int v) {
    maxPhotos = v;
    _p.setInt('maxPhotos', v);
    notifyListeners();
  }

  void setLargeVideoMb(int v) {
    largeVideoMb = v;
    _p.setInt('largeVideoMb', v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    haptics = v;
    _p.setBool('haptics', v);
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    _p.setBool('onboarded', true);
    notifyListeners();
  }

  void addFreed(int bytes, int count) {
    freedBytes += bytes;
    removedCount += count;
    _p.setInt('freedBytes', freedBytes);
    _p.setInt('removedCount', removedCount);
    notifyListeners();
  }

  void resetStats() {
    freedBytes = 0;
    removedCount = 0;
    _p.setInt('freedBytes', 0);
    _p.setInt('removedCount', 0);
    notifyListeners();
  }
}

/// Haptics that respect the user's setting.
class Hap {
  static void light() {
    if (AppSettings.i.haptics) HapticFeedback.selectionClick();
  }

  static void medium() {
    if (AppSettings.i.haptics) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (AppSettings.i.haptics) HapticFeedback.heavyImpact();
  }
}
