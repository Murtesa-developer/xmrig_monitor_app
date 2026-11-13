import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:xmrig_monitor/data/models/profile.dart';
import 'package:xmrig_monitor/data/models/summary.dart';

enum ApiErrorKind { unreachable, unauthorized, forbidden, restricted, notFound, badResponse }

class ApiException implements Exception {
  ApiException(this.kind, this.message);
  final ApiErrorKind kind;
  final String message;
  @override
  String toString() => message;
}

/// Thin client for the XMRig HTTP API (doc/API.md in the XMRig repo).
class XmrigApi {
  XmrigApi(this.profile, {http.Client? client}) : _client = client ?? http.Client();

  final MinerProfile profile;
  final http.Client _client;
  static const _timeout = Duration(seconds: 5);

  Future<http.Response> _send(String method, String path, {String? body}) async {
    final req = http.Request(method, profile.uri(path));
    if (profile.hasToken) req.headers['Authorization'] = 'Bearer ${profile.token}';
    if (body != null) {
      // XMRig compares Content-Type to exactly "application/json" and answers
      // 415 otherwise. Setting `req.body` makes package:http append
      // "; charset=utf-8", so send raw bytes instead.
      req.headers['Content-Type'] = 'application/json';
      req.bodyBytes = utf8.encode(body);
    }
    try {
      final streamed = await _client.send(req).timeout(_timeout);
      final res = await http.Response.fromStream(streamed).timeout(_timeout);
      _check(res, write: method != 'GET');
      return res;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(ApiErrorKind.unreachable, 'Timed out reaching ${profile.label}');
    } catch (_) {
      throw ApiException(ApiErrorKind.unreachable, 'Cannot reach ${profile.label}');
    }
  }

  void _check(http.Response r, {required bool write}) {
    final c = r.statusCode;
    if (c >= 200 && c < 300) return;
    switch (c) {
      case 401:
        throw ApiException(ApiErrorKind.unauthorized, 'The miner requires an access token.');
      case 403:
        throw write
            ? ApiException(ApiErrorKind.restricted,
                'Rejected (403): wrong access token, or the miner runs with "restricted": true.')
            : ApiException(ApiErrorKind.forbidden, 'Access token rejected by the miner (403).');
      case 404:
        throw ApiException(ApiErrorKind.notFound, 'Endpoint not found (404).');
      case 415:
        throw ApiException(ApiErrorKind.badResponse, 'Miner rejected the content type (415).');
      default:
        throw ApiException(ApiErrorKind.badResponse, 'Unexpected response from miner ($c).');
    }
  }

  Map<String, dynamic> _json(http.Response r) {
    try {
      final v = jsonDecode(utf8.decode(r.bodyBytes));
      if (v is Map<String, dynamic>) return v;
    } on FormatException {
      // fall through
    }
    throw ApiException(ApiErrorKind.badResponse, 'The miner returned something that is not JSON.');
  }

  Future<Map<String, dynamic>> _getFirst(List<String> paths) async {
    ApiException? last;
    for (final p in paths) {
      try {
        return _json(await _send('GET', p));
      } on ApiException catch (e) {
        if (e.kind != ApiErrorKind.notFound) rethrow;
        last = e;
      }
    }
    throw last!;
  }

  Future<MinerSummary> summary() async => MinerSummary.fromJson(await _getFirst(['/2/summary', '/1/summary']));

  /// Needs an access token and "restricted": false on the miner.
  Future<Map<String, dynamic>> getConfig() => _getFirst(['/1/config', '/2/config']);

  Future<void> putConfig(Map<String, dynamic> config) async {
    await _send('PUT', '/1/config', body: jsonEncode(config));
  }

  void close() => _client.close();
}
