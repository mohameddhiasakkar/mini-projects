import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import 'message_page.dart';
import 'chat_screen.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({Key? key}) : super(key: key);

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  bool _hasAiConversation = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final currentUser = await SessionService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUserId = currentUser.id;
        });

        final conversations =
            await DatabaseService.getUserConversations(currentUser.id);
        final hasAi = conversations.any((c) {
          final pid = (c['partnerId'] ?? c['partner_id'] ?? '').toString();
          final prole =
              (c['partnerRole'] ?? c['partner_role'] ?? '').toString();
          return pid == 'ai_bot' || prole.toLowerCase() == 'ai';
        });
        setState(() {
          _conversations = conversations;
          _isLoading = false;
          _hasAiConversation = hasAi;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

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
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView.builder(
                // Add a pinned AI entry only if backend did not already include one
                itemCount: (_hasAiConversation ? 0 : 1) +
                    _conversations.length +
                    (_conversations.isEmpty && !_hasAiConversation ? 1 : 0),
                itemBuilder: (context, index) {
                  final pinnedCount = _hasAiConversation ? 0 : 1;

                  // Index 0: Pinned AI Assistant chat entry (only if not present in data)
                  if (pinnedCount == 1 && index == 0) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: const Icon(Icons.smart_toy, color: Colors.white),
                      ),
                      title: const Text(
                        'My AI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Ask about jobs, CV, and matches'),
                      trailing: const Text('🤖'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(
                              matchName: 'My AI',
                              matchUserId: 'ai_bot',
                              matchUserRole: 'ai',
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // If there are no conversations, show a friendly placeholder after the AI entry
                  if (_conversations.isEmpty &&
                      pinnedCount == 1 &&
                      index == 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start matching to begin chatting — or try the AI Assistant above',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Otherwise show normal conversations (shift index by pinnedCount)
                  final conversation = _conversations[index - pinnedCount];
                  final partnerId = conversation['partnerId'] as String;
                  final partnerName = conversation['partnerName'] as String;
                  final partnerRole = conversation['partnerRole'] as String;
                  final lastMessage = conversation['lastMessage'] as String;
                  final lastMessageTime =
                      conversation['lastMessageTime'] as DateTime;
                  final unreadCount = conversation['unreadCount'] as int;

                  final isAi = partnerId == 'ai_bot' ||
                      (partnerRole).toLowerCase() == 'ai';

                  return ListTile(
                    leading: isAi
                        ? CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: const Icon(Icons.smart_toy,
                                color: Colors.white),
                          )
                        : CircleAvatar(
                            backgroundColor: partnerRole == 'employer'
                                ? Colors.blue
                                : Colors.green,
                            child: Text(
                              partnerName.isNotEmpty
                                  ? partnerName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isAi ? 'My AI' : partnerName,
                            style: TextStyle(
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => isAi
                              ? const ChatScreen(
                                  matchName: 'My AI',
                                  matchUserId: 'ai_bot',
                                  matchUserRole: 'ai',
                                )
                              : MessagePage(
                                  partnerId: partnerId,
                                  partnerName: partnerName,
                                  partnerRole: partnerRole,
                                  currentUserId: _currentUserId!,
                                ),
                        ),
                      ).then((_) => _loadConversations());
                    },
                  );
                },
              ),
            ),
    );
  }
}
