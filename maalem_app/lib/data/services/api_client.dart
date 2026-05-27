import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8081';

  static String get _webUrl {
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    return 'http://$host:8081';
  }

  static String get baseUrl => kIsWeb ? _webUrl : _androidEmulatorUrl;

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
