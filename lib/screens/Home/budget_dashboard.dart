import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';

class BudgetDashboard extends StatefulWidget {
  final DashboardController controller;
  const BudgetDashboard({super.key, required this.controller});

  @override
  State<BudgetDashboard> createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends State<BudgetDashboard> {
  double? _moneyBudget;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final v = await widget.controller.getMoneyBudgetRs();
    setState(() => _moneyBudget = v);
  }

  void _setMoneyBudget() {
    final txt = TextEditingController(text: _moneyBudget?.toStringAsFixed(0) ?? "");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Monthly Money Budget (Rs)"),
        content: TextField(
          controller: txt,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "e.g. 1200"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final v = double.tryParse(txt.text.trim());
              if (v != null) {
                await widget.controller.setMoneyBudgetRs(v);
                setState(() => _moneyBudget = v);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: widget.controller.monthlyTotalLiters(),
      builder: (context, snap) {
        final usedL = snap.data ?? 0;
        final bill = widget.controller.estimateBillRs(usedL);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("💰 Budget Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _line("This month usage", "${usedL.toStringAsFixed(0)} L"),
            _line("Bill forecast", "Rs ${bill.toStringAsFixed(2)}"),
            _line("Monthly money budget", _moneyBudget != null ? "Rs ${_moneyBudget!.toStringAsFixed(0)}" : "—"),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _setMoneyBudget,
              icon: const Icon(Icons.savings),
              label: const Text("Set Money Budget"),
            ),
          ],
        );
      },
    );
  }

  Widget _line(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(a), Text(b, style: const TextStyle(fontWeight: FontWeight.w600))],
    ),
  );
}
