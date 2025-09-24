import 'package:flutter/material.dart';
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
  int userPoints = 320;           // your current points
  int level = 3;
  double xpProgress = 0.55;       // 0..1
  int streakDays = 6;

  // --- Demo data (replace with Firestore later) ---
  List<Challenge> challenges = const [
    Challenge(
      id: "c1",
      title: "5-Minute Shower",
      description: "Limit daily showers to 5 minutes.",
      goalLiters: 200,
      currentLiters: 120,
      rewardPoints: 60,
      joined: true,
    ),
    Challenge(
      id: "c2",
      title: "Fix a Leak",
      description: "Find and fix any leaking tap at home.",
      goalLiters: 100,
      currentLiters: 0,
      rewardPoints: 100,
      joined: false,
    ),
    Challenge(
      id: "c3",
      title: "Weekly Saver",
      description: "Save 500L of water this week.",
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
      title: "10% Off – Water Filter",
      description: "Voucher for eco water filter",
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
      description: "Stainless steel bottle",
      costPoints: 450,
      image: "https://picsum.photos/seed/bottle/300/200",
    ),
    Reward(
      id: "r4",
      title: "Community Badge",
      description: "Special badge in your profile",
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
  }

  void _leaveChallenge(String id) {
    setState(() {
      challenges = challenges.map((c) =>
        c.id == id ? c.copyWith(joined: false) : c
      ).toList();
    });
  }

  void _logTenLiters(String id) {
    setState(() {
      challenges = challenges.map((c) {
        if (c.id != id) return c;
        final updated = c.copyWith(currentLiters: c.currentLiters + 10);
        if (updated.completed) {
          // award points once it crosses the goal
          userPoints += updated.rewardPoints;
          // bump XP a little
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
  }

  void _redeemReward(Reward reward) {
    if (userPoints < reward.costPoints) return;
    setState(() => userPoints -= reward.costPoints);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Redeemed 🎉"),
        content: Text("You redeemed “${reward.title}”."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showRewardDialog(int pts) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Challenge Completed"),
        content: Text("Great job! You earned +$pts points."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Nice")),
        ],
      ),
    );
  }

  void _showLevelUp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Level Up!"),
        content: Text("Welcome to Level $level 🔥"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text("Gamification"),
          centerTitle: true,
          backgroundColor: const Color(0xFF176ED2),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Challenges"),
              Tab(text: "Leaderboard"),
              Tab(text: "Rewards"),
            ],
            indicatorColor: Colors.white,
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

  // Top header (shared) – points, level, XP, streak
  Widget _header() {
    return Column(
      children: [
        // Points & XP
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: xpProgress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  Text("Lv $level", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Eco Saver", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text("XP: ${(xpProgress * 100).toInt()}%"),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF176ED2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$userPoints pts",
                  style: const TextStyle(
                    color: Color(0xFF176ED2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Streak
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text("🔥 $streakDays-day streak — keep saving!",
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildChallengesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Active Challenges",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          for (final c in challenges)
            ChallengeCard(
              challenge: c,
              onJoin: () => _joinChallenge(c.id),
              onLeave: () => _leaveChallenge(c.id),
              onLog10L: () => _logTenLiters(c.id),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Community Leaderboard",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Column(
            children: leaderboard.map((e) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: e.isYou ? Colors.green : const Color(0xFF176ED2),
                    child: Text(e.rank.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    e.name,
                    style: TextStyle(fontWeight: e.isYou ? FontWeight.w700 : FontWeight.w500),
                  ),
                  trailing: Text("${e.points} pts",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF176ED2),
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Redeem Rewards",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          // Grid of rewards
          GridView.builder(
            shrinkWrap: true,
            itemCount: rewards.length,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 210,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (_, i) => RewardCard(
              reward: rewards[i],
              userPoints: userPoints,
              onRedeem: () => _redeemReward(rewards[i]),
            ),
          ),
        ],
      ),
    );
  }
}
