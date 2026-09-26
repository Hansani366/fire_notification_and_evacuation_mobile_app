import 'package:shared_preferences/shared_preferences.dart';

/// Where the app finds the `alert-service` backend.
///
/// A phone must reach the server by its **LAN IP**, never `localhost`, so the
/// address is passed in at build time:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8090
/// ```
///
/// with `10.0.2.2` (the host loopback as seen from the Android emulator) as the
/// fallback when nothing is given.
///
/// THE BUILD IS THE ONLY PLACE THE ADDRESS COMES FROM, ON PURPOSE. There used to
/// be an in-app override, saved to shared_preferences and reachable by
/// long-pressing the dashboard title, and it took precedence over the compiled
/// value. That meant an address typed in weeks earlier could silently outrank
/// the one the APK was built with, and an APK built against the right server
/// would talk to the wrong one with nothing on screen to say so. An installed
/// build now points where it was built to point, which is also what makes a
/// trial run reproducible: the address is a property of the artefact, recorded
/// by whoever built it, not a hidden per-handset setting.
class AppConfig {
  AppConfig._();

  static const String _tokenKey = 'fcm_token';

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8090',
  );

  /// Backend origin, e.g. `http://192.168.1.10:8090` (no trailing slash).
  static final String baseUrl = _normalise(_envBaseUrl);

  /// This device's FCM token, cached so the **background isolate** can reach it.
  ///
  /// A push that arrives while the app is terminated is handled in a separate
  /// isolate with none of `main()`'s state — no repository, no Firebase, no
  /// loaded config. That is also the case where delivery timing matters most,
  /// because it is the one a sleeping person actually experiences. Persisting
  /// the token is what lets that isolate acknowledge the push at all. The base
  /// URL needs no such treatment: it is compiled in, so the isolate already has
  /// it.
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

  /// Build a request URI for a backend path like `/api/state`.
  static Uri api(String path) => Uri.parse('$baseUrl$path');

  static String _normalise(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
