import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class SessionService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isAuthenticatedKey = 'is_authenticated';

  // Save authentication token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isAuthenticatedKey, true);
  }

  // Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save user session
  static Future<void> saveUserSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user data before saving
      if (user.id.isEmpty) {
        throw Exception('Cannot save user session: User ID is empty');
      }
      
      if (user.email.isEmpty) {
        throw Exception('Cannot save user session: User email is empty');
      }
      
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('Error saving user session: $e');
      throw Exception('Failed to save user session: $e');
    }
  }

  // Get user session
  static Future<User?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson);
        if (userMap['role'] == 'candidate') {
          return Candidate.fromJson(userMap);
        } else if (userMap['role'] == 'employer') {
          return Employer.fromJson(userMap);
        }
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }
    return null;
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_isAuthenticatedKey);
  }

  // Get user role
  static Future<String?> getUserRole() async {
    final user = await getUserSession();
    return user?.role;
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final user = await getUserSession();
    return user?.id;
  }

  // Legacy methods for backward compatibility
  static Future<bool> isLoggedIn() async => isAuthenticated();
  static Future<User?> getCurrentUser() async => getUserSession();
} 