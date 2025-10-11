import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:watermeter/services/notification_service.dart';
import 'package:watermeter/widgets/dashboard_navbar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _currentNavIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox();
              
              return TextButton(
                onPressed: () {
                  NotificationService.markAllAsRead();
                },
                child: const Text('Mark all as read'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final isRead = notification['isRead'] == true;

              return _buildNotificationItem(
                notification,
                notificationId,
                isRead,
              );
            },
          );
        },
      ),
      bottomNavigationBar: DashboardNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          // Handle navigation
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    String notificationId,
    bool isRead,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? Colors.white : Colors.blue[50],
      elevation: 2,
      child: ListTile(
        leading: _getNotificationIcon(notification['type']),
        title: Text(
          _getNotificationTitle(notification),
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getNotificationBody(notification)),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification['timestamp']),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'mark_read') {
              NotificationService.markAsRead(notificationId);
            } else if (value == 'delete') {
              NotificationService.deleteNotification(notificationId);
            }
          },
          itemBuilder: (context) => [
            if (!isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Text('Mark as read'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            NotificationService.markAsRead(notificationId);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'challenge_invitation':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
        );
    }
  }

  String _getNotificationTitle(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'challenge_invitation':
        return 'Challenge Invitation';
      default:
        return 'Notification';
    }
  }

  String _getNotificationBody(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'challenge_invitation':
        return '${notification['inviterName']} invited you to join "${notification['challengeTitle']}"';
      default:
        return notification['body'] ?? '';
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'challenge_invitation':
        // Navigate to challenges tab or specific challenge
        Navigator.pop(context); // Go back to community screen
        // You can add logic to automatically switch to challenges tab
        break;
      default:
        break;
    }
  }
}