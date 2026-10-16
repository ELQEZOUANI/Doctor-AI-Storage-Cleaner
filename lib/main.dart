import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'analytics_screen.dart';
import 'app_state.dart';
import 'ad_service.dart';
import 'gemini_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'settings.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await AppSettings.i.load();
  await GeminiService.i.init();
  await AdService.i.init();
  runApp(const DoctorAiApp());
}

class DoctorAiApp extends StatefulWidget {
  const DoctorAiApp({super.key});
  @override
  State<DoctorAiApp> createState() => _DoctorAiAppState();
}

class _DoctorAiAppState extends State<DoctorAiApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Doctor AI: Storage Cleaner',
        debugShowCheckedModeBanner: false,
        theme: Lux.theme(),
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: !_splashDone
              ? SplashScreen(
                  key: const ValueKey('splash'),
                  onDone: () {
                    AdService.i.showAppOpenAdIfAvailable(
                      onDismissed: () {
                        if (!mounted) return;
                        setState(() => _splashDone = true);
                        if (AppSettings.i.onboarded) {
                          AppState.i.scan();
                        }
                      },
                    );
                  },
                )
              : !AppSettings.i.onboarded
                  ? OnboardingScreen(
                      key: const ValueKey('onboarding'),
                      initialPage: 0,
                      autoCycle: false,
                      onComplete: () {
                        setState(() {});
                        AppState.i.scan();
                      },
                    )
                  : const Shell(key: ValueKey('shell')),
        ),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: tab, children: const [HomeScreen(), AnalyticsScreen(), SettingsScreen()]),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Lux.blue.withValues(alpha: .2)))),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Lux.surface,
              indicatorColor: Lux.blue.withValues(alpha: .18),
              labelTextStyle: WidgetStateProperty.resolveWith(
                  (s) => Lux.sans(11, c: s.contains(WidgetState.selected) ? Lux.blue : Lux.muted, w: FontWeight.w600, ls: 1)),
              iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? Lux.blue : Lux.muted)),
            ),
            child: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) {
                Hap.light();
                if (i != tab) {
                  if (i == 1 || i == 2) {
                    AdService.i.showInterstitialAdIfAvailable();
                  }
                }
                setState(() => tab = i);
              },
              destinations: const [
                NavigationDestination(icon: Icon(CupertinoIcons.sparkles), label: 'Clean'),
                NavigationDestination(icon: Icon(CupertinoIcons.chart_pie), label: 'Analytics'),
                NavigationDestination(icon: Icon(CupertinoIcons.slider_horizontal_3), label: 'Settings'),
              ],
            ),
          ),
        ),
      );
}
