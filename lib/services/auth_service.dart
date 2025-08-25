// services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _jwtTokenKey = 'jwt_token';
  static const String _userPhoneKey = 'user_phone';
  static const String _userIdKey = 'user_id';

  /// Save JWT token and user info after successful login
  static Future<void> saveAuthData({
    required String jwtToken,
    required String phoneNumber,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jwtTokenKey, jwtToken);
    await prefs.setString(_userPhoneKey, phoneNumber);
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
  }

  /// Get stored JWT token
  static Future<String?> getJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jwtTokenKey);
  }

  /// Get stored user phone number
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Check if user is logged in (has valid JWT token)
  static Future<bool> isLoggedIn() async {
    final token = await getJwtToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all authentication data (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtTokenKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userIdKey);
  }

  /// Get authorization headers for API calls
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getJwtToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
