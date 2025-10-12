// lib/features/ai_tips/view/ai_tips_page.dart
import 'package:flutter/material.dart';
import '../../controllers/ai_tip_controller.dart';
import '../../models/ai_tip_model.dart';

class AiTipsPage extends StatefulWidget {
  const AiTipsPage({super.key});

  @override
  State<AiTipsPage> createState() => _AiTipsPageState();
}

class _AiTipsPageState extends State<AiTipsPage> {
  final _controller = AiTipsController();
  List<AiTip> _tips = [];
  bool _loading = true;
  String _aiResponse = "";

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    final tips = await _controller.fetchTips();
    setState(() {
      _tips = tips;
      _loading = false;
    });
  }

  Future<void> _askAi(String category, double usage) async {
    setState(() => _aiResponse = "Thinking...");
    try {
      final result =
          await _controller.getAiRecommendation(category: category, usageValue: usage);
      setState(() => _aiResponse = result);
    } catch (e) {
      setState(() => _aiResponse = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Tips")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text("Saved Tips", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._tips.map((tip) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(tip.category),
                        subtitle: Text(tip.description),
                        trailing: Text("${tip.estimatedSaveLitres}L"),
                      ),
                    )),
                const Divider(height: 32),
                const Text("Ask Gemini AI",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _askAi("Shower", 200),
                  icon: const Icon(Icons.shower_outlined),
                  label: const Text("Suggest Shower Tip"),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _askAi("Laundry", 100),
                  icon: const Icon(Icons.local_laundry_service_outlined),
                  label: const Text("Suggest Laundry Tip"),
                ),
                if (_aiResponse.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _aiResponse,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ]
              ],
            ),
    );
  }
}
