import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  bool _isFirstLaunch = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> isFirstLaunch() async {
    if (_prefs == null) await init(); // Ensure _prefs is initialized
    _isFirstLaunch = _prefs?.getBool('first_launch') ?? true;
    return _isFirstLaunch;
  }

  Future<void> setFirstLaunchComplete() async {
    if (_prefs == null) await init(); // Ensure _prefs is initialized
    await _prefs?.setBool('first_launch', false);
    _isFirstLaunch = false;
  }

  // App Rating Methods
  Future<int> getLoginCount() async {
    if (_prefs == null) await init();
    return _prefs?.getInt('login_count') ?? 0;
  }

  Future<void> incrementLoginCount() async {
    if (_prefs == null) await init();
    final currentCount = await getLoginCount();
    await _prefs?.setInt('login_count', currentCount + 1);
  }

  Future<bool> hasShownRatingPrompt() async {
    if (_prefs == null) await init();
    return _prefs?.getBool('has_shown_rating_prompt') ?? false;
  }

  Future<void> setRatingPromptShown() async {
    if (_prefs == null) await init();
    await _prefs?.setBool('has_shown_rating_prompt', true);
  }

  Future<bool> shouldShowRatingPrompt() async {
    final loginCount = await getLoginCount();
    final hasShownPrompt = await hasShownRatingPrompt();
    return loginCount >= 6 && !hasShownPrompt;
  }
}
