import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize notifications
  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get device token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveDeviceToken(token);
    }

    // Handle background messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // Save device token for push notifications
  static Future<void> _saveDeviceToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    // You can show a local notification here
  }

  // Handle background messages when app is opened
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
    // Navigate to specific screen based on message data
  }

  // Send challenge invitation notification
  static Future<void> sendChallengeInvitation({
    required String challengeId,
    required String challengeTitle,
    required String inviterName,
    required String invitedUserId,
  }) async {
    try {
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(invitedUserId)
          .collection('notifications')
          .add({
            'type': 'challenge_invitation',
            'challengeId': challengeId,
            'challengeTitle': challengeTitle,
            'inviterName': inviterName,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': {
              'challengeId': challengeId,
              'challengeTitle': challengeTitle,
            },
          });

      // Send push notification
      await _sendPushNotification(
        userId: invitedUserId,
        title: 'Challenge Invitation',
        body: '$inviterName invited you to join "$challengeTitle"',
        data: {
          'type': 'challenge_invitation',
          'challengeId': challengeId,
        },
      );

    } catch (e) {
      print('Error sending challenge invitation: $e');
    }
  }

  // Send push notification
  static Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's device tokens
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);

      if (tokens.isEmpty) return;

      // In a real app, you would send this via FCM HTTP API
      // For now, we'll just log it
      print('Would send push notification to user $userId: $title - $body');

      // Actual implementation would use http package to call FCM API
      // await http.post(
      //   Uri.parse('https://fcm.googleapis.com/fcm/send'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'key=YOUR_SERVER_KEY',
      //   },
      //   body: jsonEncode({
      //     'registration_ids': tokens,
      //     'notification': {
      //       'title': title,
      //       'body': body,
      //       'sound': 'default',
      //     },
      //     'data': data,
      //   }),
      // );

    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notifications = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Get unread notifications count
  static Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}