import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'session_service.dart';

class DatabaseService {
  static const String _candidatesKey = 'candidates_database';
  static const String _jobOffersKey = 'job_offers_database';
  static const String _matchesKey = 'matches_database';
  static const String _messagesKey = 'messages_database';
  // Note: This service uses ApiService for backend calls, which handles URL construction

  // Helper method to convert role names to short database-compatible values
  static String _getShortRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return 'u';
      case 'employer':
        return 'e';
      case 'ai':
        return 'a';
      case 'candidate':
        return 'c';
      default:
        return 'u'; // Default to 'u' for unknown roles
    }
  }

  // Save a candidate to the database
  static Future<void> saveCandidate(Candidate candidate) async {
    try {
      // Try to save to backend first
      try {
        final token = await SessionService.getToken();
        if (token == null) {
          // No auth token, save locally only
          await _saveCandidateLocally(candidate);
          return;
        }
        await ApiService.updateProfile(candidate.toJson());
        // If successful, also save locally as cache
        await _saveCandidateLocally(candidate);
      } catch (e) {
        print('Backend save failed, saving locally: $e');
        await _saveCandidateLocally(candidate);
      }
    } catch (e) {
      print('Error saving candidate: $e');
      rethrow;
    }
  }

  // Local save method
  static Future<void> _saveCandidateLocally(Candidate candidate) async {
    final prefs = await SharedPreferences.getInstance();
    final candidates = await getAllCandidates();

    // Check if candidate already exists
    final existingIndex = candidates.indexWhere((c) => c.id == candidate.id);
    if (existingIndex != -1) {
      candidates[existingIndex] = candidate;
    } else {
      candidates.add(candidate);
    }

    final candidatesJson = candidates.map((c) => c.toJson()).toList();
    await prefs.setString(_candidatesKey, jsonEncode(candidatesJson));
  }

  // Get all candidates from the database
  static Future<List<Candidate>> getAllCandidates() async {
    try {
      // Try to get from backend first
      try {
        final candidates = await ApiService.getCandidatesForMatching();
        // Cache the results locally
        await _cacheCandidatesLocally(candidates);
        return candidates;
      } catch (e) {
        print('Backend fetch failed, using local cache: $e');
        return await _getCandidatesLocally();
      }
    } catch (e) {
      print('Error getting candidates: $e');
      return [];
    }
  }

  // Local get method
  static Future<List<Candidate>> _getCandidatesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final candidatesJson = prefs.getString(_candidatesKey);

    if (candidatesJson != null) {
      try {
        final List<dynamic> candidatesList = jsonDecode(candidatesJson);
        return candidatesList.map((json) => Candidate.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing candidates: $e');
      }
    }
    return [];
  }

  // Cache candidates locally
  static Future<void> _cacheCandidatesLocally(
      List<Candidate> candidates) async {
    final prefs = await SharedPreferences.getInstance();
    final candidatesJson = candidates.map((c) => c.toJson()).toList();
    await prefs.setString(_candidatesKey, jsonEncode(candidatesJson));
  }

  // Get candidates excluding the current user
  static Future<List<Candidate>> getCandidatesForMatching(
      String currentUserId) async {
    try {
      final allCandidates = await getAllCandidates();
      return allCandidates
          .where((candidate) => candidate.id != currentUserId)
          .toList();
    } catch (e) {
      print('Error getting candidates for matching: $e');
      return [];
    }
  }

  // Get employers excluding the current user
  static Future<List<Employer>> getEmployersForMatching(
      String currentUserId) async {
    try {
      // For now, return empty list since we don't have employer data
      // This would need to be implemented with backend support
      return [];
    } catch (e) {
      print('Error getting employers for matching: $e');
      return [];
    }
  }

  // Delete a job offer
  static Future<void> deleteJobOffer(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobOffers = await getAllJobOffers();

      // Remove the job offer
      jobOffers.removeWhere((job) => job.id == jobId);

      // Save updated list
      final jobOffersJson = jobOffers.map((j) => j.toJson()).toList();
      await prefs.setString(_jobOffersKey, jsonEncode(jobOffersJson));
    } catch (e) {
      print('Error deleting job offer: $e');
      rethrow;
    }
  }

  // Save a job offer to the database
  static Future<void> saveJobOffer(JobOffer jobOffer) async {
    try {
      // Try to save to backend first
      try {
        // Note: This would need a backend endpoint for job offers
        await _saveJobOfferLocally(jobOffer);
      } catch (e) {
        print('Backend save failed, saving locally: $e');
        await _saveJobOfferLocally(jobOffer);
      }
    } catch (e) {
      print('Error saving job offer: $e');
      rethrow;
    }
  }

  // Local save method for job offers
  static Future<void> _saveJobOfferLocally(JobOffer jobOffer) async {
    final prefs = await SharedPreferences.getInstance();
    final jobOffers = await getAllJobOffers();

    // Check if job offer already exists
    final existingIndex = jobOffers.indexWhere((j) => j.id == jobOffer.id);
    if (existingIndex != -1) {
      jobOffers[existingIndex] = jobOffer;
    } else {
      jobOffers.add(jobOffer);
    }

    final jobOffersJson = jobOffers.map((j) => j.toJson()).toList();
    await prefs.setString(_jobOffersKey, jsonEncode(jobOffersJson));
  }

  // Get all job offers from the database
  static Future<List<JobOffer>> getAllJobOffers() async {
    try {
      // Try to get from backend first
      try {
        final jobOffers = await ApiService.getJobOffers();
        // Cache the results locally
        await _cacheJobOffersLocally(jobOffers);
        return jobOffers;
      } catch (e) {
        print('Backend fetch failed, using local cache: $e');
        return await _getJobOffersLocally();
      }
    } catch (e) {
      print('Error getting job offers: $e');
      return [];
    }
  }

  // Local get method for job offers
  static Future<List<JobOffer>> _getJobOffersLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final jobOffersJson = prefs.getString(_jobOffersKey);

    if (jobOffersJson != null) {
      try {
        final List<dynamic> jobOffersList = jsonDecode(jobOffersJson);
        return jobOffersList.map((json) => JobOffer.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing job offers: $e');
      }
    }
    return [];
  }

  // Cache job offers locally
  static Future<void> _cacheJobOffersLocally(List<JobOffer> jobOffers) async {
    final prefs = await SharedPreferences.getInstance();
    final jobOffersJson = jobOffers.map((j) => j.toJson()).toList();
    await prefs.setString(_jobOffersKey, jsonEncode(jobOffersJson));
  }

  // Save a match to the database
  static Future<void> saveMatch(Match match) async {
    try {
      // Try to save to backend first
      try {
        await ApiService.createMatch(match.toJson());
        // If successful, also save locally as cache
        await _saveMatchLocally(match);
      } catch (e) {
        print('Backend save failed, saving locally: $e');
        await _saveMatchLocally(match);
      }
    } catch (e) {
      print('Error saving match: $e');
      rethrow;
    }
  }

  // Local save method for matches
  static Future<void> _saveMatchLocally(Match match) async {
    try {
      print('DatabaseService: Saving match locally: ${match.toJson()}');
      final prefs = await SharedPreferences.getInstance();
      final matches = await getAllMatches();
      print('DatabaseService: Current local matches count: ${matches.length}');

      // Check if match already exists
      final existingIndex = matches.indexWhere((m) => m.id == match.id);
      if (existingIndex != -1) {
        print('DatabaseService: Updating existing match');
        matches[existingIndex] = match;
      } else {
        print('DatabaseService: Adding new match');
        matches.add(match);
      }

      final matchesJson = matches.map((m) => m.toJson()).toList();
      await prefs.setString(_matchesKey, jsonEncode(matchesJson));
      print(
          'DatabaseService: Match saved locally successfully. Total matches: ${matches.length}');
    } catch (e) {
      print('DatabaseService: Error saving match locally: $e');
    }
  }

  // Get all matches from the database
  static Future<List<Match>> getAllMatches() async {
    try {
      print('DatabaseService: Getting all matches...');
      // Try to get from backend first
      try {
        final currentUserId = await _getCurrentUserId();
        if (currentUserId != null) {
          print('DatabaseService: Current user ID: $currentUserId');
          final matches = await ApiService.getUserMatches(currentUserId);
          print(
              'DatabaseService: Backend returned ${matches.length} matches for current user');
          // Cache the results locally
          await _cacheMatchesLocally(matches);
          return matches;
        } else {
          print('DatabaseService: No current user ID, using local cache');
          return await _getMatchesLocally();
        }
      } catch (e) {
        print('DatabaseService: Backend fetch failed, using local cache: $e');
        return await _getMatchesLocally();
      }
    } catch (e) {
      print('DatabaseService: Error getting matches: $e');
      return [];
    }
  }

  // Local get method for matches
  static Future<List<Match>> _getMatchesLocally() async {
    try {
      print('DatabaseService: Getting matches from local storage...');
      final prefs = await SharedPreferences.getInstance();
      final matchesJson = prefs.getString(_matchesKey);

      if (matchesJson != null) {
        try {
          final List<dynamic> matchesList = jsonDecode(matchesJson);
          final matches =
              matchesList.map((json) => Match.fromJson(json)).toList();
          print(
              'DatabaseService: Retrieved ${matches.length} matches from local storage');
          return matches;
        } catch (e) {
          print(
              'DatabaseService: Error parsing matches from local storage: $e');
        }
      } else {
        print('DatabaseService: No matches found in local storage');
      }
      return [];
    } catch (e) {
      print('DatabaseService: Error accessing local storage: $e');
      return [];
    }
  }

  // Cache matches locally
  static Future<void> _cacheMatchesLocally(List<Match> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = matches.map((m) => m.toJson()).toList();
    await prefs.setString(_matchesKey, jsonEncode(matchesJson));
  }

  // Get user matches
  static Future<List<Match>> getMatchesForUser(String userId) async {
    try {
      print('DatabaseService: Getting matches for user: $userId');
      // Try to get from backend first
      try {
        final matches = await ApiService.getUserMatches(userId);
        print('DatabaseService: Backend returned ${matches.length} matches');
        // Cache the results locally
        await _cacheMatchesLocally(matches);
        return matches;
      } catch (e) {
        print('DatabaseService: Backend fetch failed, using local cache: $e');
        return await _getMatchesForUserLocally(userId);
      }
    } catch (e) {
      print('DatabaseService: Error getting user matches: $e');
      return [];
    }
  }

  // Local get method for user matches
  static Future<List<Match>> _getMatchesForUserLocally(String userId) async {
    try {
      print(
          'DatabaseService: Getting matches from local cache for user: $userId');
      final allMatches = await _getMatchesLocally();
      print(
          'DatabaseService: Local cache has ${allMatches.length} total matches');
      final userMatches = allMatches
          .where((match) =>
              match.candidateId == userId || match.employerId == userId)
          .toList();
      print(
          'DatabaseService: Found ${userMatches.length} matches for user $userId');
      return userMatches;
    } catch (e) {
      print('DatabaseService: Error getting user matches locally: $e');
      return [];
    }
  }

  // Get current user ID
  static Future<String?> _getCurrentUserId() async {
    try {
      final user = await ApiService.getCurrentUser();
      return user.id;
    } catch (e) {
      return null;
    }
  }

  // Save a message to the database
  static Future<void> saveMessage(Message message) async {
    try {
      // Try to save to backend first
      try {
        final token = await SessionService.getToken();
        if (token == null) {
          // No auth token, save locally only
          await _saveMessageLocally(message);
          return;
        }
        // Skip backend for AI or sample/local-only conversations
        final isAiMessage =
            message.senderRole == 'a' || message.senderRole == 'ai';
        final isSampleIds =
            message.senderId.toLowerCase().startsWith('sample_') ||
                message.receiverId.toLowerCase().startsWith('sample_');
        if (isAiMessage || isSampleIds) {
          await _saveMessageLocally(message);
          return;
        }
        await ApiService.sendMessage({
          'sender_id': message.senderId,
          'receiver_id': message.receiverId,
          'content': message.content,
          'message': message.content, // Some backends validate on 'message'
          'sender_name': message.senderName,
          'sender_role': _getShortRole(message.senderRole),
        });
        // If successful, also save locally as cache
        await _saveMessageLocally(message);
      } catch (e) {
        print('Backend save failed, saving locally: $e');
        await _saveMessageLocally(message);
      }
    } catch (e) {
      print('Error saving message: $e');
      rethrow;
    }
  }

  // Local save method for messages
  static Future<void> _saveMessageLocally(Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final allMessages = await getAllMessages();
    allMessages.add(message);

    final messagesJson = allMessages.map((m) => m.toJson()).toList();
    await prefs.setString(_messagesKey, jsonEncode(messagesJson));
  }

  // Get all messages from the database
  static Future<List<Message>> getAllMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_messagesKey);

      if (messagesJson != null) {
        try {
          final List<dynamic> messagesList = jsonDecode(messagesJson);
          return messagesList.map((json) => Message.fromJson(json)).toList();
        } catch (e) {
          print('Error parsing messages: $e');
        }
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Get conversation between two users
  static Future<List<Message>> getConversation(
      String userId1, String userId2) async {
    try {
      // Try to get from backend first
      try {
        final token = await SessionService.getToken();
        if (token == null) {
          return await _getConversationLocally(userId1, userId2);
        }
        final messages = await ApiService.getConversation(userId1, userId2);
        // Cache the results locally
        await _cacheMessagesLocally(messages);
        return messages;
      } catch (e) {
        print('Backend fetch failed, using local cache: $e');
        return await _getConversationLocally(userId1, userId2);
      }
    } catch (e) {
      print('Error getting conversation: $e');
      return [];
    }
  }

  // Real-time like conversation stream using simple polling
  static Stream<List<Message>> getConversationStream(
      String userId1, String userId2,
      {Duration pollInterval = const Duration(seconds: 2)}) {
    return Stream.periodic(pollInterval)
        .asyncMap((_) => getConversation(userId1, userId2));
  }

  // Local get method for conversations
  static Future<List<Message>> _getConversationLocally(
      String userId1, String userId2) async {
    try {
      final allMessages = await getAllMessages();
      return allMessages
          .where((message) =>
              (message.senderId == userId1 && message.receiverId == userId2) ||
              (message.senderId == userId2 && message.receiverId == userId1))
          .toList();
    } catch (e) {
      print('Error getting conversation locally: $e');
      return [];
    }
  }

  // Cache messages locally
  static Future<void> _cacheMessagesLocally(List<Message> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingMessages = await getAllMessages();

      // Merge with existing messages, avoiding duplicates
      final Map<String, Message> messageMap = {};
      for (final msg in existingMessages) {
        messageMap[msg.id] = msg;
      }
      for (final msg in messages) {
        messageMap[msg.id] = msg;
      }

      final allMessages = messageMap.values.toList();
      final messagesJson = allMessages.map((m) => m.toJson()).toList();
      await prefs.setString(_messagesKey, jsonEncode(messagesJson));
    } catch (e) {
      print('Error caching messages: $e');
    }
  }

  // Get all conversations for a user
  static Future<List<Map<String, dynamic>>> getUserConversations(
      String userId) async {
    try {
      // Try to get from backend first
      try {
        final conversations = await ApiService.getUserConversations(userId);
        return conversations;
      } catch (e) {
        print('Backend fetch failed, using local cache: $e');
        return await _getUserConversationsLocally(userId);
      }
    } catch (e) {
      print('Error getting user conversations: $e');
      return [];
    }
  }

  // Local get method for user conversations
  static Future<List<Map<String, dynamic>>> _getUserConversationsLocally(
      String userId) async {
    try {
      final allMessages = await getAllMessages();
      final Map<String, List<Message>> conversations = {};

      // Group messages by conversation partner
      for (final message in allMessages) {
        String partnerId;
        if (message.senderId == userId) {
          partnerId = message.receiverId;
        } else if (message.receiverId == userId) {
          partnerId = message.senderId;
        } else {
          continue;
        }

        if (!conversations.containsKey(partnerId)) {
          conversations[partnerId] = [];
        }
        conversations[partnerId]!.add(message);
      }

      // Convert to list of conversation summaries
      final List<Map<String, dynamic>> conversationSummaries = [];
      for (final entry in conversations.entries) {
        final partnerId = entry.key;
        final messages = entry.value;
        messages.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

        final lastMessage = messages.first;
        final unreadCount =
            messages.where((m) => !m.isRead && m.senderId != userId).length;

        // Get partner name
        String partnerName = 'Unknown';
        String partnerRole = 'unknown';

        try {
          final candidate = await getCandidateById(partnerId);
          if (candidate != null) {
            partnerName = candidate.name;
            partnerRole = 'candidate';
          } else {
            final employer = await getEmployerById(partnerId);
            if (employer != null) {
              partnerName = employer.name;
              partnerRole = 'employer';
            }
          }
        } catch (e) {
          print('Error getting partner info: $e');
        }

        conversationSummaries.add({
          'partnerId': partnerId,
          'partnerName': partnerName,
          'partnerRole': partnerRole,
          'lastMessage': lastMessage.content,
          'lastMessageTime': lastMessage.timestamp,
          'unreadCount': unreadCount,
        });
      }

      // Sort by most recent message
      conversationSummaries.sort((a, b) => (b['lastMessageTime'] as DateTime)
          .compareTo(a['lastMessageTime'] as DateTime));

      return conversationSummaries;
    } catch (e) {
      print('Error getting user conversations: $e');
      return [];
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(
      String senderId, String receiverId) async {
    try {
      // Try to mark as read on backend first
      try {
        final token = await SessionService.getToken();
        if (token != null) {
          await ApiService.markMessagesAsRead(senderId, receiverId);
        }
      } catch (e) {
        print('Backend mark as read failed: $e');
      }

      // Also mark locally
      await _markMessagesAsReadLocally(senderId, receiverId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Local mark as read method
  static Future<void> _markMessagesAsReadLocally(
      String senderId, String receiverId) async {
    try {
      final allMessages = await getAllMessages();
      bool hasChanges = false;

      for (int i = 0; i < allMessages.length; i++) {
        if (allMessages[i].senderId == senderId &&
            allMessages[i].receiverId == receiverId &&
            !allMessages[i].isRead) {
          allMessages[i] = allMessages[i].copyWith(isRead: true);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        final prefs = await SharedPreferences.getInstance();
        final messagesJson = allMessages.map((m) => m.toJson()).toList();
        await prefs.setString(_messagesKey, jsonEncode(messagesJson));
      }
    } catch (e) {
      print('Error marking messages as read locally: $e');
    }
  }

  // Get candidate by ID
  static Future<Candidate?> getCandidateById(String id) async {
    try {
      final candidates = await getAllCandidates();
      return candidates.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get employer by ID
  static Future<Employer?> getEmployerById(String id) async {
    try {
      // This would need to be implemented with backend support
      // For now, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear all data (for testing)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_candidatesKey);
      await prefs.remove(_jobOffersKey);
      await prefs.remove(_matchesKey);
      await prefs.remove(_messagesKey);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Add some sample data for testing
  static Future<void> addSampleData() async {
    try {
      // Add sample candidates
      final sampleCandidates = [
        Candidate(
          id: 'sample_candidate_1',
          name: 'Sarah Johnson',
          email: 'sarah.johnson@email.com',
          role: 'candidate',
          jobTitle: 'Senior Flutter Developer',
          country: 'United States',
          skills: ['Flutter', 'Dart', 'Firebase', 'Git', 'REST APIs'],
          profileSummary:
              'Passionate mobile developer with 5+ years of experience building beautiful and functional apps.',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Candidate(
          id: 'sample_candidate_2',
          name: 'Michael Chen',
          email: 'michael.chen@email.com',
          role: 'candidate',
          jobTitle: 'UI/UX Designer',
          country: 'Canada',
          skills: [
            'Figma',
            'Adobe Creative Suite',
            'Prototyping',
            'User Research',
            'Design Systems'
          ],
          profileSummary:
              'Creative designer focused on creating user-centered experiences that solve real problems.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Candidate(
          id: 'sample_candidate_3',
          name: 'Emily Rodriguez',
          email: 'emily.rodriguez@email.com',
          role: 'candidate',
          jobTitle: 'Backend Developer',
          country: 'Spain',
          skills: ['Node.js', 'MongoDB', 'Express', 'AWS', 'Docker'],
          profileSummary:
              'Backend specialist with expertise in building scalable and maintainable server-side applications.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      for (final candidate in sampleCandidates) {
        await saveCandidate(candidate);
      }

      // Add sample job offers
      final sampleJobOffers = [
        JobOffer(
          id: 'sample_job_1',
          title: 'Senior Flutter Developer',
          description:
              'We are looking for an experienced Flutter developer to join our team. You will be responsible for developing and maintaining mobile applications.',
          skillsRequired: ['Flutter', 'Dart', 'Firebase', 'Git'],
          location: 'New York, NY',
          salary: '\$80,000 - \$120,000',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        JobOffer(
          id: 'sample_job_2',
          title: 'UI/UX Designer',
          description:
              'Creative designer needed to create beautiful and intuitive user interfaces for our mobile and web applications.',
          skillsRequired: [
            'Figma',
            'Adobe Creative Suite',
            'Prototyping',
            'User Research'
          ],
          location: 'San Francisco, CA',
          salary: '\$70,000 - \$100,000',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      for (final jobOffer in sampleJobOffers) {
        await saveJobOffer(jobOffer);
      }

      // Add sample messages for conversations
      final sampleMessages = [
        Message(
          id: 'msg_1',
          senderId: 'sample_candidate_1',
          receiverId: 'employer_1',
          content:
              'Hi! I saw your job posting for Senior Flutter Developer. I have 5+ years of experience with Flutter and would love to discuss this opportunity.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          senderName: 'Sarah Johnson',
          senderRole: _getShortRole('candidate'),
        ),
        Message(
          id: 'msg_2',
          senderId: 'employer_1',
          receiverId: 'sample_candidate_1',
          content:
              'Hello Sarah! Thanks for reaching out. Your experience looks great. Can you tell me more about your recent Flutter projects?',
          timestamp:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
          senderName: 'John Smith',
          senderRole: _getShortRole('employer'),
        ),
        Message(
          id: 'msg_3',
          senderId: 'sample_candidate_1',
          receiverId: 'employer_1',
          content:
              'Of course! I recently built a full-stack e-commerce app with Flutter and Firebase. It handles user authentication, real-time inventory, and payment processing.',
          timestamp:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          senderName: 'Sarah Johnson',
          senderRole: _getShortRole('candidate'),
        ),
        Message(
          id: 'msg_4',
          senderId: 'employer_1',
          receiverId: 'sample_candidate_1',
          content:
              'That sounds impressive! Would you be available for a technical interview this week?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          senderName: 'John Smith',
          senderRole: _getShortRole('employer'),
        ),
        Message(
          id: 'msg_5',
          senderId: 'sample_candidate_2',
          receiverId: 'employer_2',
          content:
              'Hi Sarah! I\'m interested in your UI/UX Designer position. I have experience with Figma and user research.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          senderName: 'Michael Chen',
          senderRole: _getShortRole('candidate'),
        ),
        Message(
          id: 'msg_6',
          senderId: 'employer_2',
          receiverId: 'sample_candidate_2',
          content:
              'Hello Michael! Thanks for your interest. Can you share your portfolio?',
          timestamp: DateTime.now().subtract(const Duration(hours: 23)),
          senderName: 'Sarah Johnson',
          senderRole: _getShortRole('employer'),
        ),
      ];

      for (final message in sampleMessages) {
        await saveMessage(message);
      }

      print('Sample data added successfully');
    } catch (e) {
      print('Error adding sample data: $e');
    }
  }
}
