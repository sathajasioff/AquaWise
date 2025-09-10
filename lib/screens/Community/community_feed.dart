import 'package:flutter/material.dart';

void main() => runApp(const AquaCardApp());

class AquaCardApp extends StatelessWidget {
  const AquaCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const UsageScreen(),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  // 0: Community, 1: Group Challenges, 2: Leaderboard
  int selected = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented pills
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0B2540),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _SegmentedPills(
                  selectedIndex: selected,
                  onChanged: (i) => setState(() => selected = i),
                  items: const [
                    PillItem(icon: Icons.chat_bubble_outline, label: 'Community Feed'),
                    PillItem(icon: Icons.emoji_events_outlined, label: 'Group Challenges'),
                    PillItem(icon: Icons.leaderboard_outlined, label: 'Leaderboard'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Your fixed usage card
              const WaterUsageCard(
                title: "Today's Usage",
                valueText: "245L",
                subText: "12% below average",
              ),

              const SizedBox(height: 20),

              // Header pill card (changes per tab)
              GradientPillCard(
                icon: selected == 0
                    ? Icons.chat_bubble_outline
                    : selected == 1
                        ? Icons.group_outlined
                        : Icons.leaderboard_outlined,
                title: selected == 0
                    ? 'Community Feed'
                    : selected == 1
                        ? 'Group Challenges'
                        : 'Leaderboard',
                subtitle: selected == 0
                    ? 'See what your community is talking about'
                    : selected == 1
                        ? 'Compete and collaborate with your community'
                        : 'Track rankings and achievements',
              ),

              const SizedBox(height: 16),

              // ===== Content by tab =====
              if (selected == 1) ...[
                const SizedBox(height: 8),
                ChallengeCard(
                  title: 'Apartment Block Challenge',
                  description:
                      'All apartments in Building A compete to save the most water this month',
                  participantsCount: 24,
                  progressCurrentLiters: 3200,
                  progressGoalLiters: 5000,
                  rewardText: 'Reward: Building garden upgrade fund',
                  endDateLabel: 'Ends 04/09/2025',
                  onJoin: () {},
                ),
                const SizedBox(height: 14),
                ChallengeCard(
                  title: 'Street Cleanup Water-Saver',
                  description:
                      'Neighbors on Maple Street team up to reduce hose usage on driveways',
                  participantsCount: 12,
                  progressCurrentLiters: 1800,
                  progressGoalLiters: 3000,
                  rewardText: 'Reward: Community picnic sponsorship',
                  endDateLabel: 'Ends 18/09/2025',
                  onJoin: () {},
                ),
                const SizedBox(height: 16),

                // Create a Challenge (dashed)
                CreateChallengeCard(
                  title: 'Create a Challenge',
                  subtitle: 'Start a custom challenge for your family, friends, or building',
                  onTap: () {
                    // TODO: navigate to creation flow
                  },
                ),
              ],

              if (selected == 0)
                const _PlaceholderCard(text: 'Community posts will appear here.'),

              if (selected == 2)
                LeaderboardCard(
                  entries: const [
                    LeaderboardEntry(
                      rank: 1,
                      name: 'Emma Wilson',
                      litersSaved: 2840,
                      points: 1250,
                      trend: Trend.rising,
                    ),
                    LeaderboardEntry(
                      rank: 2,
                      name: 'David Park',
                      litersSaved: 2650,
                      points: 1180,
                      trend: Trend.same,
                    ),
                    LeaderboardEntry(
                      rank: 3,
                      name: 'Sarah Chen',
                      litersSaved: 2100,
                      points: 980,
                      trend: Trend.rising,
                    ),
                    LeaderboardEntry(
                      rank: 4,
                      name: 'You',
                      litersSaved: 1890,
                      points: 850,
                      trend: Trend.rising,
                      isCurrentUser: true,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------- REUSABLE WIDGETS -----------------

class WaterUsageCard extends StatelessWidget {
  final String title;
  final String valueText;
  final String subText;

  const WaterUsageCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C62FF), Color(0xFF5AA6FF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330C62FF),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Today's Usage",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                Icon(Icons.water_drop_outlined, color: Colors.white, size: 25),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valueText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Opacity(
              opacity: 0.9,
              child: Text(
                subText,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PillItem {
  final IconData icon;
  final String label;
  const PillItem({required this.icon, required this.label});
}

class _SegmentedPills extends StatelessWidget {
  final List<PillItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedPills({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const _borderColor = Color(0xFFE6EEF6);
  static const _textColor = Color(0xFF16324C);
  static const _selectedGradient = [Color(0xFF22A4FF), Color(0xFF0F84FF)];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(items.length, (i) {
        final isSelected = i == selectedIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _selectedGradient,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected ? null : Border.all(color: _borderColor, width: 1.2),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Color(0x330F84FF), blurRadius: 10, offset: Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i].icon, size: 20, color: isSelected ? Colors.white : const Color(0xFF3A5A78)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class GradientPillCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const GradientPillCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const _gradient =
      LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF22A4FF), Color(0xFF0F84FF)]);

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x330F84FF), blurRadius: 16, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x66FFFFFF), blurRadius: 10, spreadRadius: -2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 14.5, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Challenge Card =====
class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final int participantsCount;
  final double progressCurrentLiters;
  final double progressGoalLiters;
  final String rewardText;
  final String endDateLabel;
  final VoidCallback onJoin;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.participantsCount,
    required this.progressCurrentLiters,
    required this.progressGoalLiters,
    required this.rewardText,
    required this.endDateLabel,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (progressCurrentLiters / progressGoalLiters).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + participants badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF16324C))),
              ),
              _ParticipantsBadge(count: participantsCount),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.4),
          ),
          const SizedBox(height: 14),

          // Progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progress",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              Text("${progressCurrentLiters.toStringAsFixed(0)} / ${progressGoalLiters.toStringAsFixed(0)} L saved",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
            ),
          ),

          const SizedBox(height: 16),

          // Reward + CTA
          Row(
            children: [
              // Reward text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rewardText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text(endDateLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _JoinButton(onPressed: onJoin),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParticipantsBadge extends StatelessWidget {
  final int count;
  const _ParticipantsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ADE80), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$count ",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const TextSpan(
              text: "participants",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _JoinButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.group_add_outlined, size: 18),
      label: const Text("Join Challenge"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

/// ===== Create a Challenge (Dashed Border) =====
class CreateChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const CreateChallengeCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2FA6FF);
    const radius = 16.0;

    final content = SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 36, color: blue),
            SizedBox(height: 10),
            Text(
              'Create a Challenge',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16324C),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Start a custom challenge for your family, friends, or building',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5B7288),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );

    final dashed = CustomPaint(
      painter: _DashedBorderPainter(
        color: blue.withOpacity(0.6),
        strokeWidth: 2,
        dashLength: 10,
        dashGap: 6,
        radius: radius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          color: Colors.white,
          child: content,
        ),
      ),
    );

    if (onTap == null) return dashed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: dashed,
      ),
    );
  }
}

