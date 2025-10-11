import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watermeter/services/firebase_user_service.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final List<String> likedBy;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.likedBy,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }
}

class FirebaseCommunityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new post
  static Future<void> createPost(String content) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userName = await FirebaseUserService.getUserDisplayName();
        
        final post = CommunityPost(
          id: '',
          userId: user.uid,
          userName: userName,
          content: content,
          timestamp: DateTime.now(),
          likes: 0,
          comments: 0,
          likedBy: [],
        );

        await _firestore.collection('community_posts').add(post.toFirestore());
      }
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Stream of all community posts
  static Stream<List<CommunityPost>> getCommunityPosts() {
    return _firestore
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList());
  }

  // Like a post
  static Future<void> likePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final postRef = _firestore.collection('community_posts').doc(postId);
        
        await _firestore.runTransaction((transaction) async {
          final postDoc = await transaction.get(postRef);
          if (postDoc.exists) {
            final data = postDoc.data()!;
            final likedBy = List<String>.from(data['likedBy'] ?? []);
            
            if (likedBy.contains(user.uid)) {
              // Unlike
              likedBy.remove(user.uid);
              transaction.update(postRef, {
                'likes': FieldValue.increment(-1),
                'likedBy': likedBy,
              });
            } else {
              // Like
              likedBy.add(user.uid);
              transaction.update(postRef, {
                'likes': FieldValue.increment(1),
                'likedBy': likedBy,
              });
            }
          }
        });
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  // Check if current user liked a post
  static Future<bool> isPostLikedByUser(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final postDoc = await _firestore.collection('community_posts').doc(postId).get();
        if (postDoc.exists) {
          final data = postDoc.data()!;
          final likedBy = List<String>.from(data['likedBy'] ?? []);
          return likedBy.contains(user.uid);
        }
      }
      return false;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Add comment to post
  static Future<void> addComment(String postId, String comment) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userName = await FirebaseUserService.getUserDisplayName();
        
        await _firestore.collection('community_posts').doc(postId).collection('comments').add({
          'userId': user.uid,
          'userName': userName,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Increment comment count
        await _firestore.collection('community_posts').doc(postId).update({
          'comments': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  // Get comments for a post
  static Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'userName': data['userName'] ?? 'Anonymous',
                'comment': data['comment'] ?? '',
                'timestamp': (data['timestamp'] as Timestamp).toDate(),
              };
            })
            .toList());
  }
}