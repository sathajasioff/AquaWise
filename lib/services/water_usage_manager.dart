import 'package:watermeter/services/firebase_user_service.dart';

class WaterUsageManager {
  // Simulate water usage data (in a real app, this would come from IoT devices)
  static final Map<String, double> _usagePatterns = {
    'shower': 65.0, // liters per 10-minute shower
    'faucet': 8.0,  // liters per minute
    'toilet': 6.0,  // liters per flush
    'dishwasher': 15.0, // liters per load
    'washing_machine': 50.0, // liters per load
  };

  // Add water usage for a specific activity
  static Future<void> logWaterUsage(String activity, {int quantity = 1, double? customAmount}) async {
    try {
      // First, ensure we have the dailyUsage structure
      await FirebaseUserService.getTodayWaterUsage();
      
      double usageAmount;
      
      if (customAmount != null) {
        usageAmount = customAmount;
      } else {
        final baseUsage = _usagePatterns[activity] ?? 0.0;
        usageAmount = baseUsage * quantity;
      }
      
      // Get current usage for today
      final currentUsage = await FirebaseUserService.getTodayWaterUsage();
      final newTotalUsage = currentUsage + usageAmount;
      
      // Update in Firebase
      await FirebaseUserService.updateDailyWaterUsage(newTotalUsage);
      
      print('✅ Logged $usageAmount liters for $activity (quantity: $quantity)');
      print('✅ Total usage now: $newTotalUsage liters');
    } catch (e) {
      print('❌ Error logging water usage: $e');
      rethrow;
    }
  }
  // Get recommended daily usage (WHO recommendation: 50-100 liters per person)
  static double getRecommendedDailyUsage() {
    return 80.0; // liters per day
  }

  // Calculate water saving percentage
  static double calculateSavingPercentage(double actualUsage) {
    final recommended = getRecommendedDailyUsage();
    if (actualUsage <= recommended) {
      return ((recommended - actualUsage) / recommended) * 100;
    } else {
      return -((actualUsage - recommended) / recommended) * 100;
    }
  }

  // Get usage message based on consumption
  static String getUsageMessage(double usage) {
    final recommended = getRecommendedDailyUsage();
    
    if (usage <= recommended * 0.5) {
      return 'Excellent water saving! 🌟';
    } else if (usage <= recommended * 0.8) {
      return 'Great water usage! 💧';
    } else if (usage <= recommended) {
      return 'Good job! Within recommended limits ✅';
    } else if (usage <= recommended * 1.2) {
      return 'Slightly above average';
    } else {
      return 'Consider reducing water usage';
    }
  }

  // Get water saving tips
  static List<String> getWaterSavingTips(double currentUsage) {
    final tips = <String>[];
    final recommended = getRecommendedDailyUsage();
    
    if (currentUsage > recommended) {
      tips.addAll([
        'Take shorter showers (saves ~30L per 5 minutes)',
        'Fix leaky faucets (saves ~75L per week)',
        'Use dishwasher only when full (saves ~15L per load)',
        'Turn off tap while brushing teeth (saves ~8L per minute)',
      ]);
    } else {
      tips.addAll([
        'Great job! You\'re saving water effectively',
        'Consider installing water-efficient fixtures',
        'Collect rainwater for plants',
        'Water plants in the morning to reduce evaporation',
      ]);
    }
    
    return tips;
  }
}