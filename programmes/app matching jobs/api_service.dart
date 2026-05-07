import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'session_service.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class ApiService {
  static String _baseUrl = '';
  static bool _isInitialized = false;
  static String _aiBaseUrl = '';
  static bool _aiInitialized = false;

  // Initialize the service and find the working backend
  static Future<void> initialize() async {
    if (_isInitialized) return;

    for (String url in ApiConfig.allUrls) {
      try {
        final healthResp = await http.get(
          Uri.parse('$url/${ApiConfig.healthEndpoint}'),
          headers: {'Accept': 'application/json'},
        ).timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
        if (healthResp.statusCode == 200) {
          _baseUrl = url;
          _isInitialized = true;
          return;
        }
        // If server responds (even 404/405), consider base reachable
        if (healthResp.statusCode >= 200 && healthResp.statusCode < 500) {
          _baseUrl = url;
          _isInitialized = true;
          return;
        }
      } catch (e) {
        // If network error, try a direct GET to base URL as fallback probe
        try {
          final baseProbe = await http
              .get(Uri.parse(url))
              .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
          if (baseProbe.statusCode >= 200 && baseProbe.statusCode < 500) {
            _baseUrl = url;
            _isInitialized = true;
            return;
          }
        } catch (_) {
          // continue to next URL
        }
      }
    }

    // If we reached here, no server reachable
    _baseUrl = 'local';
    _isInitialized = true;
  }

  // Initialize optional AI base URL separate from main API
  static Future<void> initializeAi() async {
    if (_aiInitialized) return;
    for (String url in ApiConfig.aiUrls) {
      try {
        final healthResp = await http
            .get(Uri.parse('$url/health'))
            .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
        if (healthResp.statusCode >= 200 && healthResp.statusCode < 500) {
          _aiBaseUrl = url;
          _aiInitialized = true;
          return;
        }
      } catch (_) {}
    }
    // Fallback to main base if AI base not found
    await initialize();
    _aiBaseUrl = _baseUrl == 'local' ? '' : _baseUrl;
    _aiInitialized = true;
  }

  // Headers for authenticated requests
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SessionService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With':
          'XMLHttpRequest', // Add this header for Laravel API detection
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper method to convert role names to short database-compatible values
  static String _getShortRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return 'u';
      case 'employer':
        return 'e';
      case 'ai':
        return 'a';
      default:
        return 'u'; // Default to 'u' for unknown roles
    }
  }

  // Generic HTTP request method
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_baseUrl == 'local') {
      throw Exception(
          'No backend server available. Please start your backend server or check the configuration.');
    }

    final url = Uri.parse('$_baseUrl/$endpoint');
    final requestHeaders = await _getHeaders();
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Log the response for debugging
      debugPrint('API Response: ${response.statusCode} - ${response.body}');

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Authentication methods - Use /login endpoint since base URL already includes /api
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      // Use /login endpoint since base URL already includes /api
      final response = await _makeRequest('POST', 'login', body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug logging
        print('Login response received: ${response.body}');
        print('Parsed data: $data');

        // Handle the actual response structure from the backend
        // The backend returns: { success: true, message: "...", user: {...}, token: "..." }
        final responseData = data['success'] == true ? data : data;

        // Validate required fields before proceeding
        if (responseData['token'] == null ||
            responseData['token'].toString().isEmpty) {
          throw Exception('Login response missing authentication token');
        }

        if (responseData['user'] == null) {
          throw Exception('Login response missing user data');
        }

        // Save token and user data
        await SessionService.saveToken(responseData['token']);

        try {
          print('Attempting to parse user data: ${responseData['user']}');
          final user = responseData['user']['role'] == 'candidate'
              ? Candidate.fromJson(responseData['user'])
              : Employer.fromJson(responseData['user']);
          print('User parsed successfully: ${user.toJson()}');
          await SessionService.saveUserSession(user);
        } catch (userError) {
          // If user parsing fails, still save the token but log the error
          print('Warning: Failed to parse user data: $userError');
          print('Raw user data: ${responseData['user']}');
          // Don't throw here as the login was successful
        }

        return responseData;
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ??
            'Login failed with status ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('TypeError: null')) {
        throw Exception(
            'Login failed: Invalid response format from server. Please try again.');
      }
      throw Exception('Login error: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData) async {
    try {
      // Use /register endpoint since base URL already includes /api
      final response = await _makeRequest('POST', 'register', body: userData);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Save token and user data
        if (data['token'] != null) {
          await SessionService.saveToken(data['token']);
        }

        if (data['user'] != null) {
          final user = data['user']['role'] == 'candidate'
              ? Candidate.fromJson(data['user'])
              : Employer.fromJson(data['user']);
          await SessionService.saveUserSession(user);
        }

        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      // Use /logout endpoint since base URL already includes /api
      await _makeRequest('POST', 'logout');
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await SessionService.clearSession();
    }
  }

  // User management methods
  static Future<User> getCurrentUser() async {
    try {
      // Use /profile endpoint since server has /api/profile
      final response = await _makeRequest('GET', 'profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['role'] == 'candidate'
            ? Candidate.fromJson(data)
            : Employer.fromJson(data);
        await SessionService.saveUserSession(user);
        return user;
      } else {
        throw Exception('Failed to get user profile');
      }
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  static Future<User> updateProfile(Map<String, dynamic> profileData) async {
    try {
      // Use /profile endpoint since base URL already includes /api
      final response = await _makeRequest('PUT', 'profile', body: profileData);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['role'] == 'candidate'
            ? Candidate.fromJson(data)
            : Employer.fromJson(data);
        await SessionService.saveUserSession(user);
        return user;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Profile update failed');
      }
    } catch (e) {
      throw Exception('Profile update error: $e');
    }
  }

  // Messaging methods - Use /messages endpoint since server has /api/messages
  static Future<Message> sendMessage(Map<String, dynamic> messageData) async {
    try {
      // Some backends expect 'message' as the key; include both for compatibility
      final payload = {
        ...messageData,
        if (!messageData.containsKey('message'))
          'message': messageData['content'],
      };
      final response = await _makeRequest('POST', 'messages', body: payload);

      if (response.statusCode == 201) {
        final payload = jsonDecode(response.body);
        final msgJson = (payload['data'] ?? payload['message'] ?? payload);
        return Message.fromJson(msgJson);
      } else {
        try {
          final error = jsonDecode(response.body);
          final details =
              error['errors'] ?? error['detail'] ?? error['message'];
          throw Exception(details ??
              'Failed to send message (HTTP ${response.statusCode})');
        } catch (_) {
          throw Exception(
              'Failed to send message (HTTP ${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Send message error: $e');
    }
  }

  static Future<List<Message>> getConversation(
      String userId1, String userId2) async {
    try {
      final response =
          await _makeRequest('GET', 'messages/conversation/$userId1/$userId2');

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final messages = (payload['data'] ?? payload['messages'] ?? []) as List;
        return messages.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get conversation');
      }
    } catch (e) {
      throw Exception('Get conversation error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserConversations(
      String userId) async {
    try {
      final response =
          await _makeRequest('GET', 'messages/conversations/$userId');

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final list =
            (payload['data'] ?? payload['conversations'] ?? []) as List;
        return List<Map<String, dynamic>>.from(list);
      } else {
        throw Exception('Failed to get user conversations');
      }
    } catch (e) {
      throw Exception('Get conversations error: $e');
    }
  }

  static Future<void> markMessagesAsRead(
      String senderId, String receiverId) async {
    try {
      await _makeRequest('POST', 'messages/mark-read', body: {
        'sender_id': senderId,
        'receiver_id': receiverId,
      });
    } catch (e) {
      throw Exception('Mark messages as read error: $e');
    }
  }

  // Matching methods - Use /candidates endpoint since server has /api/candidates
  static Future<List<Candidate>> getCandidatesForMatching() async {
    try {
      final response = await _makeRequest('GET', 'candidates');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        return candidates.map((json) => Candidate.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get candidates');
      }
    } catch (e) {
      throw Exception('Get candidates error: $e');
    }
  }

  static Future<List<JobOffer>> getJobOffers() async {
    try {
      final response = await _makeRequest('GET', 'job-offers');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobOffers = data['job_offers'] as List;
        return jobOffers.map((json) => JobOffer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get job offers');
      }
    } catch (e) {
      throw Exception('Get job offers error: $e');
    }
  }

  static Future<Match> createMatch(Map<String, dynamic> matchData) async {
    try {
      final response = await _makeRequest('POST', 'matches', body: matchData);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Match.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create match');
      }
    } catch (e) {
      throw Exception('Create match error: $e');
    }
  }

  static Future<List<Match>> getUserMatches(String userId) async {
    try {
      final response = await _makeRequest('GET', 'matches/user/$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = data['matches'] as List;
        return matches.map((json) => Match.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get user matches');
      }
    } catch (e) {
      throw Exception('Get matches error: $e');
    }
  }

  // Check API health
  static Future<bool> checkApiHealth() async {
    try {
      await initialize();
      return _baseUrl != 'local';
    } catch (e) {
      return false;
    }
  }

  // Set offline mode
  static void setOfflineMode(bool offline) {
    if (offline) {
      _baseUrl = 'local';
      _isInitialized = true;
    }
  }

  // Get connection status message
  static String getConnectionStatusMessage() {
    if (_baseUrl == 'local') {
      return 'Working in offline mode. Some features may be limited.';
    }
    return 'Connected to backend server.';
  }

  // AI chatbot
  static Future<String> sendAiMessage(String message) async {
    try {
      await initializeAi();
      if (_aiBaseUrl.isNotEmpty && _aiBaseUrl != 'local') {
        final url = Uri.parse('$_aiBaseUrl/ai/chat');
        debugPrint('Trying AI service at: $url');
        try {
          final response = await http.post(
            url,
            headers: await _getHeaders(),
            body: jsonEncode({'message': message}),
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic>) {
              if (data['response'] is String &&
                  (data['response'] as String).isNotEmpty) {
                return data['response'];
              }
              if (data['text'] is String &&
                  (data['text'] as String).isNotEmpty) {
                return data['text'];
              }
            }
            return '';
          }
          // Return richer error details
          try {
            final body = response.body;
            throw Exception(
                'AI chat failed: ${response.statusCode} ${body.isNotEmpty ? '- ' + body : ''}');
          } catch (_) {
            throw Exception('AI chat failed: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('AI service connection failed: $e');
          // Fall through to Laravel endpoint
        }
        // If non-200, fall through to Laravel endpoint
      }

      final response = await _makeRequest('POST', 'ai/chat', body: {
        'message': message,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['response'] is String &&
              (data['response'] as String).isNotEmpty) {
            return data['response'];
          }
          if (data['text'] is String && (data['text'] as String).isNotEmpty) {
            return data['text'];
          }
        }
        return '';
      } else {
        // Show the exact backend error
        try {
          final errorBody = response.body;
          if (errorBody.isNotEmpty) {
            final errorData = jsonDecode(errorBody);
            final errorMessage = errorData['message'] ??
                errorData['error'] ??
                errorData['detail'] ??
                errorBody;
            throw Exception(
                'AI chat failed: ${response.statusCode} - $errorMessage');
          } else {
            throw Exception(
                'AI chat failed: ${response.statusCode} - Empty response body');
          }
        } catch (parseError) {
          if (parseError.toString().contains('AI chat failed:')) {
            rethrow;
          }
          throw Exception(
              'AI chat failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('AI chat error: $e');
    }
  }

  // AI chatbot with persistence on backend
  static Future<Map<String, dynamic>> sendAiChat({
    required String senderId,
    required String message,
    String? senderName,
  }) async {
    try {
      await initializeAi();
      if (_aiBaseUrl.isNotEmpty && _aiBaseUrl != 'local') {
        final url = Uri.parse('$_aiBaseUrl/messages/ai-chat');
        debugPrint('Trying AI service at: $url');
        try {
          final response = await http.post(
            url,
            headers: await _getHeaders(),
            body: jsonEncode({
              'sender_id': senderId,
              'message': message,
              if (senderName != null) 'sender_name': senderName,
            }),
          );
          debugPrint(
              'AI service response: ${response.statusCode} - ${response.body}');
          if (response.statusCode == 200 || response.statusCode == 201) {
            final payload = jsonDecode(response.body);
            final data = payload['data'] ?? payload;
            return {
              'user_message': data['user_message'] ?? message,
              'ai_message': data['ai_message'] ?? (data['response'] ?? ''),
            };
          }
          // Return richer error details
          try {
            final body = response.body;
            throw Exception(
                'AI chat failed: ${response.statusCode} ${body.isNotEmpty ? '- ' + body : ''}');
          } catch (_) {
            throw Exception('AI chat failed: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('AI service connection failed: $e');
          // Fall through to Laravel backend
        }
        // Fall back to Laravel
      }

      debugPrint('Falling back to Laravel backend for AI chat');
      final response = await _makeRequest('POST', 'messages/ai-chat', body: {
        'sender_id': senderId,
        'message': message,
        if (senderName != null) 'sender_name': senderName,
      });

      debugPrint(
          'Laravel AI chat response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final data = payload['data'] ?? {};
        return {
          'user_message': data['user_message'],
          'ai_message': data['ai_message'],
        };
      } else {
        // Show the exact backend error
        try {
          final errorBody = response.body;
          if (errorBody.isNotEmpty) {
            final errorData = jsonDecode(errorBody);
            final errorMessage = errorData['message'] ??
                errorData['error'] ??
                errorData['detail'] ??
                errorBody;
            throw Exception(
                'AI chat failed: ${response.statusCode} - $errorMessage');
          } else {
            throw Exception(
                'AI chat failed: ${response.statusCode} - Empty response body');
          }
        } catch (parseError) {
          if (parseError.toString().contains('AI chat failed:')) {
            rethrow;
          }
          throw Exception(
              'AI chat failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('AI chat error: $e');
      throw Exception('AI chat error: $e');
    }
  }
}
