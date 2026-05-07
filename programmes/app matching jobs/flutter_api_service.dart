import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final List<String> _baseUrls = ApiConfig.allUrls;
  
  static String _currentBaseUrl = _baseUrls[0];
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    for (String url in _baseUrls) {
      try {
        final healthResp = await http
            .get(
              Uri.parse('$url/${ApiConfig.healthEndpoint}'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
        if (healthResp.statusCode == 200) {
          _currentBaseUrl = url;
          _isInitialized = true;
          return;
        }
        // If server responds (even 404/405), consider base reachable
        if (healthResp.statusCode >= 200 && healthResp.statusCode < 500) {
          _currentBaseUrl = url;
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
            _currentBaseUrl = url;
            _isInitialized = true;
            return;
          }
        } catch (_) {
          // continue to next URL
        }
      }
    }

    // If we reached here, no server reachable
    _currentBaseUrl = 'local';
    _isInitialized = true;
  }

  static String get baseUrl => _currentBaseUrl;

  // Check if we're in local mode (no backend server)
  static bool get isLocalMode => _currentBaseUrl == 'local';

  // Generic function to handle HTTP requests
  static Future<Map<String, dynamic>> _handleRequest(
      String method,
      String endpoint,
      Map<String, String>? headers,
      dynamic body,
      ) async {
    
    // If in local mode, return local response
    if (isLocalMode) {
      return _handleLocalRequest(method, endpoint, body);
    }

    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      http.Response response;

      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: jsonEncode(body))
            .timeout(Duration(seconds: ApiConfig.requestTimeoutSeconds));
      } else if (method == 'GET') {
        response = await http.get(uri, headers: headers)
            .timeout(Duration(seconds: ApiConfig.requestTimeoutSeconds));
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: jsonEncode(body))
            .timeout(Duration(seconds: ApiConfig.requestTimeoutSeconds));
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers)
            .timeout(Duration(seconds: ApiConfig.requestTimeoutSeconds));
      } else {
        throw Exception('Invalid HTTP method');
      }

      // Successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _tryDecode(response.body);
      }

      // Error: try to extract message/errors from body
      final parsed = _tryDecode(response.body);
      final message = _extractErrorMessage(parsed) ?? 'Failed with status code: ${response.statusCode}';
      return {
        'success': false,
        'message': message,
        'status': response.statusCode,
        'data': parsed,
      };
    } catch (e) {
      String errorMessage = 'Network error: $e';
      if (e is SocketException) {
        errorMessage = 'Connection failed: Unable to reach the server.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout: Server took too long to respond.';
      }
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    }
  }

  static Map<String, dynamic> _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'raw': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }

  static String? _extractErrorMessage(Map<String, dynamic> parsed) {
    if (parsed['message'] is String) return parsed['message'];
    // Laravel validation errors
    if (parsed['errors'] is Map<String, dynamic>) {
      final errors = parsed['errors'] as Map<String, dynamic>;
      if (errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    return null;
  }

  // Handle requests when in local mode
  static Map<String, dynamic> _handleLocalRequest(String method, String endpoint, dynamic body) {
    switch (endpoint) {
      case 'login':
        return {
          'success': true,
          'message': 'Logged in successfully (local mode)',
          'user': {
            'id': 'local_user_1',
            'name': 'Local User',
            'email': body['email'],
            'role': 'candidate',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          'token': 'local_token_${DateTime.now().millisecondsSinceEpoch}',
        };
      case 'register':
        return {
          'success': true,
          'message': 'Registered successfully (local mode)',
          'user': {
            'id': 'local_user_${DateTime.now().millisecondsSinceEpoch}',
            'name': body['full_name'],
            'email': body['email'],
            'role': body['role'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          'token': 'local_token_${DateTime.now().millisecondsSinceEpoch}',
        };
      default:
        return {
          'success': false,
          'message': 'Endpoint not available in local mode: $endpoint',
        };
    }
  }

  // Public API methods
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String dateOfBirth,
    required String country,
    required String role,
    String? jobTitle,
    String? companyName,
  }) async {
    return await _handleRequest(
      'POST',
      'register',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      {
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
        'country': country,
        'role': role,
        'job_title': jobTitle ?? '',
        'company_name': companyName ?? '',
      },
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _handleRequest(
      'POST',
      'login',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      {
        'email': email,
        'password': password,
      },
    );
  }

  // Add method to check authentication status
  static Future<Map<String, dynamic>> checkAuthStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-auth'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUser(String token) async {
    final response = await _handleRequest(
      'GET',
      'user',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Logout user
  static Future<Map<String, dynamic>> logout(String token) async {
    final response = await _handleRequest(
      'POST',
      'logout',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Get candidate profile
  static Future<Map<String, dynamic>> getCandidateProfile(String token) async {
    final response = await _handleRequest(
      'GET',
      'candidate/profile',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Update candidate profile
  static Future<Map<String, dynamic>> updateCandidateProfile({
    required String token,
    required String fullName,
    required String email,
    required String jobTitle,
    required String country,
    File? cvFile,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/candidate/profile'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields.addAll({
      'full_name': fullName,
      'email': email,
      'job_title': jobTitle,
      'country': country,
    });

    if (cvFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cv_file', cvFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  // Download CV
  static Future<Map<String, dynamic>> downloadCV(String token) async {
    final response = await _handleRequest(
      'GET',
      'candidate/cv/download',
      {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Delete CV
  static Future<Map<String, dynamic>> deleteCV(String token) async {
    final response = await _handleRequest(
      'DELETE',
      'candidate/cv',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Post job offer
  static Future<Map<String, dynamic>> postJobOffer({
    required String token,
    required String title,
    required String description,
    required String skillsRequired,
    required String location,
    double? salaryMin,
    double? salaryMax,
    String? jobType,
    String? experienceLevel,
  }) async {
    final response = await _handleRequest(
      'POST',
      'employer/job-offers',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      {
        'title': title,
        'description': description,
        'skills_required': skillsRequired,
        'location': location,
        'salary_min': salaryMin ?? 0,
        'salary_max': salaryMax ?? 0,
        'job_type': jobType ?? 'full-time',
        'experience_level': experienceLevel ?? 'entry',
      },
    );
    return response;
  }

  // Get my job offers
  static Future<Map<String, dynamic>> getMyJobOffers(String token) async {
    final response = await _handleRequest(
      'GET',
      'employer/job-offers',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Get specific job offer
  static Future<Map<String, dynamic>> getJobOffer(String token, int jobId) async {
    final response = await _handleRequest(
      'GET',
      'employer/job-offers/$jobId',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Update job offer
  static Future<Map<String, dynamic>> updateJobOffer({
    required String token,
    required int jobId,
    required String title,
    required String description,
    required String skillsRequired,
    required String location,
    double? salaryMin,
    double? salaryMax,
    String? jobType,
    String? experienceLevel,
    String? status,
  }) async {
    final response = await _handleRequest(
      'PUT',
      'employer/job-offers/$jobId',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      {
        'title': title,
        'description': description,
        'skills_required': skillsRequired,
        'location': location,
        'salary_min': salaryMin ?? 0,
        'salary_max': salaryMax ?? 0,
        'job_type': jobType ?? 'full-time',
        'experience_level': experienceLevel ?? 'entry',
        'status': status ?? 'active',
      },
    );
    return response;
  }

  // Delete job offer
  static Future<Map<String, dynamic>> deleteJobOffer(String token, int jobId) async {
    final response = await _handleRequest(
      'DELETE',
      'employer/job-offers/$jobId',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      null,
    );
    return response;
  }

  // Match CV (returns score, status, recommendations)
  static Future<Map<String, dynamic>> matchCV({
    required String token,
    required Map<String, dynamic> cvData,
  }) async {
    final response = await _handleRequest(
      'POST',
      'match-cv',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      cvData,
    );
    return response;
  }

  // Chat with AI (Rasa)
  static Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String message,
  }) async {
    final response = await _handleRequest(
      'POST',
      'chat',
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      {
        'message': message,  // Standard key most APIs expect
      },
    );
    return response;
  }
}
