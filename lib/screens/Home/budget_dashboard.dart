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
        title: const Text("Set Monthly Money Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your monthly water budget in rupees",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: txt,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g. 1200",
                prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final v = double.tryParse(txt.text.trim());
              if (v != null) {
                await widget.controller.setMoneyBudgetRs(v);
                setState(() => _moneyBudget = v);
              }
              Navigator.pop(context);
            },
            child: const Text("Save Budget"),
          ),
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
        final remainingBudget = _moneyBudget != null ? _moneyBudget! - bill : 0;
        final isOverBudget = _moneyBudget != null && bill > _moneyBudget!;
        final budgetPercentage = _moneyBudget != null && _moneyBudget! > 0 
            ? (bill / _moneyBudget!).clamp(0, 1) 
            : 0;

        return Container(
          width: double.infinity,
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
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9A3D), Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Budget Dashboard",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Track your water expenses and budget",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Budget Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isOverBudget ? Colors.red.shade50 : Colors.green.shade50,
                      isOverBudget ? Colors.orange.shade50 : Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOverBudget ? Colors.red.shade100 : Colors.green.shade100,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Budget Utilization",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOverBudget ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOverBudget ? "Over Budget" : "On Track",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        LinearProgressIndicator(
                          value: budgetPercentage.toDouble(),
                          minHeight: 16,
                          backgroundColor: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOverBudget ? Colors.red : const Color(0xFF2D7DD2),
                          ),
                        ),
                        if (budgetPercentage > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${(budgetPercentage * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                        Text(
                          "Rs ${bill.toStringAsFixed(0)} / Rs ${_moneyBudget?.toStringAsFixed(0) ?? '0'}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Financial Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _FinancialRow(
                      icon: Icons.water_drop,
                      iconColor: Colors.blue,
                      title: "Water Usage",
                      value: "${usedL.toStringAsFixed(0)} L",
                    ),
                    const SizedBox(height: 12),
                    _FinancialRow(
                      icon: Icons.receipt_long,
                      iconColor: Colors.orange,
                      title: "Estimated Bill",
                      value: "Rs ${bill.toStringAsFixed(2)}",
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 12),
                    _FinancialRow(
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.purple,
                      title: "Monthly Budget",
                      value: _moneyBudget != null ? "Rs ${_moneyBudget!.toStringAsFixed(0)}" : "Not set",
                    ),
                    if (_moneyBudget != null) ...[
                      const SizedBox(height: 12),
                      _FinancialRow(
                        icon: Icons.account_balance,
                        iconColor: isOverBudget ? Colors.red : Colors.green,
                        title: isOverBudget ? "Over Budget" : "Remaining",
                        value: "Rs ${remainingBudget.toStringAsFixed(0)}",
                        isHighlighted: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Set Budget Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _setMoneyBudget,
                  icon: const Icon(Icons.savings, size: 20),
                  label: const Text(
                    "Set Money Budget",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9A3D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),

              // Tip Section
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Set a budget to track your water expenses and save money",
                        style: TextStyle(
                          color: Color(0xFF1A2B47),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isHighlighted;

  const _FinancialRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              color: const Color(0xFF1A2B47),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? const Color(0xFFFF9A3D) : const Color(0xFF1A2B47),
          ),
        ),
      ],
    );
  }
}