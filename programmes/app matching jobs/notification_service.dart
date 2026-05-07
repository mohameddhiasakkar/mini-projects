import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  OverlayEntry? _currentNotification;

  void showMessageNotification({
    required String message,
    String? assetPath,
    Duration duration = const Duration(seconds: 5),
  }) {
    dismissNotification();

    final notification = MessageNotification(
      message: message,
      lottieAsset: assetPath,
      onDismiss: dismissNotification,
    );

    _currentNotification = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 0,
        right: 0,
        child: notification,
      ),
    );

    Overlay.of(navigatorKey.currentContext!).insert(_currentNotification!);

    Future.delayed(duration, () {
      dismissNotification();
    });
  }

  void showMatchNotification({
    required String matchName,
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    dismissNotification();

    final notification = MessageNotification(
      message: '🎉 New match with $matchName!\n$message',
      lottieAsset: null,
      onDismiss: dismissNotification,
    );

    _currentNotification = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 0,
        right: 0,
        child: notification,
      ),
    );

    Overlay.of(navigatorKey.currentContext!).insert(_currentNotification!);

    Future.delayed(duration, () {
      dismissNotification();
    });
  }

  void dismissNotification() {
    _currentNotification?.remove();
    _currentNotification = null;
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MessageNotification extends StatefulWidget {
  final String message;
  final String? lottieAsset;
  final VoidCallback? onDismiss;

  const MessageNotification({
    super.key,
    required this.message,
    this.lottieAsset,
    this.onDismiss,
  });

  @override
  State<MessageNotification> createState() => _MessageNotificationState();
}

class _MessageNotificationState extends State<MessageNotification>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _buildAnimatedIcon(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon() {
    final assetPath = widget.lottieAsset ?? '';
    if (assetPath.contains('Notification')) {
      return _buildNotificationIcon();
    } else if (assetPath.contains('CPU_Cooldown')) {
      return _buildCPUIcon();
    } else if (assetPath.contains('Businessman_Career')) {
      return _buildBusinessmanIcon();
    } else {
      return _buildDefaultIcon();
    }
  }

  Widget _buildNotificationIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Icon(
        Icons.notifications,
        color: Colors.blue[600],
        size: 30,
      ),
    );
  }

  Widget _buildCPUIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.memory,
        color: Colors.green[600],
        size: 30,
      ),
    );
  }

  Widget _buildBusinessmanIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.business,
        color: Colors.blue[600],
        size: 30,
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.animation,
        color: Colors.grey,
        size: 30,
      ),
    );
  }
}
