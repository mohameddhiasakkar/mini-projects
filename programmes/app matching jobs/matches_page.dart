import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../widgets/profile_photo_widget.dart';
// import 'chat_screen_corrected.dart' as ai_chat_legacy; // removed
import 'chat_screen.dart' as ai_chat;
import 'profile_view_page.dart'; // Added import for ProfileViewPage
import 'message_page.dart'; // Add import for MessagePage
import '../services/database_service.dart'; // Added import for DatabaseService
import '../services/api_service.dart'; // Added import for ApiService
import 'package:shared_preferences/shared_preferences.dart'; // Added import for SharedPreferences

class MatchesPage extends StatefulWidget {
  final String userRole;
  final String userId;

  const MatchesPage({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  List<Match> _matches = [];
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading matches for user: ${widget.userId}');
      // Load real matches from the API
      final matches = await DatabaseService.getMatchesForUser(widget.userId);
      print('Loaded ${matches.length} matches from API');

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading matches: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load matches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testApiConnection() async {
    try {
      print('Testing API connection...');
      final isHealthy = await ApiService.checkApiHealth();
      print('API health check result: $isHealthy');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'API Connection: ${isHealthy ? "Connected" : "Disconnected"}'),
            backgroundColor: isHealthy ? Colors.green : Colors.red,
          ),
        );
      }

      // Also try to get matches directly from API
      if (isHealthy) {
        print('Trying to get matches directly from API...');
        try {
          final matches = await ApiService.getUserMatches(widget.userId);
          print('Direct API call returned ${matches.length} matches');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Direct API: ${matches.length} matches found'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } catch (e) {
          print('Direct API call failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Direct API failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('API test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearLocalCache() async {
    try {
      print('Clearing local matches cache...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('matches_database');
      print('Local cache cleared');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local cache cleared'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Reload matches after clearing cache
      await _loadMatches();
    } catch (e) {
      print('Error clearing cache: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Match> get _filteredMatches {
    switch (_selectedFilter) {
      case 'super_liked':
        return _matches.where((match) => match.isSuperLike).toList();
      case 'active':
        return _matches.where((match) => match.isActive).toList();
      default:
        return _matches;
    }
  }

  void _onMatchTap(Match match) {
    // Get the match name for the chat
    String matchName = 'Unknown';
    String matchUserId = '';
    String matchUserRole = '';

    if (widget.userRole == 'candidate' && match.employerName != null) {
      matchName = match.employerName!;
      matchUserId = match.employerId;
      matchUserRole = 'employer';
    } else if (widget.userRole == 'employer' && match.candidateName != null) {
      matchName = match.candidateName!;
      matchUserId = match.candidateId;
      matchUserRole = 'candidate';
    }

    // Navigate to conversation with matched user
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          partnerId: matchUserId,
          partnerName: matchName,
          partnerRole: matchUserRole,
          currentUserId: widget.userId,
        ),
      ),
    );
  }

  void _onSuperLike(Match match) {
    setState(() {
      // Create a new match with updated super like status
      final index = _matches.indexWhere((m) => m.id == match.id);
      if (index != -1) {
        _matches[index] = match.copyWith(isSuperLike: true);
      }
    });

    // Get the match name for the notification
    String matchName = 'Unknown';
    if (widget.userRole == 'candidate' && match.employerName != null) {
      matchName = match.employerName!;
    } else if (widget.userRole == 'employer' && match.candidateName != null) {
      matchName = match.candidateName!;
    }

    NotificationService().showMatchNotification(
      matchName: matchName,
      message: "Super liked this match! They'll be notified! ⭐",
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches'),
        backgroundColor: const Color(0xFF4B2E2A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'My AI',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ai_chat.ChatScreen(
                    matchName: 'My AI',
                    matchUserId: 'ai_bot',
                    matchUserRole: 'ai',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLocalCache,
            tooltip: 'Clear local cache',
          ),
          IconButton(
            icon: const Icon(Icons.api),
            onPressed: _testApiConnection,
            tooltip: 'Test API connection',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
            tooltip: 'Refresh matches',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMatches();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
          children: [
            // Filter buttons
            Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Active'),
                const SizedBox(width: 8),
                _buildFilterChip('super_liked', 'Super Liked'),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              ))
            else if (_filteredMatches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No matches found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start matching with people to see them here!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._filteredMatches.map(_buildMatchCard),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor: const Color(0xFF4B2E2A),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile photo
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to profile view
                        String matchUserId = '';
                        String matchUserRole = '';

                        if (widget.userRole == 'candidate') {
                          matchUserId = match.employerId;
                          matchUserRole = 'employer';
                        } else {
                          matchUserId = match.candidateId;
                          matchUserRole = 'candidate';
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileViewPage(
                              userId: matchUserId,
                              userRole: matchUserRole,
                              matchName: widget.userRole == 'candidate'
                                  ? match.employerName
                                  : match.candidateName,
                            ),
                          ),
                        );
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Tooltip(
                          message: 'Click to view profile',
                          child: ProfilePhotoWidget(
                            userId: widget.userRole == 'candidate'
                                ? match.employerId
                                : match.candidateId,
                            size: 50,
                            showBorder: true,
                            borderColor:
                                match.isSuperLike ? Colors.blue : Colors.green,
                            borderWidth: 2,
                          ),
                        ),
                      ),
                    ),
                    if (match.isSuperLike)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Match info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.isSuperLike
                            ? '⭐ Super Match!'
                            : ' 💻 It\'s a Match!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matched ${_getTimeAgo(match.matchedAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Super like button
                if (!match.isSuperLike)
                  IconButton(
                    onPressed: () => _onSuperLike(match),
                    icon: const Icon(Icons.star_border, color: Colors.blue),
                    tooltip: 'Super Like',
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Match details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display names instead of IDs
                      if (widget.userRole == 'candidate' &&
                          match.employerName != null)
                        Text(
                          'Employer: ${match.employerName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2F2F2F),
                          ),
                        )
                      else if (widget.userRole == 'employer' &&
                          match.candidateName != null)
                        Text(
                          'Candidate: ${match.candidateName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2F2F2F),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Matched ${_getTimeAgo(match.matchedAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (match.jobOfferId != null)
                        Text(
                          'Job Offer ID: ${match.jobOfferId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _onMatchTap(match),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2E2A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Chat'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
