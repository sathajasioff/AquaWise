import 'package:flutter/material.dart';
import '../models/reward.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final int userPoints;
  final VoidCallback onRedeem;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final canRedeem = userPoints >= reward.costPoints;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image (optional)
          if (reward.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                reward.image!,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  alignment: Alignment.center,
                  color: Colors.grey[200],
                  child: const Icon(Icons.card_giftcard),
                ),
              ),
            ),
          if (reward.image != null) const SizedBox(height: 10),
          Text(
            reward.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            reward.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF176ED2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${reward.costPoints} pts",
                  style: const TextStyle(
                    color: Color(0xFF176ED2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: canRedeem ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem ? Colors.green[700] : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: const Text("Redeem"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
