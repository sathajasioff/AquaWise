import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique referral code for the user
  static Future<String> generateReferralCode() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Use first 4 chars of UID + random 4 digits
      final code = '${user.uid.substring(0, 4)}${DateTime.now().millisecondsSinceEpoch % 10000}'.toUpperCase();
      
      // Store the referral code in user document
      await _firestore.collection('users').doc(user.uid).set({
        'referralCode': code,
        'referralCount': 0,
        'referralPoints': 0,
      }, SetOptions(merge: true));
      
      return code;
    }
    return '';
  }

  // Get user's referral code
  static Future<String> getReferralCode() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      return data?['referralCode'] ?? '';
    }
    return '';
  }

  // Get referral statistics
  static Future<Map<String, dynamic>> getReferralStats() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      
      return {
        'referralCount': data?['referralCount'] ?? 0,
        'referralPoints': data?['referralPoints'] ?? 0,
        'referralCode': data?['referralCode'] ?? '',
      };
    }
    return {'referralCount': 0, 'referralPoints': 0, 'referralCode': ''};
  }

  // Main share invitation method
  static Future<void> shareInvitation() async {
    try {
      final code = await getReferralCode();
      final message = _generateInvitationMessage(code);
      
      await Share.share(message);
      await _trackShareEvent();
    } catch (e) {
      print('Error sharing invitation: $e');
    }
  }

  // Share via SMS
  static Future<void> shareViaSMS() async {
    try {
      final code = await getReferralCode();
      final message = _generateInvitationMessage(code);
      final uri = 'sms:?body=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(uri))) {
        await launchUrl(Uri.parse(uri));
        await _trackShareEvent();
      } else {
        // Fallback to regular share
        await shareInvitation();
      }
    } catch (e) {
      print('Error sharing via SMS: $e');
      // Fallback to regular share
      await shareInvitation();
    }
  }

  // Share via email
  static Future<void> shareViaEmail() async {
    try {
      final code = await getReferralCode();
      final message = _generateInvitationMessage(code);
      final subject = 'Join me in saving water with AquaCard! 💧';
      final uri = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(uri))) {
        await launchUrl(Uri.parse(uri));
        await _trackShareEvent();
      } else {
        // Fallback to regular share
        await shareInvitation();
      }
    } catch (e) {
      print('Error sharing via email: $e');
      await shareInvitation();
    }
  }

  // Copy to clipboard (simulated using share)
  static Future<void> copyToClipboard() async {
    try {
      final code = await getReferralCode();
      final message = 'My AquaCard referral code: $code\n\nJoin me in saving water! 💧';
      
      // For cross-platform compatibility, use share as copy alternative
      await Share.share(message);
      await _trackShareEvent();
    } catch (e) {
      print('Error copying to clipboard: $e');
    }
  }

  // Generate invitation message
  static String _generateInvitationMessage(String code) {
    return '''
💧 Join me in saving water with AquaCard! 🌊

Use my referral code: **$code**

Together we can:
✅ Track water usage
✅ Join community challenges  
✅ Earn rewards for saving water
✅ Help protect our planet

Download the app and let's make a difference! 💙

#WaterConservation #EcoFriendly #SaveWater
''';
  }

  // Track share events
  static Future<void> _trackShareEvent() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('shareEvents').add({
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'invite_share',
      });
    }
  }

  // Generate deep link (for future implementation)
  static String generateDeepLink(String referralCode) {
    return 'https://aquacard.page.link/invite?code=$referralCode';
  }

  // Get leaderboard for top referrers
  static Stream<QuerySnapshot> getReferralLeaderboard() {
    return _firestore
        .collection('users')
        .where('referralCount', isGreaterThan: 0)
        .orderBy('referralCount', descending: true)
        .limit(10)
        .snapshots();
  }

  // Update referral stats when someone joins using the code
  static Future<void> updateReferralStats(String referralCode) async {
    try {
      // Find user with this referral code
      final query = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .get();

      if (query.docs.isNotEmpty) {
        final referrerId = query.docs.first.id;
        await _firestore.collection('users').doc(referrerId).update({
          'referralCount': FieldValue.increment(1),
          'referralPoints': FieldValue.increment(100),
        });
      }
    } catch (e) {
      print('Error updating referral stats: $e');
    }
  }
}