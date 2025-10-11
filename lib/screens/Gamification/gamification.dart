// screens/Gamification/gamification_screen.dart
import 'package:flutter/material.dart' hide Badge;
import '../../controllers/gamification_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/challenge.dart';
import '../../models/user_challenge.dart';
import '../../models/user.dart';
import '../../models/badge.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> 
    with AutomaticKeepAliveClientMixin<GamificationScreen> {
  final GamificationController _controller = GamificationController();
  final DashboardController _dashboardController = DashboardController();
  String? _userType;
  List<Challenge> _availableChallenges = [];
  bool _loading = true;
  User? _currentUser;
  bool _isCasualUser = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Use the new efficient method
      final userData = await _controller.getUserEssentialData();
      final user = await _dashboardController.fetchUser();
      final challenges = _controller.getChallengesForPersona(userData['userType']);
      
      print('✅ Loaded user: ${user?.username}');
      print('✅ Loaded userType: ${userData['userType']}');
      print('✅ Available challenges: ${challenges.length}');

      setState(() {
        _currentUser = user;
        _userType = userData['userType'];
        _availableChallenges = challenges;
        _isCasualUser = _userType == 'casual';
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_loading) {
      return _buildLoadingScreen();
    }

    // Determine tabs based on user type
    final tabs = _isCasualUser 
      ? const [
          Tab(icon: Icon(Icons.flag), text: 'Challenges'),
          Tab(icon: Icon(Icons.task), text: 'Casual Tasks'),
          Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
        ]
      : const [
          Tab(icon: Icon(Icons.flag), text: 'Challenges'),
          Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
        ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          title: Text('${_capitalize(_userType!)} Water Saving Game'),
          backgroundColor: Color.fromARGB(255, 45, 134, 212),
          foregroundColor: Colors.white,
          actions: [
            if (_isCasualUser)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUserData,
                tooltip: 'Refresh Tasks',
              ),
          ],
          bottom: TabBar(
            tabs: tabs,
          ),
        ),
        body: _isCasualUser 
          ? TabBarView(
              children: [
                _buildChallengesTab(),
                _buildCasualTasksTab(),
                _buildBadgesTab(),
              ],
            )
          : TabBarView(
              children: [
                _buildChallengesTab(),
                _buildBadgesTab(),
              ],
            ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F84FF),),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Your Game...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 CHALLENGES TAB
  Widget _buildChallengesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPointsCard(),
          const SizedBox(height: 24),
          _buildAvailableChallengesSection(),
          const SizedBox(height: 24),
          _buildActiveChallengesSection(),
          const SizedBox(height: 24),
          _buildCompletedChallengesSection(),
        ],
      ),
    );
  }

  // 🎯 CASUAL TASKS TAB (Only for casual users)
  Widget _buildCasualTasksTab() {
    if (!_isCasualUser) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Casual tasks are only available for casual users.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        // User Info Card
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Casual User Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('User Type: $_userType'),
                Text('Username: ${_currentUser?.username ?? 'N/A'}'),
                _buildCurrentPointsDisplay(),
              ],
            ),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _controller.getCasualTasksFromLeaderboard(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildCasualTasksLoading();
              }

              if (snapshot.hasError) {
                return _buildCasualTasksError(snapshot.error.toString());
              }

              final tasks = snapshot.data ?? [];
              
              if (tasks.isEmpty) {
                return _buildNoCasualTasks();
              }

              return _buildCasualTasksList(tasks);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPointsDisplay() {
    return StreamBuilder<int>(
      stream: _controller.getUserPoints(),
      builder: (context, snapshot) {
        final points = snapshot.data ?? 0;
        return Text(
          'Current Points: $points',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _buildCasualTasksList(List<Map<String, dynamic>> tasks) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress Overview
        _buildProgressStats(tasks),
        const SizedBox(height: 16),
        
        // Tasks List Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'My Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B47),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Tasks List
        ...tasks.map((task) => _buildCasualTaskCard(task)),
      ],
    );
  }

  Widget _buildProgressStats(List<Map<String, dynamic>> tasks) {
    final completedTasks = tasks.where((task) => task['status'] == 'completed').length;
    final totalTasks = tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    
    final totalPoints = tasks.fold<int>(0, (int sum, task) {
      final points = task['pointsEarned'];
      if (points is int) return sum + points;
      if (points is double) return sum + points.toInt();
      if (points is String) return sum + (int.tryParse(points) ?? 0);
      return sum;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress Overview', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.analytics, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$completedTasks/$totalTasks completed'),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Complete',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$totalPoints Points', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total Earned', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasualTaskCard(Map<String, dynamic> task) {
    final isCompleted = task['status'] == 'completed';
    final points = task['pointsEarned'] ?? 0;
    final taskName = task['taskName'] ?? 'Unknown Task';
    final startedAt = task['startedAt'];
    final taskId = task['taskId'] ?? '';
    final category = task['category'] ?? 'general';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.access_time,
            color: isCompleted ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          taskName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'In Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (startedAt != null) 
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Started: ${_formatDateString(startedAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+${points}P',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isCompleted) 
              ElevatedButton(
                onPressed: () => _completeCasualTask(taskId, taskName),
                child: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(80, 30),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasualTasksLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your casual tasks...'),
        ],
      ),
    );
  }

  Widget _buildCasualTasksError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCasualTasks() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Tasks Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete tasks from your dashboard to see them here.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeCasualTask(String taskId, String taskName) async {
    if (taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Task ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _controller.completeCasualTaskFromGamification(taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$taskName" completed! + Points earned'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🏆 BADGES TAB - UPDATED WITH ENHANCED PROGRESSION
  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Progress with Enhanced Display
          _buildBadgeProgressSection(),
          const SizedBox(height: 24),
          
          const Text(
            'My Badges',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B47),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Earned achievements and badges',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildUserBadgesSection(),
        ],
      ),
    );
  }

  Widget _buildBadgeProgressSection() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _controller.getBadgeProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBadgesLoading();
        }
        
        final progressData = snapshot.data ?? {};
        final nextBadge = progressData['nextBadge'] as Badge?;
        final currentPoints = progressData['currentPoints'] ?? 0;
        final pointsRequired = progressData['pointsRequired'] ?? 1;
        final progress = progressData['progress'] ?? 0.0;
        final pointsNeeded = progressData['pointsNeeded'] ?? 0;
        final isAchievable = progressData['isAchievable'] ?? false;
        final status = progressData['status'] ?? 'In Progress';
        final unearnedCount = progressData['unearnedBadgesCount'] ?? 0;
        
        Color cardColor;
        Color progressColor;
        String title;

        if (nextBadge == null) {
          cardColor = Colors.purple.shade50;
          progressColor = Colors.purple;
          title = 'All Badges Earned!';
        } else if (isAchievable) {
          cardColor = Colors.green.shade50;
          progressColor = Colors.green;
          title = 'Ready to Earn!';
        } else {
          cardColor = Colors.blue.shade50;
          progressColor = Colors.blue;
          title = 'Next Badge Progress';
        }

        return Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    if (unearnedCount > 0 && nextBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unearnedCount left',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (nextBadge != null) ...[
                  Row(
                    children: [
                      Text(nextBadge.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextBadge.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              nextBadge.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: progressColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: progressColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: progressColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: progressColor,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$currentPoints/$pointsRequired points',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        isAchievable ? '🎉 Ready to earn!' : '${pointsNeeded} points needed',
                        style: TextStyle(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, size: 48, color: Colors.purple),
                        const SizedBox(height: 12),
                        const Text(
                          'All Badges Earned!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have collected all available badges',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Points: $currentPoints',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserBadgesSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.getUserBadgesWithDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBadgesLoading();
        }

        if (snapshot.hasError) {
          return _buildBadgesError();
        }

        final badges = snapshot.data ?? [];

        if (badges.isEmpty) {
          return _buildNoBadges();
        }

        return _buildBadgesGrid(badges);
      },
    );
  }

  // 🏅 Points Display
  Widget _buildPointsCard() {
    return StreamBuilder<int>(
      stream: _controller.getUserPoints(),
      builder: (context, snapshot) {
        final points = snapshot.data ?? 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F84FF), Color(0xFF2DD4BF)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 48),
              const SizedBox(height: 10),
              Text(
                '${_currentUser?.username ?? 'User'}\'s Points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_capitalize(_userType!)} Water Saver',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgesGrid(List<Map<String, dynamic>> badges) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badgeData = badges[index];
            final badge = badgeData['badge'] as Badge;
            final userBadge = badgeData['userBadge'] as UserBadge;
            
            return _buildBadgeItem(badge, userBadge);
          },
        ),
      ),
    );
  }

  Widget _buildBadgeItem(Badge badge, UserBadge userBadge) {
    final rarityColor = _getRarityColor(badge.rarity);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rarityColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: Color(0xFF1A2B47),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Earned',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(userBadge.earnedAt),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesLoading() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            'Loading badges...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesError() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Unable to load badges',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBadges() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No Badges Yet',
            style: TextStyle(
              color: Color(0xFF1A2B47),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete challenges to earn your first badge!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🎯 Available Challenges
  Widget _buildAvailableChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available ${_capitalize(_userType!)} Challenges',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2B47),
          ),
        ),
        const SizedBox(height: 8),
        if (_availableChallenges.isEmpty)
          _buildEmptySection('No challenges found', 'Try again later.')
        else
          ..._availableChallenges.map((c) => _buildChallengeCard(c)),
      ],
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getChallengeIcon(challenge.type),
          color: _getChallengeColor(challenge.type),
        ),
        title: Text(
          challenge.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(challenge.description),
        trailing: ElevatedButton(
          onPressed: () => _startChallenge(challenge),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getChallengeColor(challenge.type),
            foregroundColor: Colors.white,
          ),
          child: const Text('Start'),
        ),
      ),
    );
  }

  Future<void> _startChallenge(Challenge challenge) async {
    try {
      await _controller.startChallenge(challenge);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Started: ${challenge.title}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // ⏳ Active Challenges
  Widget _buildActiveChallengesSection() {
    return StreamBuilder<List<UserChallenge>>(
      stream: _controller.getActiveChallenges(),
      builder: (context, snapshot) {
        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) {
          return _buildEmptySection(
            'No Active Challenges',
            'Start one from the list above to begin!',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active ${_capitalize(_userType!)} Challenges',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B47),
              ),
            ),
            const SizedBox(height: 8),
            ...challenges.map((uc) => _buildActiveChallengeCard(uc)),
          ],
        );
      },
    );
  }

  Widget _buildActiveChallengeCard(UserChallenge uc) {
    final challenge = _availableChallenges.firstWhere(
      (x) => x.id == uc.challengeId,
      orElse: () => Challenge(
        id: uc.challengeId,
        title: 'Active Challenge',
        description: 'Challenge in progress',
        points: 0,
        type: _userType!,
        activity: '',
        targetTime: 0,
        targetLiters: 0,
        difficulty: 'easy',
      ),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.orange),
        title: Text(challenge.title),
        subtitle: Text('Started: ${_formatDate(uc.startedAt)}'),
        trailing: Text(
          '${challenge.points} pts',
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ✅ Completed Challenges
  Widget _buildCompletedChallengesSection() {
    return StreamBuilder<List<UserChallenge>>(
      stream: _controller.getCompletedChallenges(),
      builder: (context, snapshot) {
        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) {
          return _buildEmptySection(
            'No Completed Challenges',
            'Complete one to earn rewards!',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed ${_capitalize(_userType!)} Challenges',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B47),
              ),
            ),
            const SizedBox(height: 8),
            ...challenges.map((uc) => _buildCompletedChallengeCard(uc)),
          ],
        );
      },
    );
  }

  Widget _buildCompletedChallengeCard(UserChallenge uc) {
    final challenge = _availableChallenges.firstWhere(
      (x) => x.id == uc.challengeId,
      orElse: () => Challenge(
        id: uc.challengeId,
        title: 'Completed Challenge',
        description: 'Challenge completed',
        points: uc.earnedPoints,
        type: _userType!,
        activity: '',
        targetTime: 0,
        targetLiters: 0,
        difficulty: 'easy',
      ),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(challenge.title),
        trailing: Text(
          '+${uc.earnedPoints} pts',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Utility Methods
  Widget _buildEmptySection(String title, String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 48),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            Text(msg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _formatDate(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  Color _getChallengeColor(String type) {
    switch (type) {
      case 'eco': return const Color(0xFF00B894);
      case 'budget': return const Color(0xFF2D7DD2);
      case 'family': return const Color(0xFF667EEA);
      case 'casual': return const Color(0xFFFF9A00);
      default: return Colors.blueGrey;
    }
  }

  IconData _getChallengeIcon(String type) {
    switch (type) {
      case 'eco': return Icons.eco;
      case 'budget': return Icons.savings;
      case 'family': return Icons.family_restroom;
      case 'casual': return Icons.person;
      default: return Icons.flag;
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common': return Colors.blue;
      case 'rare': return Colors.green;
      case 'epic': return Colors.purple;
      case 'legendary': return Colors.orange;
      default: return Colors.grey;
    }
  }
}