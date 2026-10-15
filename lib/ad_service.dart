import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'settings.dart';

/// Professional AdMob service managing real production iOS AdMob ads
/// (App Open, Rewarded, Interstitial) for Doctor AI: Storage Cleaner.
class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService i = AdService._();

  /// Real production iOS AdMob App ID.
  static String appId = kAdMobIosAppId;

  /// Real production iOS App Open Ad Unit ID.
  static String appOpenAdUnitId = kAdMobIosAppOpenAdUnitId;

  /// Real production iOS Rewarded Ad Unit ID.
  static String rewardedAdUnitId = kAdMobIosRewardedAdUnitId;

  /// Real production iOS Interstitial Ad Unit ID.
  static String interstitialAdUnitId = kAdMobIosInterstitialAdUnitId;

  // --- App Open Ad State ---
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadTime;
  bool _isLoadingAppOpen = false;

  // --- Rewarded Ad State ---
  RewardedAd? _rewardedAd;
  DateTime? _rewardedLoadTime;
  bool _isLoadingRewarded = false;

  // --- Interstitial Ad State ---
  InterstitialAd? _interstitialAd;
  DateTime? _interstitialLoadTime;
  bool _isLoadingInterstitial = false;
  DateTime? _lastInterstitialShowTime;

  /// Cooldown between consecutive interstitial presentations to maintain luxury UX.
  static const Duration minInterstitialInterval = Duration(seconds: 20);

  bool _isShowingAd = false;
  bool _isInitialized = false;

  /// Tracks time when app entered background to prevent showing App Open ads on quick switches.
  DateTime? _backgroundTime;

  /// Returns true if an App Open Ad is cached, unexpired (valid for 4 hours),
  /// and the user is not a VIP/Pro subscriber.
  bool get isAdAvailable {
    if (AppSettings.i.isVip) return false;
    if (_appOpenAd == null || _isShowingAd || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  /// Returns true if a Rewarded Ad is cached and ready to show.
  bool get isRewardedAdAvailable {
    if (AppSettings.i.isVip) return false;
    if (_rewardedAd == null || _isShowingAd || _rewardedLoadTime == null) return false;
    return DateTime.now().difference(_rewardedLoadTime!) < const Duration(hours: 4);
  }

  /// Returns true if an Interstitial Ad is cached and ready.
  /// Set [ignoreCooldown] to true for user delete actions.
  bool isInterstitialReady({bool ignoreCooldown = false}) {
    if (AppSettings.i.isVip) return false;
    if (_interstitialAd == null || _isShowingAd || _interstitialLoadTime == null) return false;
    if (DateTime.now().difference(_interstitialLoadTime!) >= const Duration(hours: 4)) return false;
    if (!ignoreCooldown &&
        _lastInterstitialShowTime != null &&
        DateTime.now().difference(_lastInterstitialShowTime!) < minInterstitialInterval) {
      return false;
    }
    return true;
  }

  /// Returns true if an Interstitial Ad is cached and past cooldown.
  bool get isInterstitialAdAvailable => isInterstitialReady(ignoreCooldown: false);

  /// Whether any ad is currently presenting on screen.
  bool get isShowingAd => _isShowingAd;

  /// Initializes the Google Mobile Ads SDK and preloads inventory.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      WidgetsBinding.instance.addObserver(this);
      debugPrint('[AdService] Google Mobile Ads initialized successfully.');

      // Preload all ad units
      loadAppOpenAd();
      loadRewardedAd();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('[AdService] Initialization notice: $e');
    }
  }

  // --- Configuration ---

  void setAppOpenAdUnitId(String id) {
    appOpenAdUnitId = id;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    loadAppOpenAd();
  }

  void setRewardedAdUnitId(String id) {
    rewardedAdUnitId = id;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    loadRewardedAd();
  }

  void setInterstitialAdUnitId(String id) {
    interstitialAdUnitId = id;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    loadInterstitialAd();
  }

  bool _isValidUnit(String id) =>
      id.isNotEmpty && !id.contains('YOUR_') && !id.contains('PASTE_');

  // --- App Open Ads ---

  void loadAppOpenAd() {
    if (AppSettings.i.isVip || !_isValidUnit(appOpenAdUnitId)) return;
    if (_isLoadingAppOpen || isAdAvailable) return;

    _isLoadingAppOpen = true;
    try {
      AppOpenAd.load(
        adUnitId: appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdService] App Open Ad loaded successfully.');
            _appOpenAd = ad;
            _appOpenLoadTime = DateTime.now();
            _isLoadingAppOpen = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] App Open Ad failed to load: ${error.message} (${error.code})');
            _isLoadingAppOpen = false;
            _appOpenAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] AppOpenAd.load notice: $e');
      _isLoadingAppOpen = false;
    }
  }

  void showAppOpenAdIfAvailable({VoidCallback? onDismissed}) {
    if (AppSettings.i.isVip || !isAdAvailable) {
      loadAppOpenAd();
      onDismissed?.call();
      return;
    }

    try {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
          debugPrint('[AdService] App Open Ad showed full screen.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('[AdService] App Open Ad dismissed.');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          onDismissed?.call();
          loadAppOpenAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdService] App Open Ad failed to show: ${error.message}');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          onDismissed?.call();
          loadAppOpenAd();
        },
      );

      _appOpenAd!.show();
    } catch (e) {
      debugPrint('[AdService] AppOpenAd.show notice: $e');
      _isShowingAd = false;
      _appOpenAd = null;
      onDismissed?.call();
    }
  }

  // --- Rewarded Ads (Doctor AI unlock) ---

  void loadRewardedAd() {
    if (AppSettings.i.isVip || !_isValidUnit(rewardedAdUnitId)) return;
    if (_isLoadingRewarded || isRewardedAdAvailable) return;

    _isLoadingRewarded = true;
    try {
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdService] Rewarded Ad loaded successfully.');
            _rewardedAd = ad;
            _rewardedLoadTime = DateTime.now();
            _isLoadingRewarded = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] Rewarded Ad failed to load: ${error.message} (${error.code})');
            _isLoadingRewarded = false;
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] RewardedAd.load notice: $e');
      _isLoadingRewarded = false;
    }
  }

  void showRewardedAd({
    required void Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
    VoidCallback? onFailed,
  }) {
    if (AppSettings.i.isVip) {
      onDismissed?.call();
      return;
    }

    if (!isRewardedAdAvailable) {
      loadRewardedAd();
      onFailed?.call();
      return;
    }

    try {
      _isShowingAd = true;
      bool rewarded = false;
      RewardItem? rewardItem;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
          debugPrint('[AdService] Rewarded Ad showed full screen.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('[AdService] Rewarded Ad dismissed.');
          _isShowingAd = false;
          ad.dispose();
          _rewardedAd = null;
          if (rewarded && rewardItem != null) {
            onUserEarnedReward(rewardItem!);
          }
          onDismissed?.call();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdService] Rewarded Ad failed to show: ${error.message}');
          _isShowingAd = false;
          ad.dispose();
          _rewardedAd = null;
          onFailed?.call();
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
          rewarded = true;
          rewardItem = reward;
        },
      );
    } catch (e) {
      debugPrint('[AdService] RewardedAd.show notice: $e');
      _isShowingAd = false;
      _rewardedAd = null;
      onFailed?.call();
      loadRewardedAd();
    }
  }

  // --- Interstitial Ads (Analytics & Settings transitions) ---

  void loadInterstitialAd() {
    if (AppSettings.i.isVip || !_isValidUnit(interstitialAdUnitId)) return;
    if (_isLoadingInterstitial ||
        (_interstitialAd != null &&
            _interstitialLoadTime != null &&
            DateTime.now().difference(_interstitialLoadTime!) < const Duration(hours: 4))) {
      return;
    }

    _isLoadingInterstitial = true;
    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdService] Interstitial Ad loaded successfully.');
            _interstitialAd = ad;
            _interstitialLoadTime = DateTime.now();
            _isLoadingInterstitial = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] Interstitial Ad failed to load: ${error.message} (${error.code})');
            _isLoadingInterstitial = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] InterstitialAd.load notice: $e');
      _isLoadingInterstitial = false;
    }
  }

  void showInterstitialAdIfAvailable({
    VoidCallback? onDismissed,
    bool ignoreCooldown = false,
  }) {
    if (AppSettings.i.isVip || !isInterstitialReady(ignoreCooldown: ignoreCooldown)) {
      if (_interstitialAd == null) {
        loadInterstitialAd();
      }
      onDismissed?.call();
      return;
    }

    try {
      _isShowingAd = true;
      _lastInterstitialShowTime = DateTime.now();

      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
          debugPrint('[AdService] Interstitial Ad showed full screen.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('[AdService] Interstitial Ad dismissed.');
          _isShowingAd = false;
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdService] Interstitial Ad failed to show: ${error.message}');
          _isShowingAd = false;
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
          loadInterstitialAd();
        },
      );

      _interstitialAd!.show();
    } catch (e) {
      debugPrint('[AdService] InterstitialAd.show notice: $e');
      _isShowingAd = false;
      _interstitialAd = null;
      onDismissed?.call();
      loadInterstitialAd();
    }
  }

  // --- Lifecycle & Cleanup ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // Only show on resume if the app was in the background for more than 3 seconds
      final bg = _backgroundTime;
      _backgroundTime = null;
      if (bg != null && DateTime.now().difference(bg) > const Duration(seconds: 3)) {
        showAppOpenAdIfAvailable();
      }
    }
  }

  /// Cleans up resources.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
