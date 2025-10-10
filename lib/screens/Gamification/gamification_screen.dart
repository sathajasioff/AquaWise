import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/challenge.dart';
import '../../models/reward.dart';
import '../../models/leaderboard_entry.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/reward_card.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  // --- User meta ---
  int userPoints = 320;
  int level = 3;
  double xpProgress = 0.55;
  int streakDays = 6;

  // --- Demo data ---
  List<Challenge> challenges = const [
    Challenge(
      id: "c1",
      title: "5-Minute Shower",
      description: "Limit daily showers to 5 minutes to save water",
      goalLiters: 200,
      currentLiters: 120,
      rewardPoints: 60,
      joined: true,
    ),
    Challenge(
      id: "c2",
      title: "Fix a Leak",
      description: "Find and fix any leaking tap at home",
      goalLiters: 100,
      currentLiters: 0,
      rewardPoints: 100,
      joined: false,
    ),
    Challenge(
      id: "c3",
      title: "Weekly Saver",
      description: "Save 500L of water this week",
      goalLiters: 500,
      currentLiters: 410,
      rewardPoints: 150,
      joined: true,
    ),
  ];

  final List<LeaderboardEntry> leaderboard = const [
    LeaderboardEntry(rank: 1, name: "Ayesha", points: 1500),
    LeaderboardEntry(rank: 2, name: "Ravi", points: 1320),
    LeaderboardEntry(rank: 3, name: "Meena", points: 1205),
    LeaderboardEntry(rank: 4, name: "You", points: 1100, isYou: true),
    LeaderboardEntry(rank: 5, name: "Tharindu", points: 980),
  ];

  final List<Reward> rewards = const [
    Reward(
      id: "r1",
      title: "Water Filter Discount",
      description: "10% off eco-friendly water filter",
      costPoints: 250,
      image: "https://picsum.photos/seed/filter/300/200",
    ),
    Reward(
      id: "r2",
      title: "Plant a Tree",
      description: "We plant a tree on your behalf",
      costPoints: 300,
      image: "https://picsum.photos/seed/tree/300/200",
    ),
    Reward(
      id: "r3",
      title: "Reusable Bottle",
      description: "Premium stainless steel water bottle",
      costPoints: 450,
      image: "https://picsum.photos/seed/bottle/300/200",
    ),
    Reward(
      id: "r4",
      title: "Eco Warrior Badge",
      description: "Special badge for your profile",
      costPoints: 150,
      image: "https://picsum.photos/seed/badge/300/200",
    ),
  ];

  // --- Actions ---
  void _joinChallenge(String id) {
    setState(() {
      challenges = challenges.map((c) =>
        c.id == id ? c.copyWith(joined: true) : c
      ).toList();
    });
    _showSnackBar("Challenge joined! Start saving water 💧");
  }

  void _leaveChallenge(String id) {
    setState(() {
      challenges = challenges.map((c) =>
        c.id == id ? c.copyWith(joined: false) : c
      ).toList();
    });
    _showSnackBar("Challenge left");
  }

  void _logTenLiters(String id) {
    setState(() {
      challenges = challenges.map((c) {
        if (c.id != id) return c;
        final updated = c.copyWith(currentLiters: c.currentLiters + 10);
        if (updated.completed) {
          userPoints += updated.rewardPoints;
          xpProgress += 0.1;
          if (xpProgress >= 1) {
            level += 1;
            xpProgress = xpProgress - 1;
            _showLevelUp();
          }
          _showRewardDialog(updated.rewardPoints);
        }
        return updated;
      }).toList();
    });
    _showSnackBar("+10L logged! Keep going 🌟");
  }

  void _redeemReward(Reward reward) {
    if (userPoints < reward.costPoints) {
      _showSnackBar("Not enough points! Need ${reward.costPoints - userPoints} more");
      return;
    }
    setState(() => userPoints -= reward.costPoints);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Redeemed 🎉"),
        content: Text("You redeemed \"${reward.title}\"."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRewardDialog(int pts) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Challenge Completed"),
        content: Text("Great job! You earned +$pts points."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nice"),
          ),
        ],
      ),
    );
  }

  void _showLevelUp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Level Up!"),
        content: Text("Welcome to Level $level 🔥"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 23, 110, 210),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Eco Challenges",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  "Challenges",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Tab(
                child: Text(
                  "Leaderboard",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Tab(
                child: Text(
                  "Rewards",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
            indicatorColor: const Color.fromARGB(255, 23, 110, 210),
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        body: TabBarView(
          children: [
            _buildChallengesTab(),
            _buildLeaderboardTab(),
            _buildRewardsTab(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: xpProgress,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 23, 110, 210)),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "Lv $level",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${(xpProgress * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Water Saver",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Eco Warrior",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.amber[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "$userPoints Points",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 23, 110, 210),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 23, 110, 210).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "$streakDays days",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          LinearProgressIndicator(
            value: xpProgress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 23, 110, 210)),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 24),
          // Section Header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Active Challenges",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Challenges List
          Column(
            children: challenges.map((challenge) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ChallengeCard(
                  challenge: challenge,
                  onJoin: () => _joinChallenge(challenge.id),
                  onLeave: () => _leaveChallenge(challenge.id),
                  onLog10L: () => _logTenLiters(challenge.id),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 24),
          // Section Header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Community Leaderboard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Leaderboard List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: leaderboard.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: entry.isYou ? const Color.fromARGB(255, 23, 110, 210).withOpacity(0.05) : Colors.transparent,
                    border: Border(
                      bottom: entry.rank != leaderboard.length 
                          ? BorderSide(color: Colors.grey[300]!) 
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getRankColor(entry.rank),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            entry.rank.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Text(
                          entry.name,
                          style: TextStyle(
                            fontWeight: entry.isYou ? FontWeight.w600 : FontWeight.w500,
                            color: entry.isYou ? const Color.fromARGB(255, 23, 110, 210) : Colors.black87,
                          ),
                        ),
                      ),
                      // Points
                      Text(
                        "${entry.points} pts",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 23, 110, 210),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 24),
          // Section Header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Available Rewards",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Rewards Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rewards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 200,
            ),
            itemBuilder: (context, index) => RewardCard(
              reward: rewards[index],
              userPoints: userPoints,
              onRedeem: () => _redeemReward(rewards[index]),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color.fromARGB(255, 23, 110, 210); // Blue
    }
  }
}