import 'dart:convert';
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
}
