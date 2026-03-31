// lib/utils/app_config.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // Remote Config parameter names — match exactly what you set in Firebase.
  static const String _kGemini   = 'gemini_api_key';
  static const String _kMaptiler = 'maptiler_api_key';

  // Cache duration — keys are fetched fresh at most once per hour.
  // Prevents hammering Remote Config on every map tile request.
  static const Duration _fetchInterval = Duration(hours: 1);

  static FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  /// Call once in main() after Firebase.initializeApp().
  /// Sets fetch interval and activates cached values immediately.
  static Future<void> initialize() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout:      const Duration(seconds: 10),
        minimumFetchInterval: _fetchInterval,
      ));

      // Set empty defaults so the app never crashes if Remote Config
      // is unreachable on first launch.
      await _rc.setDefaults(const {
        _kGemini:   '',
        _kMaptiler: '',
      });

      await _rc.fetchAndActivate();
      _logInfo('AppConfig: Remote Config initialised');
    } catch (e) {
      // Non-fatal — cached or default values will be used.
      _logWarning('AppConfig: Remote Config init failed — $e');
    }
  }

  /// Gemini API key — read from Remote Config.
  static String get geminiApiKey {
    final key = _rc.getString(_kGemini);
    if (key.isEmpty) _logWarning('AppConfig: gemini_api_key is empty');
    return key;
  }

  /// MapTiler API key — read from Remote Config.
  static String get maptilerApiKey {
    final key = _rc.getString(_kMaptiler);
    if (key.isEmpty) _logWarning('AppConfig: maptiler_api_key is empty');
    return key;
  }

  static void _logInfo(String msg) {
    if (kDebugMode) debugPrint('[AppConfig] $msg');
  }

  static void _logWarning(String msg) {
    if (kDebugMode) debugPrint('[AppConfig] WARNING: $msg');
  }
}