/// Painter for dashed rounded rectangle
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromLTRBR(0, 0, size.width, size.height, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        final segment = metric.extractPath(distance, next.clamp(0, metric.length));
        canvas.drawPath(segment, paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      color != old.color ||
      strokeWidth != old.strokeWidth ||
      dashLength != old.dashLength ||
      dashGap != old.dashGap ||
      radius != old.radius;
}

/// ===== Leaderboard =====

enum Trend { rising, same, falling }

class LeaderboardEntry {
  final int rank;
  final String name;
  final int litersSaved;
  final int points;
  final Trend trend;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.litersSaved,
    required this.points,
    required this.trend,
    this.isCurrentUser = false,
  });
}

class LeaderboardCard extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const LeaderboardCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final isLast = i == entries.length - 1;
          return _LeaderboardRow(entry: e, showDivider: !isLast);
        }),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool showDivider;

  const _LeaderboardRow({required this.entry, required this.showDivider});

  Color _trendColor(Trend t) {
    switch (t) {
      case Trend.rising:
        return const Color(0xFF16A34A);
      case Trend.same:
        return const Color(0xFF6B7280);
      case Trend.falling:
        return const Color(0xFFDC2626);
    }
  }

  IconData _trendIcon(Trend t) {
    switch (t) {
      case Trend.rising:
        return Icons.trending_up;
      case Trend.same:
        return Icons.horizontal_rule_rounded;
      case Trend.falling:
        return Icons.trending_down;
    }
  }

  Widget _rankBadge() {
    if (entry.rank == 1) {
      return const Icon(Icons.emoji_events_outlined, color: Color(0xFFF4B400), size: 22); // gold
    } else if (entry.rank == 2) {
      return const Icon(Icons.emoji_events_outlined, color: Color(0xFF9CA3AF), size: 22); // silver
    } else if (entry.rank == 3) {
      return const Icon(Icons.emoji_events_outlined, color: Color(0xFFF59E0B), size: 22); // bronze
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFEFF6FF),
          border: Border.all(color: const Color(0xFF3B82F6)),
        ),
        child: Text(
          '#${entry.rank}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D4ED8),
            fontSize: 12,
          ),
        ),
      );
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final row = Container(
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? const Color(0xFFEFFBFF) : Colors.white,
        borderRadius: entry.isCurrentUser ? BorderRadius.circular(12) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 34, child: Center(child: _rankBadge())),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F5F9)),
            alignment: Alignment.center,
            child: Text(
              _initials(entry.name),
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('${entry.litersSaved}L saved this month',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.points} pts',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F84FF))),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_trendIcon(entry.trend), size: 16, color: _trendColor(entry.trend)),
                  const SizedBox(width: 4),
                  Text(
                    entry.trend == Trend.rising
                        ? 'Rising'
                        : entry.trend == Trend.same
                            ? 'Same'
                            : 'Falling',
                    style: TextStyle(fontSize: 12, color: _trendColor(entry.trend), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      children: [
        row,
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}

/// Placeholder for other tabs
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
        boxShadow: const [BoxShadow(color: Color(0x0F0B2540), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF16324C), height: 1.35)),
    );
  }
}
