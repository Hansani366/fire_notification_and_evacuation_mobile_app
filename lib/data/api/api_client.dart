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

  /// Mark one occupant out of the building.
  ///
  /// The token is what makes the count idempotent: a double tap, a reopened
  /// notification and a retried request are all the same person. Returns the
  /// backend's running total, or null if it did not say.
  Future<int?> checkout(String id, String token) async {
    final res = await _client
        .post(AppConfig.api('/api/incidents/$id/checkout'),
            headers: _jsonHeaders, body: jsonEncode({'token': token}))
        .timeout(_timeout);
    final data = jsonDecode(_ok(res));
    return data is Map && data['checkedOut'] is num
        ? (data['checkedOut'] as num).toInt()
        : null;
  }

  /// Acknowledge that a push arrived, closing the delivery round trip.
  ///
  /// Deliberately short-timeout and fire-and-forget at the call site: this is
  /// instrumentation, and it must never delay showing somebody a fire alert.
  Future<void> reportDelivered(String id, String token, {String? state}) async {
    await _client
        .post(AppConfig.api('/api/incidents/$id/delivered'),
            headers: _jsonHeaders,
            body: jsonEncode({'token': token, 'state': state}))
        .timeout(const Duration(seconds: 5));
  }

  /// The incident record, read after the event rather than during it.
  Future<Map<String, dynamic>> getReport(String id) async => _decodeMap(
      await _client.get(AppConfig.api('/api/incidents/$id/report')).timeout(_timeout));

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
