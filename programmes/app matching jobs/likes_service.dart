import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LikesService {
  static const String _likesKey = 'likes_database';
  static const String _totalLikesKey = 'total_likes_count';

  // Get total likes count
  static Future<int> getTotalLikes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_totalLikesKey) ?? 30; // Default to 30 likes
    } catch (e) {
      print('Error getting total likes: $e');
      return 30;
    }
  }

  // Set total likes count
  static Future<void> setTotalLikes(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_totalLikesKey, count);
    } catch (e) {
      print('Error setting total likes: $e');
    }
  }

  // Decrease likes by 1 (when a message is liked)
  static Future<int> decreaseLikes() async {
    try {
      final currentLikes = await getTotalLikes();
      final newLikes = (currentLikes - 1).clamp(0, double.infinity).toInt();
      await setTotalLikes(newLikes);
      return newLikes;
    } catch (e) {
      print('Error decreasing likes: $e');
      return 0;
    }
  }

  // Increase likes (for testing or admin purposes)
  static Future<int> increaseLikes([int amount = 1]) async {
    try {
      final currentLikes = await getTotalLikes();
      final newLikes = currentLikes + amount;
      await setTotalLikes(newLikes);
      return newLikes;
    } catch (e) {
      print('Error increasing likes: $e');
      return 0;
    }
  }

  // Reset likes to default value
  static Future<void> resetLikes() async {
    try {
      await setTotalLikes(30);
    } catch (e) {
      print('Error resetting likes: $e');
    }
  }

  // Get likes for a specific message
  static Future<List<String>> getLikedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedMessagesJson = prefs.getString(_likesKey);
      
      if (likedMessagesJson != null) {
        try {
          final List<dynamic> likedMessagesList = jsonDecode(likedMessagesJson);
          return likedMessagesList.map((json) => json.toString()).toList();
        } catch (e) {
          print('Error parsing liked messages: $e');
        }
      }
      return [];
    } catch (e) {
      print('Error getting liked messages: $e');
      return [];
    }
  }

  // Like a message
  static Future<bool> likeMessage(String messageId) async {
    try {
      final likedMessages = await getLikedMessages();
      
      // Check if message is already liked
      if (likedMessages.contains(messageId)) {
        return false; // Already liked
      }

      // Check if user has likes remaining
      final totalLikes = await getTotalLikes();
      if (totalLikes <= 0) {
        return false; // No likes remaining
      }

      // Add message to liked messages
      likedMessages.add(messageId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_likesKey, jsonEncode(likedMessages));

      // Decrease total likes
      await decreaseLikes();
      
      return true;
    } catch (e) {
      print('Error liking message: $e');
      return false;
    }
  }

  // Unlike a message
  static Future<bool> unlikeMessage(String messageId) async {
    try {
      final likedMessages = await getLikedMessages();
      
      // Check if message is liked
      if (!likedMessages.contains(messageId)) {
        return false; // Not liked
      }

      // Remove message from liked messages
      likedMessages.remove(messageId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_likesKey, jsonEncode(likedMessages));

      // Increase total likes back
      await increaseLikes();
      
      return true;
    } catch (e) {
      print('Error unliking message: $e');
      return false;
    }
  }

  // Check if a message is liked
  static Future<bool> isMessageLiked(String messageId) async {
    try {
      final likedMessages = await getLikedMessages();
      return likedMessages.contains(messageId);
    } catch (e) {
      print('Error checking if message is liked: $e');
      return false;
    }
  }
}
