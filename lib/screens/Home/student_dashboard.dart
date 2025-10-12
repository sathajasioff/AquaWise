import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CasualDashboard extends StatefulWidget {
  const CasualDashboard({super.key});

  @override
  State<CasualDashboard> createState() => _CasualDashboardState();
}

class _CasualDashboardState extends State<CasualDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<_TaskItem> _tasks = [];
  List<String> _startedTaskIds = [];
  List<String> _completedTaskIds = [];
  bool _isLoading = true;

  // Master list of all possible tasks
  final List<_TaskItem> _allTasks = [
    _TaskItem(
      id: '1',
      title: "Log one shower today",
      subtitle: "Track your daily shower usage",
      icon: Icons.shower,
      color: Colors.blue,
      points: 10,
    ),
    _TaskItem(
      id: '2',
      title: "Try 2-min shorter wash",
      subtitle: "Small changes make big differences",
      icon: Icons.timer,
      color: Colors.green,
      points: 15,
    ),
    _TaskItem(
      id: '3',
      title: "Fill a bottle instead of running tap",
      subtitle: "Save water while brushing or washing",
      icon: Icons.water_drop,
      color: Colors.orange,
      points: 8,
    ),
    _TaskItem(
      id: '4',
      title: "Use a bowl for veggie washing",
      subtitle: "Reuse water for plants",
      icon: Icons.eco,
      color: Colors.teal,
      points: 12,
    ),
    _TaskItem(
      id: '5',
      title: "Fix leaking faucet immediately",
      subtitle: "Prevent water wastage",
      icon: Icons.build,
      color: Colors.red,
      points: 20,
    ),
    _TaskItem(
      id: '6',
      title: "Collect rainwater for plants",
      subtitle: "Use natural water sources",
      icon: Icons.cloud,
      color: Colors.purple,
      points: 18,
    ),
    _TaskItem(
      id: '7',
      title: "Use full loads in washing machine",
      subtitle: "Optimize machine usage",
      icon: Icons.local_laundry_service,
      color: Colors.indigo,
      points: 14,
    ),
    _TaskItem(
      id: '8',
      title: "Water plants in early morning",
      subtitle: "Reduce evaporation loss",
      icon: Icons.nature,
      color: Colors.brown,
      points: 9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
  }

  // Generate random daily tasks (4 different tasks each day)
  Future<void> _loadDailyTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get today's date string for consistency
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Check if we already have tasks for today
      final dailyTasksDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_tasks')
          .doc(today)
          .get();

      List<_TaskItem> dailyTasks = [];

      if (dailyTasksDoc.exists) {
        // Load existing daily tasks
        final taskIds = List<String>.from(dailyTasksDoc.data()!['taskIds'] ?? []);
        dailyTasks = _allTasks.where((task) => taskIds.contains(task.id)).toList();
      } else {
        // Generate new random tasks for today
        final randomTasks = _allTasks.toList()..shuffle();
        dailyTasks = randomTasks.take(4).toList();
        
        // Save today's tasks to Firebase
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_tasks')
            .doc(today)
            .set({
          'taskIds': dailyTasks.map((task) => task.id).toList(),
          'date': today,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Load started tasks for today
      final startedTasksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('started_tasks')
          .where('date', isEqualTo: today)
          .get();

      final startedIds = startedTasksSnapshot.docs
          .map((doc) => doc.data()['taskId'] as String)
          .toList();

      // Load completed tasks for today
      final completedTasksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('completed_tasks')
          .where('date', isEqualTo: today)
          .get();

      final completedIds = completedTasksSnapshot.docs
          .map((doc) => doc.data()['taskId'] as String)
          .toList();

      setState(() {
        _tasks = dailyTasks;
        _startedTaskIds = startedIds;
        _completedTaskIds = completedIds;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startTask(_TaskItem task) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Add task to started tasks
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('started_tasks')
          .add({
        'taskId': task.id,
        'taskName': task.title,
        'date': today,
        'startedAt': FieldValue.serverTimestamp(),
      });

      // Add task to leaderboard as "in progress"
      await _firestore.collection('leaderboard').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous User',
        'taskId': task.id,
        'taskName': task.title,
        'points': task.points,
        'date': today,
        'status': 'started',
        'startedAt': FieldValue.serverTimestamp(),
        'type': 'daily_task',
      });

      // Update local state
      setState(() {
        _startedTaskIds.add(task.id);
      });

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚀 Started: '${task.title}' - Complete it to earn ${task.points} points!",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeTask(_TaskItem task) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Remove from started tasks
      final startedTaskQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('started_tasks')
          .where('taskId', isEqualTo: task.id)
          .where('date', isEqualTo: today)
          .get();

      for (final doc in startedTaskQuery.docs) {
        await doc.reference.delete();
      }

      // Add to completed tasks
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('completed_tasks')
          .add({
        'taskId': task.id,
        'taskName': task.title,
        'points': task.points,
        'date': today,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update leaderboard entry to "completed"
      final leaderboardQuery = await _firestore
          .collection('leaderboard')
          .where('userId', isEqualTo: user.uid)
          .where('taskId', isEqualTo: task.id)
          .where('date', isEqualTo: today)
          .where('status', isEqualTo: 'started')
          .get();

      for (final doc in leaderboardQuery.docs) {
        await doc.reference.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'pointsAwarded': task.points,
        });
      }

      // Update local state
      setState(() {
        _startedTaskIds.remove(task.id);
        _completedTaskIds.add(task.id);
      });

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🎉 Completed: '${task.title}' - +${task.points} points added to leaderboard!",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return _completedTaskIds.length / _tasks.length;
  }

  int get _totalStartedTasks => _startedTaskIds.length;
  int get _totalCompletedTasks => _completedTaskIds.length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(
              color: Color(0xFF667EEA),
            ),
            SizedBox(height: 16),
            Text(
              "Loading your daily tasks...",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_esports,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Water Challenges",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2B47),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Start tasks and complete them to earn points",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Progress",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2B47),
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: _completionPercentage,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _completionPercentage == 1.0 
                                  ? Colors.green 
                                  : const Color(0xFF667EEA)
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_totalCompletedTasks of ${_tasks.length} tasks completed",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _completionPercentage == 1.0 
                            ? Colors.green 
                            : const Color(0xFF667EEA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${(_completionPercentage * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_totalStartedTasks > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$_totalStartedTasks task${_totalStartedTasks > 1 ? 's' : ''} in progress",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tasks list
          Column(
            children: _tasks.asMap().entries.map((entry) {
              final task = entry.value;
              final isStarted = _startedTaskIds.contains(task.id);
              final isCompleted = _completedTaskIds.contains(task.id);
              return Container(
                margin: EdgeInsets.only(bottom: entry.key == _tasks.length - 1 ? 0 : 12),
                child: _TaskCard(
                  task: task,
                  isStarted: isStarted,
                  isCompleted: isCompleted,
                  onStart: () => _startTask(task),
                  onComplete: () => _completeTask(task),
                ),
              );
            }).toList(),
          ),

          // Footer
          if (_completedTaskIds.isNotEmpty || _startedTaskIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _completedTaskIds.isNotEmpty 
                              ? "Great job! Keep going!" 
                              : "You're making progress!",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Completed: $_totalCompletedTasks • In Progress: $_totalStartedTasks • Points: ${_calculateTotalPoints()}",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Refresh indicator
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loadDailyTasks,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                "Refresh Tasks",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalPoints() {
    return _tasks
        .where((task) => _completedTaskIds.contains(task.id))
        .fold(0, (sum, task) => sum + task.points);
  }
}

class _TaskItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int points;

  const _TaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.points,
  });
}

class _TaskCard extends StatelessWidget {
  final _TaskItem task;
  final bool isStarted;
  final bool isCompleted;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _TaskCard({
    required this.task,
    required this.isStarted,
    required this.isCompleted,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted 
            ? const Color(0xFFF0F7FF) 
            : isStarted 
                ? const Color(0xFFFFF8E1)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? const Color(0xFF2D7DD2).withOpacity(0.3)
              : isStarted
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isCompleted && !isStarted)
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? const Color(0xFF2D7DD2).withOpacity(0.1)
                  : isStarted
                      ? Colors.orange.withOpacity(0.1)
                      : task.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted 
                  ? Icons.check_circle 
                  : isStarted
                      ? Icons.play_arrow_rounded
                      : task.icon,
              color: isCompleted 
                  ? const Color(0xFF2D7DD2)
                  : isStarted
                      ? Colors.orange
                      : task.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Task content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B47),
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.subtitle,
                  style: TextStyle(
                    color: isCompleted ? Colors.grey : Colors.grey.shade600,
                    fontSize: 13,
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    "+${task.points} points",
                    style: TextStyle(
                      color: task.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Action button
          if (!isCompleted && !isStarted)
            GestureDetector(
              onTap: onStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D7DD2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2D7DD2)),
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (isStarted && !isCompleted)
            GestureDetector(
              onTap: onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  "Complete",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                "Completed",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}