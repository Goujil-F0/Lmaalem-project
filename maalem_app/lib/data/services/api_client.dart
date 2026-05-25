import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8081';
  static const String _webUrl = 'http://localhost:8081';

  static String get baseUrl => kIsWeb ? _webUrl : _androidEmulatorUrl;

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
