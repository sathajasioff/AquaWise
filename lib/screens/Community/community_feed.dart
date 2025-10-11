import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:watermeter/services/firebase_challenge_service.dart';
import 'package:watermeter/widgets/create_challenge_dialog.dart';
import 'package:watermeter/widgets/dashboard_navbar.dart';
import 'package:watermeter/services/firebase_user_service.dart';
import 'package:watermeter/services/firebase_community_service.dart';
import 'package:watermeter/services/water_usage_manager.dart';
import 'package:intl/intl.dart';
import 'package:watermeter/widgets/edit_challenge_dialog.dart';
import 'package:watermeter/widgets/invite_friends_widget.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedTab = 0;
  int _currentNavIndex = 2;
  double _todayWaterUsage = 0.0;
  bool _isLoading = true;
  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadTodayWaterUsage();
  }

  Future<void> _loadTodayWaterUsage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Loading today water usage...');

      // First, debug the user data
      await FirebaseUserService.debugUserData();

      final usage = await FirebaseUserService.getTodayWaterUsage();
      print('✅ Retrieved water usage: $usage liters');

      setState(() {
        _todayWaterUsage = usage;
      });
    } catch (e) {
      print('❌ Error loading water usage: $e');
      setState(() {
        _todayWaterUsage = 0.0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show edit challenge dialog
  void _showEditChallengeDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => EditChallengeDialog(challenge: challenge),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteChallengeDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: Text(
          challenge.participants.length > 1
              ? 'This challenge has ${challenge.participantCount - 1} other participant(s). It will be archived and participants will be notified. Continue?'
              : 'Are you sure you want to delete this challenge? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteChallenge(challenge.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete challenge
  Future<void> _deleteChallenge(String challengeId) async {
    try {
      await FirebaseChallengeService.deleteChallenge(challengeId);
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close confirmation dialog
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge deleted successfully!')),
      );
      // Refresh the UI
      setState(() {});
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close confirmation dialog
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting challenge: $e')));
    }
  }

  Future<void> _logWaterUsageAndUpdateChallenges(double liters) async {
    try {
      // Log the water usage normally
      await FirebaseUserService.addManualWaterUsage(liters);

      // Get user's active challenges
      final challenges =
          await FirebaseChallengeService.getUserChallenges().first;
      final activeChallenges = challenges.where(
        (c) =>
            c.isActive &&
            c.participants.contains(FirebaseAuth.instance.currentUser?.uid),
      );

      // Update each challenge
      for (final challenge in activeChallenges) {
        await FirebaseChallengeService.updateChallengeProgress(
          challenge.id,
          liters.toInt(),
        );
      }

      await _loadTodayWaterUsage();
    } catch (e) {
      print('Error logging water usage: $e');
      rethrow; // Re-throw to handle in the calling method
    }
  }

  Future<void> _addManualWaterUsage() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Water Usage'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Liters',
            hintText: 'Enter today\'s water usage in liters',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final liters = double.tryParse(controller.text) ?? 0.0;
              if (liters > 0) {
                try {
                  // Use the new function that also updates challenges
                  await _logWaterUsageAndUpdateChallenges(liters);
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $liters liters to today\'s usage!'),
                    ),
                  );
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTestWaterUsage() async {
    try {
      // Add some test water usage using the new function
      await _logWaterUsageAndUpdateChallenges(
        50.0,
      ); // Example: 50 liters for shower
      await _logWaterUsageAndUpdateChallenges(
        25.0,
      ); // Example: 25 liters for faucet

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test water usage added!')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await FirebaseCommunityService.createPost(_postController.text.trim());
      _postController.clear();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: TextField(
          controller: _postController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Share your water saving tips or achievements...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isPosting ? null : _createPost,
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadTodayWaterUsage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildUsageCard(),
                      const SizedBox(height: 24),
                      _buildFeatureCard(),
                      const SizedBox(height: 20),
                      _buildContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Community Hub',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.grey[900],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSegmentedControl(),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegment(
            index: 0,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Community',
          ),
          _buildSegment(
            index: 1,
            icon: Icons.emoji_events_rounded,
            label: 'Challenges',
          ),
          _buildSegment(
            index: 2,
            icon: Icons.people_alt_outlined,
            label: 'Friends',
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF0F84FF)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF0F84FF)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    final savingPercentage = WaterUsageManager.calculateSavingPercentage(
      _todayWaterUsage,
    );
    final isSaving = savingPercentage > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F84FF), Color(0xFF2DD4BF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F84FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Water Usage",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const SizedBox(
                            height: 40,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            "${_todayWaterUsage.toStringAsFixed(1)}L",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      WaterUsageManager.getUsageMessage(_todayWaterUsage),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    if (!_isLoading && _todayWaterUsage > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        isSaving
                            ? '${savingPercentage.toStringAsFixed(1)}% below average'
                            : '${savingPercentage.abs().toStringAsFixed(1)}% above average',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isLoading) ...[
                    ElevatedButton(
                      onPressed: _addManualWaterUsage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Add Usage',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (!_isLoading && _todayWaterUsage > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Water Saving Tip',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    WaterUsageManager.getWaterSavingTips(
                      _todayWaterUsage,
                    ).first,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard() {
    final features = {
      0: {
        'icon': Icons.people_alt_rounded,
        'title': 'Community Feed',
        'subtitle': 'Connect and share with your neighbors',
      },
      1: {
        'icon': Icons.groups_rounded,
        'title': 'Group Challenges',
        'subtitle': 'Compete and save together',
      },
      2: {
        'icon': Icons.people_outline_rounded,
        'title': 'Invite Friends',
        'subtitle': 'Track your progress and ranking',
      },
    };

    final feature = features[_selectedTab]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F84FF),
            const Color(0xFF0F84FF).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F84FF).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'] as IconData,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildCommunityTab();
      case 1:
        return _buildChallengesTab();
      case 2:
        return _buildFriends();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCommunityTab() {
    return Column(
      children: [
        // Add the Invite Friends Widget at the top
        InviteFriendsWidget(
          onInviteSent: () {
            // You can add any callback when invite is sent
            print('Invite was shared!');
          },
        ),
        const SizedBox(height: 16),

        // Create Post Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Share your water saving story...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreatePostDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Create Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F84FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Community Posts Stream
        StreamBuilder<List<CommunityPost>>(
          stream: FirebaseCommunityService.getCommunityPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorWidget(
                'Error loading posts: ${snapshot.error}',
              );
            }

            final posts = snapshot.data ?? [];

            if (posts.isEmpty) {
              return const _PlaceholderCard(
                text:
                    'No posts yet. Be the first to share your water saving journey!',
              );
            }

            return Column(
              children: posts.map((post) => _buildPostCard(post)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F84FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getUserInitials(post.userName),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F84FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatTimestamp(post.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<bool>(
            stream: Stream.fromFuture(
              FirebaseCommunityService.isPostLikedByUser(post.id),
            ),
            builder: (context, likeSnapshot) {
              final isLiked = likeSnapshot.data ?? false;

              return Row(
                children: [
                  _buildInteractionButton(
                    icon: isLiked
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    count: post.likes,
                    color: isLiked ? Colors.red : Colors.red,
                    onTap: () => FirebaseCommunityService.likePost(post.id),
                  ),
                  const SizedBox(width: 16),
                  _buildInteractionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    count: post.comments,
                    color: Colors.blue,
                    onTap: () => _showCommentsDialog(post),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.share_rounded, color: Colors.grey[600]),
                    iconSize: 20,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentsDialog(CommunityPost post) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Text(
                'Comments (${post.comments})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Existing comments
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseCommunityService.getComments(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return const Center(child: Text('No comments yet'));
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF0F84FF,
                            ).withOpacity(0.1),
                            child: Text(
                              _getUserInitials(comment['userName']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F84FF),
                              ),
                            ),
                          ),
                          title: Text(
                            comment['userName'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(comment['comment']),
                          trailing: Text(
                            _formatTimestamp(comment['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Add comment
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF0F84FF)),
                    onPressed: () {
                      if (commentController.text.trim().isNotEmpty) {
                        FirebaseCommunityService.addComment(
                          post.id,
                          commentController.text.trim(),
                        );
                        commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('MMM d, yyyy').format(timestamp);
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refreshData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return Column(
      children: [
        // Notifications Section for Challenge Invitations
        _buildNotificationsSection(),
        const SizedBox(height: 16),

        // Main Challenges Stream
        StreamBuilder<List<Challenge>>(
          stream: FirebaseChallengeService.getUserChallenges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorWidget(
                'Error loading challenges: ${snapshot.error}',
              );
            }

            final challenges = snapshot.data ?? [];
            final activeChallenges = challenges
                .where((c) => c.isActive)
                .toList();
            final expiredChallenges = challenges
                .where((c) => !c.isActive)
                .toList();

            return Column(
              children: [
                // Active Challenges
                if (activeChallenges.isNotEmpty) ...[
                  ...activeChallenges.map(
                    (challenge) => _buildChallengeCard(challenge),
                  ),
                  const SizedBox(height: 16),
                ],

                // Expired Challenges Section
                if (expiredChallenges.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Completed Challenges',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...expiredChallenges.map(
                    (challenge) => _buildChallengeCard(challenge),
                  ),
                  const SizedBox(height: 16),
                ],

                // Show joinable challenges if user has no active challenges
                if (activeChallenges.isEmpty) ...[
                  _buildJoinableChallengesSection(),
                  const SizedBox(height: 16),
                ],

                // Empty State or Create Challenge Card
                if (challenges.isEmpty && activeChallenges.isEmpty) ...[
                  const _PlaceholderCard(
                    text:
                        'No challenges yet. Create one to start competing with friends!',
                  ),
                  const SizedBox(height: 16),
                ],

                _buildCreateChallengeCard(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .where('type', isEqualTo: 'challenge_invitation')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Challenge Invitations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  Badge(
                    label: Text(notifications.length.toString()),
                    backgroundColor: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...notifications
                  .take(3)
                  .map((notification) => _buildNotificationItem(notification)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(QueryDocumentSnapshot notification) {
    final data = notification.data() as Map<String, dynamic>;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
      ),
      title: const Text(
        'Challenge Invitation',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${data['inviterName']} invited you to join "${data['challengeTitle']}"',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _acceptChallengeInvitation(
              data['challengeId'],
              notification.id,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _declineChallengeInvitation(notification.id),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinableChallengesSection() {
    return StreamBuilder<List<Challenge>>(
      stream: FirebaseChallengeService.getPublicChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final challenges = snapshot.data ?? [];
        final invitedChallenges =
            FirebaseChallengeService.getInvitedChallenges();

        return StreamBuilder<List<Challenge>>(
          stream: invitedChallenges,
          builder: (context, invitedSnapshot) {
            if (invitedSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }

            final invitedChallengesList = invitedSnapshot.data ?? [];
            final allJoinableChallenges = [
              ...challenges,
              ...invitedChallengesList,
            ];

            if (allJoinableChallenges.isEmpty) {
              return const SizedBox();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Join Group Challenges',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...allJoinableChallenges.map(
                  (challenge) => _buildJoinableChallengeCard(challenge),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildJoinableChallengeCard(Challenge challenge) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isParticipant = challenge.participants.contains(currentUserId);
    final isInvited = challenge.invitedUsers.contains(currentUserId);

    // If user is already participant, don't show in joinable section
    if (isParticipant) {
      return const SizedBox();
    }

    // Debug logging
    print('=== Joinable Challenge Debug ===');
    print('Joinable Challenge: ${challenge.title}');
    print('Is Participant: $isParticipant');
    print('Is Invited: $isInvited');
    print('Is Public: ${challenge.isPublic}');
    print('Is Active: ${challenge.isActive}');
    print('============================');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${challenge.creatorName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isInvited)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Invited',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${challenge.participantCount} participants',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Goal: ${challenge.goalLiters}L',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  if (isInvited) {
                    _acceptChallengeInvitation(challenge.id, null);
                  } else {
                    _joinPublicChallenge(challenge.id);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInvited ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isInvited ? 'Accept Invite' : 'Join Challenge'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isParticipant = challenge.participants.contains(currentUserId);
    final isInvited = challenge.invitedUsers.contains(currentUserId);
    final canJoin = isInvited && !isParticipant;
    final isCreator = challenge.creatorId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${challenge.creatorName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF2DD4BF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${challenge.participantCount} participants',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // ADD THIS: Edit/Delete menu for creator
                  if (isCreator) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditChallengeDialog(challenge);
                        } else if (value == 'delete') {
                          _showDeleteChallengeDialog(challenge);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Challenge'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text(
                                'Delete Challenge',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${challenge.currentLiters} / ${challenge.goalLiters} L',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F84FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: challenge.progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              challenge.isActive ? const Color(0xFF4ADE80) : Colors.grey,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),

          // Status and CTA - FIXED LOGIC
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.reward,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ends ${DateFormat('MMM d, yyyy').format(challenge.endDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (!challenge.isActive) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // FIXED: Show Join button for public challenges user can join
              if (!isParticipant &&
                  !isCreator &&
                  challenge.isPublic &&
                  challenge.isActive) ...[
                ElevatedButton(
                  onPressed: () => _joinPublicChallenge(challenge.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F84FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Join Challenge'),
                ),
              ]
              // FIXED: Show Join button for invited challenges
              else if (canJoin && challenge.isActive) ...[
                ElevatedButton(
                  onPressed: () => _joinChallenge(challenge.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept Invite'),
                ),
              ] else if (isParticipant) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Joined',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isCreator) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Creator',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateChallengeCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCreateChallengeDialog(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0F84FF), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F84FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF0F84FF),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create a Challenge',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F84FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a custom challenge for your community',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptChallengeInvitation(
    String challengeId,
    String? notificationId,
  ) async {
    try {
      await FirebaseChallengeService.acceptChallengeInvitation(challengeId);

      if (notificationId != null) {
        // Mark notification as read
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge joined successfully! 🎉')),
      );

      // Refresh the UI
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error joining challenge: $e')));
    }
  }

  Future<void> _joinPublicChallenge(String challengeId) async {
    try {
      await FirebaseChallengeService.joinPublicChallenge(challengeId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge joined successfully! 🎉')),
      );

      // Refresh the UI
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error joining challenge: $e')));
    }
  }

  Future<void> _joinChallenge(String challengeId) async {
    try {
      await FirebaseChallengeService.joinChallenge(challengeId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the challenge!')),
      );
      // Refresh the UI
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error joining challenge: $e')));
    }
  }

  Future<void> _declineChallengeInvitation(String notificationId) async {
    try {
      // Mark notification as read (effectively declining)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation declined')));

      // Refresh the UI
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error declining invitation: $e')));
    }
  }

  void _showCreateChallengeDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateChallengeDialog(),
    );
  }

  // ADDED: Friends Tab Implementation
  Widget _buildFriends() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('gamificationUsers')
        .orderBy('totalPoints', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return _buildErrorWidget('Error loading friends: ${snapshot.error}');
      }

      final users = snapshot.data?.docs ?? [];
      
      if (users.isEmpty) {
        return const _PlaceholderCard(
          text: 'No friends found. Invite friends to see them here!',
        );
      }

      // Get current user ID for highlighting
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Friends Header with Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: Color(0xFF0F84FF)),
                  const SizedBox(width: 8),
                  const Text(
                    'Friends Leaderboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16324C),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${users.length} friends',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Friends List - Using FutureBuilder to fetch user names
            ...users.asMap().entries.map((entry) {
              final index = entry.key;
              final userDoc = entry.value;
              final userData = userDoc.data() as Map<String, dynamic>;
              final isCurrentUser = userDoc.id == currentUserId;
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userDoc.id)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildFriendsRow(
                      _FriendsEntry(
                        rank: index + 1,
                        username: 'Loading...',
                        litersSaved: (userData['totalWaterSaved'] ?? 0).toInt(),
                        points: (userData['totalPoints'] ?? 0).toInt(),
                        trend: _calculateTrend(userData),
                        isCurrentUser: isCurrentUser,
                        userId: userDoc.id,
                      ),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return _buildFriendsRow(
                      _FriendsEntry(
                        rank: index + 1,
                        username: 'Unknown User',
                        litersSaved: (userData['totalWaterSaved'] ?? 0).toInt(),
                        points: (userData['totalPoints'] ?? 0).toInt(),
                        trend: _calculateTrend(userData),
                        isCurrentUser: isCurrentUser,
                        userId: userDoc.id,
                      ),
                    );
                  }

                  final userProfile = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final userName = userProfile?['username'] ?? 
                                 userProfile?['name'] ?? 
                                 userProfile?['email']?.split('@').first ?? 
                                 'User';

                  return _buildFriendsRow(
                    _FriendsEntry(
                      rank: index + 1,
                      username: userName,
                      litersSaved: (userData['totalWaterSaved'] ?? 0).toInt(),
                      points: (userData['totalPoints'] ?? 0).toInt(),
                      trend: _calculateTrend(userData),
                      isCurrentUser: isCurrentUser,
                      userId: userDoc.id,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    },
  );
}
  // ADDED: Helper method to calculate trend based on user data
  Trend _calculateTrend(Map<String, dynamic> userData) {
    final weeklyPoints = userData['weeklyPoints'] ?? 0;
    final lastWeekPoints = userData['lastWeekPoints'] ?? 0;
    
    if (weeklyPoints > lastWeekPoints) return Trend.rising;
    if (weeklyPoints < lastWeekPoints) return Trend.falling;
    return Trend.same;
  }

  // ADDED: Updated Friends Row Widget
  Widget _buildFriendsRow(_FriendsEntry entry) {
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildRankIndicator(entry.rank),
          const SizedBox(width: 12),
          // User Avatar with online status
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? const Color(0xFF0F84FF)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getUserInitials(entry.username),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isCurrentUser ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              // Online status indicator
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser
                            ? const Color(0xFF0F84FF)
                            : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F84FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.water_drop, size: 12, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.litersSaved}L saved',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.emoji_events, size: 12, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${_calculateLevel(entry.points)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F84FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.points} pts',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F84FF),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildTrendIndicator(entry.trend),
            ],
          ),
        ],
      ),
    );
  }

  // ADDED: Helper method to calculate user level based on points
  int _calculateLevel(int points) {
    if (points >= 5000) return 10;
    if (points >= 2500) return 9;
    if (points >= 1500) return 8;
    if (points >= 1000) return 7;
    if (points >= 750) return 6;
    if (points >= 500) return 5;
    if (points >= 300) return 4;
    if (points >= 150) return 3;
    if (points >= 50) return 2;
    return 1;
  }

  // ADDED: Rank Indicator Widget
  Widget _buildRankIndicator(int rank) {
    final colors = {
      1: [Color(0xFFFFD700), Color(0xFFFFC400)], // Gold
      2: [Color(0xFFC0C0C0), Color(0xFFA8A8A8)], // Silver
      3: [Color(0xFFCD7F32), Color(0xFFB87333)], // Bronze
    };

    if (colors.containsKey(rank)) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors[rank]!,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ADDED: Trend Indicator Widget
  Widget _buildTrendIndicator(Trend trend) {
    final config = {
      Trend.rising: {
        'icon': Icons.trending_up_rounded,
        'color': Color(0xFF10B981),
        'label': 'Rising',
      },
      Trend.falling: {
        'icon': Icons.trending_down_rounded,
        'color': Color(0xFFEF4444),
        'label': 'Falling',
      },
      Trend.same: {
        'icon': Icons.remove_rounded,
        'color': Color(0xFF6B7280),
        'label': 'Same',
      },
    };

    final data = config[trend]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data['icon'] as IconData, size: 14, color: data['color'] as Color),
        const SizedBox(width: 4),
        Text(
          data['label'] as String,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: data['color'] as Color,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String text;
  const _PlaceholderCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EEF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B2540),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF16324C),
          height: 1.35,
        ),
      ),
    );
  }
}

enum Trend { rising, falling, same }

// ADDED: Updated FriendsEntry class
class _FriendsEntry {
  final int rank;
  final String username;
  final int litersSaved;
  final int points;
  final Trend trend;
  final bool isCurrentUser;
  final String userId;

  const _FriendsEntry({
    required this.rank,
    required this.username,
    required this.litersSaved,
    required this.points,
    required this.trend,
    this.isCurrentUser = false,
    required this.userId,
  });
}