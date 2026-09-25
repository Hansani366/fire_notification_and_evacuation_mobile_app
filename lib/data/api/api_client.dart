import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

/// Thin HTTP wrapper over the `alert-service` REST API. Talks plain JSON to the
/// backend origin configured in [AppConfig].
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 10);
  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> getState() async =>
      _decodeMap(await _client.get(AppConfig.api('/api/state')).timeout(_timeout));

  /// Which site the backend is routing for, and in what coordinate space.
  /// Not geometry — the app carries its own drawings; this says which to use.
  Future<Map<String, dynamic>> getSitePlan() async =>
      _decodeMap(await _client.get(AppConfig.api('/api/site/plan')).timeout(_timeout));

  Future<Map<String, dynamic>> getIncident(String id) async =>
      _decodeMap(await _client.get(AppConfig.api('/api/incidents/$id')).timeout(_timeout));

  Future<List<dynamic>> getHistory() async {
    final res = await _client.get(AppConfig.api('/api/history')).timeout(_timeout);
    final body = _ok(res);
    final data = jsonDecode(body);
    return data is List ? data : const [];
  }

  Future<void> registerDevice(String token, {String platform = 'android', String? label}) async {
    final res = await _client
        .post(AppConfig.api('/api/devices'),
            headers: _jsonHeaders,
            body: jsonEncode({'token': token, 'platform': platform, 'label': label}))
        .timeout(_timeout);
    _ok(res);
  }

  Future<void> ackIncident(String id) async {
    final res = await _client
        .post(AppConfig.api('/api/incidents/$id/ack'), headers: _jsonHeaders)
        .timeout(_timeout);
    _ok(res);
  }

  /// Fire a demo alert without a real flame (calls the backend's test hook).
  Future<void> testAlert({String? zoneId}) async {
    final res = await _client
        .post(AppConfig.api('/api/test-alert'),
            headers: _jsonHeaders, body: jsonEncode({'zoneId': zoneId}))
        .timeout(_timeout);
    _ok(res);
  }

  String _ok(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return res.body;
    throw ApiException(res.statusCode, res.body);
  }

  Map<String, dynamic> _decodeMap(http.Response res) {
    final data = jsonDecode(_ok(res));
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'ApiException($statusCode): $body';
}
