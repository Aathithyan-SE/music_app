import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  static AdMobService get instance => _instance;

  // Test AdMob IDs - Use these for testing
  static String get _testBannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Android test banner ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner ID

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  bool get isBannerAdReady => _isBannerAdReady;
  BannerAd? get bannerAd => _bannerAd;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _testBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          // Failed to load banner ad: $error
          ad.dispose();
          _isBannerAdReady = false;
        },
        onAdOpened: (ad) {},
        onAdClosed: (ad) {},
        onAdImpression: (ad) {},
      ),
    );

    _bannerAd?.load();
  }

  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Android test interstitial ID
          : 'ca-app-pub-3940256099942544/4411468910', // iOS test interstitial ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          // Show the ad immediately when loaded
          ad.show();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (error) {
          // Failed to load interstitial ad: $error
        },
      ),
    );
  }

  void showInterstitialAd() {
    createInterstitialAd();
  }
  
  // Method to show interstitial ad after every search
  void trackSearchAndShowAd() {
    // Show interstitial ad after every search
    showInterstitialAd();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }
}