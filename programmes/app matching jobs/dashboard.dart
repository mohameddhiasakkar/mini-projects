import 'dart:async';
import 'package:flutter/material.dart';
import 'matching_page.dart';
import 'matches_page.dart';
import 'candidat.dart';
import 'Employer.dart';
import '../services/session_service.dart';
import '../services/likes_service.dart';
import '../services/database_service.dart';
import '../widgets/profile_photo_widget.dart';
import 'HomeScreen.dart';
import 'chat_screen.dart';
import '../models/user_model.dart'; // Add import for Match class
import 'profile_view_page.dart'; // Add import for ProfileViewPage
import 'conversation_list_page.dart'; // Add import for ConversationListPage
import '../services/api_service.dart'; // Add import for ApiService
// import 'cv_matching_page.dart'; // disabled for candidates

class Dashboard extends StatefulWidget {
  final String userRole;
  final String userId;

  const Dashboard({
    Key? key,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  int _totalLikes = 30; // Default likes count
  int _totalMatches = 0;
  List<Match> _matches = []; // Add matches list to store match data

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // Refresh data periodically to keep likes count updated
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadDashboardData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      print('Dashboard: Loading data for user: ${widget.userId}');
      final likes = await LikesService.getTotalLikes();
      print('Dashboard: Loaded likes: $likes');

      final matches = await DatabaseService.getMatchesForUser(widget.userId);
      print('Dashboard: Loaded ${matches.length} matches');

      setState(() {
        _totalLikes = likes;
        _totalMatches = matches.length;
        _matches = matches; // Store the matches data
      });
    } catch (e) {
      print('Dashboard: Error loading dashboard data: $e');
    }
  }

  void _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // Logout from backend
        await ApiService.logout();
      } catch (e) {
        print('Backend logout failed: $e');
      } finally {
        // Clear session locally
        await SessionService.clearSession();
      }

      if (mounted) {
        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cream = Color(0xFFF5EFE6);
    const Color darkCoffee = Color(0xFF4B2E2A);

    return Scaffold(
      backgroundColor: cream,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Matching Page
          MatchingPage(
            userRole: widget.userRole,
            userId: widget.userId,
          ),
          // Matches Page
          MatchesPage(
            userRole: widget.userRole,
            userId: widget.userId,
          ),
          // Profile Page
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Connection status indicator
            FutureBuilder<String>(
              future: Future.value(ApiService.getConnectionStatusMessage()),
              builder: (context, snapshot) {
                final message = snapshot.data ?? 'Checking connection...';
                final isOffline = message.contains('offline');

                if (isOffline) {
                  return Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.orange,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          message,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
                // Refresh data when switching to profile tab
                if (index == 2) {
                  _loadDashboardData();
                }
              },
              backgroundColor: Colors.white,
              selectedItemColor: darkCoffee,
              unselectedItemColor: Colors.grey[600],
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    _currentIndex == 0 ? Icons.swipe : Icons.swipe_outlined,
                  ),
                  label: widget.userRole == 'candidate'
                      ? 'Find Jobs'
                      : 'Find Candidates',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    _currentIndex == 1 ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: 'Matches',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    _currentIndex == 2 ? Icons.person : Icons.person_outline,
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B2E2A),
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header with Logo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Image
                    ProfilePhotoWidget(
                      userId: widget.userId,
                      size: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.userRole == 'candidate'
                          ? 'Candidate Profile'
                          : 'Employer Profile',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2F2F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your profile and preferences',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Actions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2F2F),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Edit Profile Button
                    _buildActionButton(
                      icon: Icons.edit,
                      title: 'Edit Profile',
                      subtitle: 'Update your information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => widget.userRole == 'candidate'
                                ? const CandidatePage()
                                : const EmployerPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Settings Button
                    _buildActionButton(
                      icon: Icons.settings,
                      title: 'Settings',
                      subtitle: 'Manage app preferences',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Settings coming soon!')),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Messages Button
                    _buildActionButton(
                      icon: Icons.message,
                      title: 'Messages',
                      subtitle: 'Chat with employers and candidates',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConversationListPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // CV Matching button hidden for candidates per requirement
                    if (widget.userRole != 'candidate') ...[
                      _buildActionButton(
                        icon: Icons.assignment,
                        title: 'CV Matching',
                        subtitle: 'Match candidates by required skills',
                        onTap: () {
                          // Intentionally disabled for candidates
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Likes Demo Button
                    _buildActionButton(
                      icon: Icons.favorite,
                      title: 'Likes Demo',
                      subtitle: 'Test the like functionality',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Notifications'),
                                backgroundColor: const Color(0xFF4B2E2A),
                                foregroundColor: Colors.white,
                              ),
                              body: const Center(
                                child: Text(
                                  'Notifications will appear here',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Statistics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F2F2F),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadDashboardData,
                          tooltip: 'Refresh Statistics',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.favorite,
                            title: 'Likes Remaining',
                            value: '$_totalLikes',
                            color: _totalLikes > 10
                                ? Colors.red
                                : (_totalLikes > 5
                                    ? Colors.orange
                                    : Colors.red[300]!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.swipe,
                            title: 'Matches',
                            value: '$_totalMatches',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Like Management Section
                    if (_totalLikes <= 5) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You\'re running low on likes! Only $_totalLikes remaining.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Reset Likes Button (for testing)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await LikesService.resetLikes();
                          await _loadDashboardData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Likes reset to 30!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Likes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B2E2A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Matches Section
              if (_matches.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Matches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F2F2F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(_matches
                          .take(3)
                          .map((match) => _buildMatchItem(match))),
                      if (_matches.length > 3)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _currentIndex = 1; // Switch to matches tab
                              });
                            },
                            child: Text(
                              'View All ${_matches.length} Matches',
                              style: const TextStyle(
                                color: Color(0xFF4B2E2A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4B2E2A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4B2E2A),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F2F2F),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(Match match) {
    // Determine the name to display based on user role
    String? displayName;
    String? displayRole;
    String userId;

    if (widget.userRole == 'candidate') {
      displayName = match.employerName ?? 'Unknown Employer';
      displayRole = 'Employer';
      userId = match.employerId;
    } else {
      displayName = match.candidateName ?? 'Unknown Candidate';
      displayRole = 'Candidate';
      userId = match.candidateId;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            // Profile photo with profile view navigation
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
                    userId: userId,
                    size: 50,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F2F2F),
                    ),
                  ),
                  Text(
                    displayRole,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Matched ${_getTimeAgo(match.matchedAt)}',
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
                // Chat button
                ElevatedButton(
                  onPressed: () {
                    // Navigate to chat with the matched user
                    String matchUserId = '';
                    String matchUserRole = '';
                    String matchName = '';

                    if (widget.userRole == 'candidate') {
                      matchUserId = match.employerId;
                      matchUserRole = 'employer';
                      matchName = match.employerName ?? 'Unknown Employer';
                    } else {
                      matchUserId = match.candidateId;
                      matchUserRole = 'candidate';
                      matchName = match.candidateName ?? 'Unknown Candidate';
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          matchName: matchName,
                          matchUserId: matchUserId,
                          matchUserRole: matchUserRole,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B2E2A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Chat'),
                ),
                const SizedBox(height: 4),
                // Profile button
                TextButton(
                  onPressed: () {
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
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      color: const Color(0xFF4B2E2A),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
}
