import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:modizk_download/services/admob_service.dart';
import 'package:modizk_download/theme.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdMobService _adMobService = AdMobService.instance;

  @override
  void initState() {
    super.initState();
    _adMobService.loadBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.primaryBackground,
        border: Border(
          top: BorderSide(
            color: MyColors.secondaryText.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: _adMobService.isBannerAdReady && _adMobService.bannerAd != null
          ? SizedBox(
              height: _adMobService.bannerAd!.size.height.toDouble(),
              width: _adMobService.bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _adMobService.bannerAd!),
            )
          : Container(
              height: 50,
              child: Center(
                child: Text(
                  'Loading ad...',
                  style: TextStyle(
                    color: MyColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}