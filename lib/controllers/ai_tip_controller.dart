// lib/features/ai_tips/controller/ai_tips_controller.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/ai_tip_model.dart';

class AiTipsController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch tips stored in Firestore (manual + AI saved tips)
  Future<List<AiTip>> fetchTips() async {
    final snapshot = await _db.collection("ai_tips").get();
    return snapshot.docs.map((d) => AiTip.fromMap(d.data(), d.id)).toList();
  }

  /// Save new AI tips into Firestore
  Future<void> saveTip(AiTip tip) async {
    await _db.collection("ai_tips").add(tip.toMap());
  }

  /// Call Gemini API to generate personalized tip
  Future<String> getAiRecommendation({
    required String category,
    required double usageValue,
  }) async {
    // ✅ Load API key securely
    const apiKey = String.fromEnvironment('GEMINI_API_KEY'); 
    if (apiKey.isEmpty) {
      throw Exception("Gemini API key is missing. Add --dart-define=GEMINI_API_KEY=YOUR_KEY when building.");
    }

    // ✅ Use correct v1 endpoint
    final endpoint =
        "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey";

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "User water usage in $category is $usageValue litres/week. Suggest a practical tip to reduce usage, short and actionable."
            }
          ]
        }
      ]
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final tip =
          json["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";
      return tip.isNotEmpty ? tip : "No tip generated. Try again.";
    } else {
      throw Exception(
          "Gemini API error: ${response.statusCode} - ${response.body}");
    }
  }
}
