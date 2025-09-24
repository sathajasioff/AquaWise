import 'package:flutter/material.dart';
import '../models/challenge.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onLog10L; // quick +10L button

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onJoin,
    required this.onLeave,
    required this.onLog10L,
  });

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return Card(
      elevation: 2,
      shape: border,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title + reward
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF176ED2).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "+${challenge.rewardPoints} pts",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF176ED2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              challenge.description,
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 12),

            // progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: challenge.progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${challenge.currentLiters}/${challenge.goalLiters} L saved • ${(challenge.progress * 100).toStringAsFixed(0)}%",
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),

            const SizedBox(height: 12),

            // actions
            Row(
              children: [
                if (!challenge.joined)
                  ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176ED2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Join"),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: onLeave,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Leave"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onLog10L,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("+10L saved"),
                  ),
                ],
                const Spacer(),
                if (challenge.completed)
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text("Completed", style: TextStyle(color: Colors.green)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
