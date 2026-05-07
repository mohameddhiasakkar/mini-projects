import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/likes_service.dart';
import '../widgets/profile_photo_widget.dart';
import 'matching_page.dart';
import 'message_page.dart';

class MatchingPage extends StatefulWidget {
  final String userRole; // 'candidate' or 'employer'
  final String userId;

  const MatchingPage({
    Key? key,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardOpacityAnimation;

  int _currentIndex = 0;
  List<dynamic> _profiles = [];
  List<Match> _matches = []; // Added to store matches
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, bool> _buttonPressed = {
    'like': false,
    'dislike': false,
    'superlike': false,
  };
  int _selectedTabIndex = 0; // 0 for profiles, 1 for matches

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0), end: const Offset(1.5, 0))
            .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));
    _cardOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeIn,
    ));

    _loadProfiles();
    _loadMatches(); // Load existing matches
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (widget.userRole == 'candidate') {
        // Load employers for candidates to match with
        final employers =
            await DatabaseService.getEmployersForMatching(widget.userId);
        _profiles = employers;
      } else {
        // Load candidates for employers to match with (excluding current user)
        final candidates =
            await DatabaseService.getCandidatesForMatching(widget.userId);
        _profiles = candidates;
      }

      setState(() {
        _isLoading = false;
      });

      // Start card animation when profiles are loaded
      if (_profiles.isNotEmpty) {
        _cardAnimationController.forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profiles: $e';
      });
    }
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await DatabaseService.getMatchesForUser(widget.userId);
      setState(() {
        _matches = matches;
      });
    } catch (e) {
      print('Error loading matches: $e');
    }
  }

  void _onLike() async {
    // Check if user has likes remaining
    final remainingLikes = await LikesService.getTotalLikes();
    if (remainingLikes <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No likes remaining!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Animate button
    _animateButton('like');

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Decrease likes count
    await LikesService.decreaseLikes();

    _handleDecision(true);

    // Show simple feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'You liked this profile! (${remainingLikes - 1} likes remaining)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onDislike() async {
    // Animate button
    _animateButton('dislike');

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 300));

    _handleDecision(false);

    // Show simple feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile rejected'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onSuperLike() async {
    // Check if user has likes remaining
    final remainingLikes = await LikesService.getTotalLikes();
    if (remainingLikes <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No likes remaining!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Animate button
    _animateButton('superlike');

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Decrease likes count
    await LikesService.decreaseLikes();

    _handleDecision(true, isSuperLike: true);

    // Show simple feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Super like sent! ⭐⭐⭐ (${remainingLikes - 1} likes remaining)'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _animateButton(String buttonType) {
    setState(() {
      _buttonPressed[buttonType] = true;
    });

    // Reset button state after animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _buttonPressed[buttonType] = false;
        });
      }
    });
  }

  void _animateCard(double direction) {
    _animationController.forward();
  }

  void _handleDecision(bool isLike, {bool isSuperLike = false}) {
    if (_currentIndex < _profiles.length) {
      final profile = _profiles[_currentIndex];

      if (isLike) {
        // Simulate matching logic - super likes have higher chance
        bool isMatch = false;
        if (isSuperLike) {
          // Super like has 80% chance of matching
          isMatch = Random().nextDouble() < 0.8;
        } else {
          // Regular like has 30% chance of matching
          isMatch = Random().nextDouble() < 0.3;
        }

        if (isMatch) {
          _showMatchDialog();

          // Save match to database and add to local matches
          _saveMatch(profile, isSuperLike: isSuperLike);
        } else {
          // Show simple feedback for no match
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isSuperLike
                    ? "Super like sent! Waiting for response... ⭐⭐⭐"
                    : "Like sent! Waiting for response... ⭐"),
                backgroundColor: isSuperLike ? Colors.blue : Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }

      setState(() {
        _currentIndex++;
      });

      _animationController.reset();

      // Animate next card if available
      if (_currentIndex < _profiles.length) {
        _cardAnimationController.reset();
        _cardAnimationController.forward();
      }
    }
  }

  void _saveMatch(dynamic profile, {bool isSuperLike = false}) async {
    try {
      // Get the names for the match
      String candidateName = '';
      String employerName = '';

      if (widget.userRole == 'candidate') {
        // Current user is candidate, profile is employer
        candidateName = 'You'; // Current user
        employerName = profile.companyName ?? 'Unknown Company';
      } else {
        // Current user is employer, profile is candidate
        candidateName = profile.name ?? 'Unknown Candidate';
        employerName = 'Your Company'; // Current user's company
      }

      final match = Match(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        candidateId: widget.userRole == 'candidate'
            ? widget.userId
            : profile.id.toString(),
        employerId: widget.userRole == 'employer'
            ? widget.userId
            : profile.id.toString(),
        jobOfferId:
            null, // We'll add this later when job offers are implemented
        matchedAt: DateTime.now(),
        isActive: true,
        isSuperLike: isSuperLike,
        candidateName: candidateName,
        employerName: employerName,
      );

      print('Creating match: ${match.toJson()}');
      await DatabaseService.saveMatch(match);
      print('Match saved successfully to database');

      // Add the match to the local list
      setState(() {
        _matches.add(match);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match saved successfully! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving match: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save match: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMatchDialog() {
    final profile = _profiles[_currentIndex];

    // Show simple feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("It's a match! 🎉"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 It\'s a Match!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userRole == 'candidate'
                  ? 'You matched with ${profile.companyName ?? 'this company'}!'
                  : 'You matched with ${profile.name ?? 'this candidate'}!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              widget.userRole == 'candidate'
                  ? 'You can now start chatting and learn more about opportunities!'
                  : 'You can now start chatting and learn more about this candidate!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to matches tab
              setState(() {
                _selectedTabIndex = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B2E2A),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Matches'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Matching'),
          backgroundColor: const Color(0xFF4B2E2A),
          foregroundColor: Colors.white,
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Profiles'),
              Tab(icon: Icon(Icons.favorite), text: 'Matches'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Profiles Tab
            _buildProfilesTab(),

            // Matches Tab
            _buildMatchesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.userRole == 'candidate' ? Icons.business : Icons.people,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.userRole == 'candidate'
                  ? 'No companies available'
                  : 'No candidates available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userRole == 'candidate'
                  ? 'Check back later for new company opportunities!'
                  : 'Check back later for new candidate profiles!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_currentIndex >= _profiles.length) {
      return _buildNoMoreProfiles();
    }

    return _buildMatchingInterface();
  }

  Widget _buildMatchesTab() {
    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: _matches.isEmpty
          ? const Center(
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
                    'No matches yet',
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return _buildMatchCard(match);
              },
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
                    ProfilePhotoWidget(
                      userId: widget.userRole == 'candidate'
                          ? match.employerId
                          : match.candidateId,
                      size: 50,
                      showBorder: true,
                      borderColor:
                          match.isSuperLike ? Colors.blue : Colors.green,
                      borderWidth: 2,
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
                      onPressed: () {
                        // Get the match name for the chat
                        String matchName = 'Unknown';
                        String matchUserId = '';
                        String matchUserRole = '';

                        if (widget.userRole == 'candidate' &&
                            match.employerName != null) {
                          matchName = match.employerName!;
                          matchUserId = match.employerId;
                          matchUserRole = 'employer';
                        } else if (widget.userRole == 'employer' &&
                            match.candidateName != null) {
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
                      },
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

  Widget _buildNoMoreProfiles() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.userRole == 'candidate' ? Icons.business : Icons.people,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.userRole == 'candidate'
                ? 'No more companies to show'
                : 'No more candidates to show',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userRole == 'candidate'
                ? 'Check back later for new company opportunities!'
                : 'Check back later for new candidate profiles!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
              _cardAnimationController.forward();
            },
            child: const Text('Start Over'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingInterface() {
    final profile = _profiles[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Match counter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} of ${_profiles.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.userRole == 'candidate'
                      ? 'Swipe to match with companies! 🏢'
                      : 'Swipe to match with candidates! 👥',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                // Add swipe gesture handling
                if (details.delta.dx.abs() > 10) {
                  // Show visual feedback for swipe
                }
              },
              onPanEnd: (details) {
                // Handle swipe gestures
                if (details.velocity.pixelsPerSecond.dx.abs() > 500) {
                  if (details.velocity.pixelsPerSecond.dx > 0) {
                    _onLike();
                  } else {
                    _onDislike();
                  }
                }
              },
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildProfileCard(profile),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic profile) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Opacity(
            opacity: _cardOpacityAnimation.value,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        color: const Color(0xFF4B2E2A),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: widget.userRole == 'candidate'
                            ? Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                ),
                              )
                            : ProfilePhotoWidget(
                                userId: profile.id?.toString(),
                                size: 200,
                                showBorder: false,
                              ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title/Name
                          Text(
                            widget.userRole == 'candidate'
                                ? (profile.companyName ?? 'Company Name')
                                : (profile.name ?? 'No Name'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F2F2F),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Company/Job Title
                          Row(
                            children: [
                              Icon(
                                widget.userRole == 'candidate'
                                    ? Icons.business
                                    : Icons.work,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.userRole == 'candidate'
                                      ? 'Represented by ${profile.name ?? 'Unknown'}'
                                      : (profile.jobTitle ??
                                          'Job title not specified'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Location/Country
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.userRole == 'candidate'
                                    ? (profile.country ??
                                        'Location not specified')
                                    : (profile.country ??
                                        'Location not specified'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Description/Bio
                          Text(
                            widget.userRole == 'candidate'
                                ? (profile.companyDescription ??
                                    'No company description available')
                                : (profile.profileSummary ??
                                    'No bio available'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Skills
                          Text(
                            widget.userRole == 'candidate'
                                ? 'Company Focus:'
                                : 'Skills:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _getSkillsList(profile)
                                .take(4)
                                .map<Widget>((skill) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4B2E2A)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        skill,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4B2E2A),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),

                          // Additional info based on role
                          if (widget.userRole == 'candidate') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.work,
                                  size: 16,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${profile.jobOffersCount} active job offers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // For candidates, show experience level
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Member since ${_formatDate(profile.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _getSkillsList(dynamic profile) {
    if (widget.userRole == 'candidate') {
      // For employers, show company focus areas
      return [
        'Technology',
        'Innovation',
        'Mobile Development',
        'AI Solutions',
        'User Experience',
        'Startup Culture',
      ];
    } else {
      // For candidates, show their skills
      final skills = profile.skills;
      if (skills is List) {
        return skills.map((skill) => skill.toString()).toList();
      }
      return [];
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Dislike button
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scale(_buttonPressed['dislike']! ? 0.9 : 1.0),
          child: GestureDetector(
            onTap: _onDislike,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 35,
              ),
            ),
          ),
        ),

        // Super Like button
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scale(_buttonPressed['superlike']! ? 0.9 : 1.0),
          child: GestureDetector(
            onTap: _onSuperLike,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star,
                color: Colors.blue,
                size: 35,
              ),
            ),
          ),
        ),

        // Like button
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scale(_buttonPressed['like']! ? 0.9 : 1.0),
          child: GestureDetector(
            onTap: _onLike,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.green,
                size: 35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
