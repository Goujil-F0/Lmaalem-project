import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'auth_user';
  static const String _mockUserKey = 'mock_user_profile';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUser(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userJson);
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  static Future<void> saveMockUser(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mockUserKey, userJson);
  }

  static Future<String?> getMockUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mockUserKey);
  }

static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_mockUserKey);
  }

  static Future<void> clearMockUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mockUserKey);
  }
}
