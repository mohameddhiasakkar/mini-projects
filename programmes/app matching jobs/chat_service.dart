import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/chat_config.dart';

class ChatService {
  static String? _baseUrl;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    for (final base in ChatConfig.allBaseUrls) {
      try {
        // Probe by hitting /chat with a harmless GET (if allowed) or skip to next
        final resp = await http
            .get(Uri.parse(base))
            .timeout(const Duration(seconds: 3));
        if (resp.statusCode >= 200 && resp.statusCode < 500) {
          _baseUrl = base;
          _initialized = true;
          return;
        }
      } catch (_) {
        // try next
      }
    }
    // If none worked, still mark initialized without a base (will error on send)
    _initialized = true;
  }

  static bool get isConfigured => _baseUrl != null;

  static Future<List<String>> sendMessage(String message) async {
    if (!_initialized) {
      await initialize();
    }
    if (_baseUrl == null) {
      throw 'Chat backend not reachable. Start your Flask bridge.';
    }

    final uri = Uri.parse('$_baseUrl/${ChatConfig.chatPath}');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final parsed = jsonDecode(resp.body);
      // Rasa REST returns a list of messages: [{"recipient_id":..., "text": "..."}, ...]
      if (parsed is List) {
        return parsed
            .whereType<Map>()
            .map((m) => (m['text'] ?? '').toString())
            .where((t) => t.isNotEmpty)
            .toList();
      }
      // Flask may wrap differently; try common shapes
      if (parsed is Map && parsed['messages'] is List) {
        return (parsed['messages'] as List)
            .map((e) => e.toString())
            .toList();
      }
      if (parsed is Map && parsed['text'] is String) {
        return [parsed['text'] as String];
      }
      return [];
    }

    throw 'Chat error: ${resp.statusCode} - ${resp.body}';
  }
} 