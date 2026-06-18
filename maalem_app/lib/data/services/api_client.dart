import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8081';
  static const String _localUrl = 'http://localhost:8081';

  static String get _webUrl {
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    return 'http://$host:8081';
  }

  static String get baseUrl {
    if (kIsWeb) return _webUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorUrl;
    }
    return _localUrl;
  }

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
