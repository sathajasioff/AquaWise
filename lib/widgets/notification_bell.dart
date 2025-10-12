import 'package:flutter/material.dart';
import 'package:watermeter/services/notification_service.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const NotificationBell({
    super.key,
    required this.onTap,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: size,
                color: Colors.grey[700],
              ),
              onPressed: onTap,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}