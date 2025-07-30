import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class PrimaryStorageServices {
  static final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();


  static Future<String?> getAccessToken() async {
    final SharedPreferences prefs = await _prefs;

    String? token = prefs.getString('access-token');
    log("userAccessToken: $token");
    return token;
  }

  static Future<void> setAccessToken(String token) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setString('access-token', token);
  }

  static Future<void> removeToken() async {
    final SharedPreferences prefs = await _prefs;
    prefs.remove('access-token');
  }

  static Future<void> removeAll() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.clear();
    prefs.remove('access-token');
  }
}