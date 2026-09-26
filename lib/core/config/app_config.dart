import 'package:shared_preferences/shared_preferences.dart';

/// Where the app finds the `alert-service` backend.
///
/// A phone must reach the server by its **LAN IP**, never `localhost`. Set it
/// three ways (in order of precedence at runtime):
///  1. An in-app override saved to shared_preferences (long-press the dashboard
///     title → "Server URL"). Survives restarts.
///  2. A compile-time default via `--dart-define=API_BASE_URL=http://<ip>:8090`.
///  3. The built-in fallback below (`10.0.2.2` = the host loopback as seen from
///     the Android emulator).
class AppConfig {
  AppConfig._();

  static const String _prefsKey = 'api_base_url';
  static const String _tokenKey = 'fcm_token';
  static const String _layoutKey = 'exit_layout';

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8090',
  );

  static String _baseUrl = _envBaseUrl;

  /// Current backend origin, e.g. `http://192.168.1.10:8090` (no trailing slash).
  static String get baseUrl => _baseUrl;

  /// Load a persisted override, if the user set one. Call once in `main()`.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = _normalise(saved);
      }
      final layout = prefs.getString(_layoutKey);
      if (layout == 'home' || layout == 'industrial') _exitLayout = layout!;
    } catch (_) {
      // Non-fatal: fall back to the compile-time default.
    }
  }

  /// Persist a new base URL at runtime (the demo settings field).
  static Future<void> setBaseUrl(String url) async {
    _baseUrl = _normalise(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _baseUrl);
  }

  /// This device's FCM token, cached so the **background isolate** can reach it.
  ///
  /// A push that arrives while the app is terminated is handled in a separate
  /// isolate with none of `main()`'s state — no repository, no Firebase, no
  /// loaded config. That is also the case where delivery timing matters most,
  /// because it is the one a sleeping person actually experiences. Persisting
  /// the token is what lets that isolate acknowledge the push at all.
  static Future<void> saveDeviceToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {
      // Non-fatal: only the background acknowledgement is lost.
    }
  }

  static Future<String?> deviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Which building's escape-route layout to draw: `industrial` or `home`.
  ///
  /// DELIBERATELY A LOCAL SETTING, NOT ONE THE BACKEND SUPPLIES. The dashboard
  /// has its own switch for what counts as a fire; this one chooses which floor
  /// plan the phone draws. They are set independently and neither reads the
  /// other, so a phone can be pointed at a different layout without touching the
  /// server, and a server restart cannot silently change what a responder sees.
  ///
  /// Defaults to `home`, the trial facility, which is also what a phone with no
  /// stored preference and no backend shows. The backend defaults to the same
  /// site, so the two agree before anyone changes either one.
  static String _exitLayout = 'home';

  static String get exitLayout => _exitLayout;

  static Future<void> setExitLayout(String key) async {
    _exitLayout = key == 'industrial' ? 'industrial' : 'home';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_layoutKey, _exitLayout);
    } catch (_) {
      // Non-fatal: the choice holds for this run, just not the next one.
    }
  }

  /// Build a request URI for a backend path like `/api/state`.
  static Uri api(String path) => Uri.parse('$_baseUrl$path');

  static String _normalise(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
