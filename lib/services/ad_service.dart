import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_constants.dart';

/// Service singleton untuk semua AdMob ads.
///
/// Panggil [initialize()] dari main() sebelum runApp.
/// COPPA compliance diset otomatis (tagForChildDirectedTreatment + maxAdContentRating G).
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  DateTime? _lastInterstitialShown;
  bool _isInitialized = false;

  // ─── Inisialisasi ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    // COPPA compliance — wajib untuk app anak
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );

    await MobileAds.instance.initialize();
    _isInitialized = true;
    debugPrint('[Ad] MobileAds initialized (COPPA compliant)');

    _loadInterstitial();
    _loadRewarded();
  }

  // ─── Banner Ad ────────────────────────────────────────────────────────────

  /// Buat BannerAd baru. BannerAdWidget yang bertanggung jawab load & dispose.
  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
  }) {
    return BannerAd(
      adUnitId: AppConstants.bannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) => onFailed(ad, error),
      ),
    );
  }

  // ─── Interstitial ─────────────────────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
          debugPrint('[Ad] Interstitial loaded');
        },
        onAdFailedToLoad: (error) =>
            debugPrint('[Ad] Interstitial failed to load: $error'),
      ),
    );
  }

  /// Tampilkan interstitial jika: tidak premium + sudah tersedia + 3 menit berlalu.
  Future<void> showInterstitialIfReady({required bool isPremium}) async {
    if (isPremium) return;
    if (_interstitialAd == null) {
      _loadInterstitial(); // preload untuk sesi berikutnya
      return;
    }

    // Throttle: tidak lebih dari 1x per N menit
    final now = DateTime.now();
    if (_lastInterstitialShown != null) {
      final elapsed = now.difference(_lastInterstitialShown!).inMinutes;
      if (elapsed < AppConstants.interstitialIntervalMinutes) {
        debugPrint('[Ad] Interstitial throttled ($elapsed min < ${AppConstants.interstitialIntervalMinutes} min)');
        return;
      }
    }

    _lastInterstitialShown = now;
    final ad = _interstitialAd!;
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[Ad] Interstitial show failed: $error');
        ad.dispose();
        _loadInterstitial();
      },
    );

    await ad.show();
  }

  // ─── Rewarded ─────────────────────────────────────────────────────────────

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('[Ad] Rewarded loaded');
        },
        onAdFailedToLoad: (error) =>
            debugPrint('[Ad] Rewarded failed to load: $error'),
      ),
    );
  }

  /// Tampilkan rewarded ad. Return `true` jika reward diberikan.
  Future<bool> showRewarded() async {
    if (_rewardedAd == null) {
      _loadRewarded();
      debugPrint('[Ad] Rewarded not ready');
      return false;
    }

    final completer = Completer<bool>();
    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[Ad] Rewarded show failed: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) => rewarded = true,
    );
    _rewardedAd = null;

    // Timeout 60 detik — jaga-jaga callback tidak terpanggil
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => false,
    );
  }

  bool get isRewardedReady => _rewardedAd != null;
}
