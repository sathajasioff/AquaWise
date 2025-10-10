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
    Challenge(
      id: "c4",
      title: "Smart Irrigation",
      description: "Use collected rainwater for plants",
      goalLiters: 300,
      currentLiters: 150,
      rewardPoints: 80,
      joined: true,
    ),
  ];

  final List<LeaderboardEntry> leaderboard = const [
    LeaderboardEntry(rank: 1, name: "Ayesha", points: 1500),
    LeaderboardEntry(rank: 2, name: "Ravi", points: 1320),
    LeaderboardEntry(rank: 3, name: "Meena", points: 1205),
    LeaderboardEntry(rank: 4, name: "You", points: 1100, isYou: true),
    LeaderboardEntry(rank: 5, name: "Tharindu", points: 980),
    LeaderboardEntry(rank: 6, name: "Priya", points: 890),
    LeaderboardEntry(rank: 7, name: "Sanjay", points: 780),
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
    Reward(
      id: "r5",
      title: "Smart Showerhead",
      description: "Water-efficient showerhead",
      costPoints: 600,
      image: "https://picsum.photos/seed/shower/300/200",
    ),
    Reward(
      id: "r6",
      title: "Eco Workshop Pass",
      description: "Free sustainability workshop",
      costPoints: 350,
      image: "https://picsum.photos/seed/workshop/300/200",
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "Reward Redeemed!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B47),
              ),
            ),
          ],
        ),
        content: Text(
          "You successfully redeemed \"${reward.title}\" 🎉\n\nYour balance: $userPoints points",
          style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Awesome!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D7DD2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardDialog(int pts) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "Challenge Complete!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B47),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Amazing work! You've earned",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D7DD2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "+$pts Points",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D7DD2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Continue",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D7DD2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelUp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "Level Up!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B47),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Congratulations! You've reached",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF9A3D), Color(0xFFE87C0C)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "LEVEL $level",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Keep up the great work!",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Let's Go!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D7DD2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2D7DD2),
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
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          title: Text(
            "Eco Challenges",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A2B47),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Color(0xFF1A2B47)),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  "Challenges",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B47),
                  ),
                ),
              ),
              Tab(
                child: Text(
                  "Leaderboard",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B47),
                  ),
                ),
              ),
              Tab(
                child: Text(
                  "Rewards",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B47),
                  ),
                ),
              ),
            ],
            indicatorColor: const Color(0xFF2D7DD2),
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

  Widget _buildChallengesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Container(
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
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7DD2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: Color(0xFF2D7DD2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Your Progress",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Level Progress
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: xpProgress,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D7DD2)),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "Lv $level",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D7DD2),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${(xpProgress * 100).toInt()}%",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 10,
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
                          Text(
                            "Water Saver",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A2B47),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Eco Warrior",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.amber.shade600, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "$userPoints Points",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D7DD2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Streak
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7DD2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$streakDays days",
                            style: GoogleFonts.poppins(
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
                LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D7DD2)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Challenges Section
          Container(
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9A3D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: Color(0xFFFF9A3D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Active Challenges",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Challenges List
                Column(
                  children: challenges.map((challenge) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D7DD2).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.water_drop_outlined,
                                  color: Color(0xFF2D7DD2),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      challenge.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A2B47),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      challenge.description,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Progress Bar
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${challenge.currentLiters}L / ${challenge.goalLiters}L",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF2D7DD2),
                                              ),
                                            ),
                                            Text(
                                              "${((challenge.currentLiters / challenge.goalLiters) * 100).toInt()}%",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: (challenge.currentLiters / challenge.goalLiters) * (MediaQuery.of(context).size.width - 120),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF2D7DD2), Color(0xFF1A5FA6)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Points and Actions
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2D7DD2).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.bolt, size: 14, color: const Color(0xFF2D7DD2)),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${challenge.rewardPoints} pts",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF2D7DD2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        if (challenge.joined)
                                          Row(
                                            children: [
                                              OutlinedButton(
                                                onPressed: () => _logTenLiters(challenge.id),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF2D7DD2),
                                                  side: const BorderSide(color: Color(0xFF2D7DD2)),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                ),
                                                child: Text(
                                                  "+10L",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: () => _leaveChallenge(challenge.id),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(color: Colors.red),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                ),
                                                child: Text(
                                                  "Leave",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          ElevatedButton(
                                            onPressed: () => _joinChallenge(challenge.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2D7DD2),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            child: Text(
                                              "Join",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Container(
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
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7DD2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: Color(0xFF2D7DD2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Your Ranking",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: xpProgress,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D7DD2)),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "Lv $level",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D7DD2),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${(xpProgress * 100).toInt()}%",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rank #4",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A2B47),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Top 20% of savers",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.amber.shade600, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "$userPoints Points",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D7DD2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7DD2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "+2 spots",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Leaderboard Section
          Container(
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF764BA2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.leaderboard_outlined,
                        color: Color(0xFF764BA2),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Community Leaderboard",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Leaderboard List
                Column(
                  children: leaderboard.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: entry.isYou ? const Color(0xFF2D7DD2).withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: entry.isYou ? const Color(0xFF2D7DD2).withOpacity(0.3) : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _getRankColor(entry.rank),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                entry.rank.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name
                          Expanded(
                            child: Text(
                              entry.name,
                              style: GoogleFonts.poppins(
                                fontWeight: entry.isYou ? FontWeight.w700 : FontWeight.w500,
                                color: entry.isYou ? const Color(0xFF2D7DD2) : const Color(0xFF1A2B47),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          // Points
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D7DD2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${entry.points} pts",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D7DD2),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Container(
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
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7DD2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: Color(0xFF2D7DD2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Your Points",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: xpProgress,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D7DD2)),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "Lv $level",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D7DD2),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${(xpProgress * 100).toInt()}%",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$userPoints Points Available",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A2B47),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Redeem your points for eco-friendly rewards",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: userPoints / 1000,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D7DD2)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rewards Section
          Container(
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_outlined,
                        color: Color(0xFF00B894),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Available Rewards",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Rewards Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rewards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 220,
                  ),
                  itemBuilder: (context, index) => RewardCard(
                    reward: rewards[index],
                    userPoints: userPoints,
                    onRedeem: () => _redeemReward(rewards[index]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
        return const Color(0xFF2D7DD2); // Blue
    }
  }
}