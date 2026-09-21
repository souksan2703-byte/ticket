import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://gateway.ltcdev.la/WhatApp/api';

  static Uri url(String path) => Uri.parse('$baseUrl/$path');

  static bool isSuccess(dynamic status) {
    if (status == true || status == 1) return true;
    if (status is String) return status.toLowerCase() == 'true';
    return false;
  }

  static Map<String, dynamic>? parseDataMap(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Normalize QR/barcode value into a clean tranid for the API.
  static String normalizeTranId(String raw) {
    var value = raw.trim();

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasQuery) {
      final fromQuery = uri.queryParameters['tranid'] ??
          uri.queryParameters['TranId'] ??
          uri.queryParameters['id'];
      if (fromQuery != null && fromQuery.trim().isNotEmpty) {
        return fromQuery.trim();
      }
    }

    if (value.startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          final id =
              decoded['tranid'] ?? decoded['TranId'] ?? decoded['ລະຫັດບັດ'];
          if (id != null) return id.toString().trim();
        }
      } catch (_) {}
    }

    return value;
  }

  /// Matches `curl --data ''` for endpoints that expect an empty POST body.
  static Future<http.Response> postEmpty(String path) {
    return http.post(url(path), body: '');
  }

  static Future<http.Response> postJson(
    String path,
    Map<String, dynamic> data,
  ) {
    final payload = Map<String, dynamic>.from(data);
    if (payload['tranid'] is String) {
      payload['tranid'] = normalizeTranId(payload['tranid'] as String);
    }

    return http.post(
      url(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }
}
