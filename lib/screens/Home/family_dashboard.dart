import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/dashboard_controller.dart';

class FamilyDashboard extends StatefulWidget {
  final DashboardController controller;
  const FamilyDashboard({super.key, required this.controller});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberBudgetController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showAddMemberForm = false;

  @override
  Widget build(BuildContext context) {
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
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.family_restroom, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Family Dashboard",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2B47),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Manage family members and track individual usage",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showAddMemberForm = !_showAddMemberForm;
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF176ED2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Add Family Member Form
          if (_showAddMemberForm) _buildAddMemberForm(),

          // Family Summary Card
          StreamBuilder<Map<String, dynamic>>(
            stream: _getFamilyMembersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _buildLoadingCard();
              }
              
              final familyData = snap.data ?? {};
              final totalFamilyBudget = _calculateTotalFamilyBudget(familyData);
              final totalFamilyUsage = _calculateTotalFamilyUsage(familyData);
              final totalMembers = familyData.length;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F84FF), Color(0xFF2DD4BF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$totalMembers Family Member${totalMembers == 1 ? '' : 's'}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total Budget: ${totalFamilyBudget.toStringAsFixed(0)}L",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Total Used: ${totalFamilyUsage.toStringAsFixed(0)}L",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        totalFamilyBudget > 0 
                            ? "${((totalFamilyUsage / totalFamilyBudget) * 100).clamp(0, 100).toStringAsFixed(0)}%"
                            : "0%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Family Members Grid
          const Text(
            "Family Members",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B47),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<Map<String, dynamic>>(
            stream: _getFamilyMembersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _buildMembersLoading();
              }
              
              final familyData = snap.data ?? {};
              if (familyData.isEmpty) {
                return _buildEmptyState();
              }

              final members = familyData.entries.toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85, // Further reduced to prevent overflow
                ),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return _buildMemberCard(member.key, member.value);
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Usage Breakdown Section
          const Text(
            "Usage Breakdown",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B47),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "See how each family member is contributing to total usage",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<Map<String, double>>(
            stream: widget.controller.familyBreakdownThisMonth(),
            builder: (context, snap) {
              final map = snap.data ?? {};
              if (map.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.water_drop_outlined, 
                          color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        "No usage data yet",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Start tracking water usage to see breakdown here",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final items = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              final totalUsage = items.fold(0.0, (sum, item) => sum + item.value);

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int index = 0; index < items.length; index++)
                      Container(
                        margin: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getMemberColor(items[index].key).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person,
                                color: _getMemberColor(items[index].key),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    items[index].key,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  LinearProgressIndicator(
                                    value: (items[index].value / totalUsage).clamp(0, 1),
                                    backgroundColor: Colors.grey.shade200,
                                    color: _getMemberColor(items[index].key),
                                    minHeight: 5,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${items[index].value.toStringAsFixed(1)} L",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "${((items[index].value / totalUsage) * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAddMemberForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Family Member",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2B47),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _memberNameController,
                  decoration: InputDecoration(
                    labelText: "Member Name",
                    hintText: "e.g., John, Sarah",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _memberBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Monthly Budget (Liters)",
                    hintText: "e.g., 1000",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: "L",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showAddMemberForm = false;
                      _memberNameController.clear();
                      _memberBudgetController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addFamilyMember,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text("Add Member"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176ED2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(String memberName, Map<String, dynamic> memberData) {
    final memberBudget = (memberData['budget'] ?? 0).toDouble();
    final memberUsage = (memberData['usage'] ?? 0).toDouble();
    final remainingBudget = memberBudget - memberUsage;
    final usagePercentage = memberBudget > 0 ? (memberUsage / memberBudget).clamp(0, 1) : 0;
    final isOverBudget = remainingBudget < 0;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 140,
        maxHeight: 140, // Fixed height to prevent overflow
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row with icon and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getMemberColor(memberName).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _getMemberColor(memberName),
                    size: 18,
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.water_drop, size: 16),
                          SizedBox(width: 6),
                          Text("Log Water Usage", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onTap: () => _logWaterUsageForMember(memberName),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 6),
                          Text("Remove", style: TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                      onTap: () => _deleteFamilyMember(memberName),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Member name
            Text(
              memberName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B47),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Progress bar
            LinearProgressIndicator(
              value: usagePercentage,
              backgroundColor: Colors.grey.shade200,
              color: isOverBudget ? Colors.red : _getMemberColor(memberName),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 6),
            
            // Usage and Budget row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${memberUsage.toStringAsFixed(0)}L",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Used",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${memberBudget.toStringAsFixed(0)}L",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Budget",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isOverBudget ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isOverBudget ? Colors.red.shade100 : Colors.green.shade100,
                ),
              ),
              child: Text(
                isOverBudget ? "Over Budget" : "On Track",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: isOverBudget ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F84FF), Color(0xFF2DD4BF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 16),
          Text(
            "Loading family data...",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersLoading() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.family_restroom_outlined, 
              color: Colors.grey.shade400, size: 64),
          const SizedBox(height: 16),
          const Text(
            "No Family Members Added",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2B47),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add your first family member to start tracking\nindividual water usage",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAddMemberForm = true;
              });
            },
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text("Add First Member"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF176ED2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMemberColor(String memberName) {
    final colors = [
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
      const Color(0xFF0F84FF),
      const Color(0xFF2DD4BF),
      const Color(0xFFFF9A3D),
      const Color(0xFFFF6B6B),
    ];
    final index = memberName.hashCode % colors.length;
    return colors[index];
  }

  // ... Keep all other methods the same (_addFamilyMember, _deleteFamilyMember, etc.)
  Future<void> _addFamilyMember() async {
    final memberName = _memberNameController.text.trim();
    final budgetText = _memberBudgetController.text.trim();

    if (memberName.isEmpty || budgetText.isEmpty) {
      _showSnackBar("Please enter both name and budget");
      return;
    }

    final budget = double.tryParse(budgetText);
    if (budget == null || budget <= 0) {
      _showSnackBar("Please enter a valid budget amount");
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final currentFamilyData = await _getFamilyMembersData();
      final currentTotalBudget = _calculateTotalFamilyBudget(currentFamilyData);
      final newTotalBudget = currentTotalBudget + budget;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('family_members')
          .doc(memberName)
          .set({
            'name': memberName,
            'budget': budget,
            'created_at': FieldValue.serverTimestamp(),
            'usage': 0.0,
          });

      _memberNameController.clear();
      _memberBudgetController.clear();
      setState(() {
        _showAddMemberForm = false;
      });
      _showSnackBar("$memberName added to family!");
      FocusScope.of(context).unfocus();
    } catch (e) {
      _showSnackBar("Error adding family member: $e");
    }
  }

  Future<void> _deleteFamilyMember(String memberName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Family Member"),
        content: Text("Are you sure you want to remove $memberName from your family?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('family_members')
            .doc(memberName)
            .delete();
        
        _showSnackBar("$memberName removed from family");
      } catch (e) {
        _showSnackBar("Error deleting family member: $e");
      }
    }
  }

  Future<void> _logWaterUsageForMember(String memberName) async {
    final TextEditingController litersController = TextEditingController();
    final TextEditingController activityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Log Water Usage for $memberName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: activityController,
              decoration: const InputDecoration(
                labelText: "Activity",
                hintText: "e.g., Shower, Cooking, Cleaning",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: litersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Liters Used",
                hintText: "e.g., 50",
                border: OutlineInputBorder(),
                suffixText: "L",
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
              final activity = activityController.text.trim();
              final litersText = litersController.text.trim();
              
              if (activity.isEmpty || litersText.isEmpty) {
                _showSnackBar("Please enter both activity and liters");
                return;
              }

              final liters = double.tryParse(litersText);
              if (liters == null || liters <= 0) {
                _showSnackBar("Please enter valid liters amount");
                return;
              }

              try {
                await widget.controller.logWaterUsage(activity, liters, memberName: memberName);
                
                final user = _auth.currentUser;
                if (user != null) {
                  final memberRef = _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('family_members')
                      .doc(memberName);

                  await memberRef.update({
                    'usage': FieldValue.increment(liters),
                    'last_updated': FieldValue.serverTimestamp(),
                  });
                }

                Navigator.pop(context);
                _showSnackBar("Logged $liters L for $memberName's $activity");
              } catch (e) {
                _showSnackBar("Error logging usage: $e");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF176ED2),
            ),
            child: const Text("Log Usage"),
          ),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>> _getFamilyMembersStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('family_members')
        .snapshots()
        .map((snapshot) {
          final Map<String, dynamic> familyData = {};
          for (final doc in snapshot.docs) {
            familyData[doc.id] = doc.data();
          }
          return familyData;
        });
  }

  Future<Map<String, dynamic>> _getFamilyMembersData() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('family_members')
        .get();

    final Map<String, dynamic> familyData = {};
    for (final doc in snapshot.docs) {
      familyData[doc.id] = doc.data();
    }
    return familyData;
  }

  double _calculateTotalFamilyBudget(Map<String, dynamic> familyData) {
    return familyData.values.fold(0.0, (sum, memberData) {
      final data = memberData as Map<String, dynamic>;
      return sum + (data['budget'] ?? 0).toDouble();
    });
  }

  double _calculateTotalFamilyUsage(Map<String, dynamic> familyData) {
    return familyData.values.fold(0.0, (sum, memberData) {
      final data = memberData as Map<String, dynamic>;
      return sum + (data['usage'] ?? 0).toDouble();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF176ED2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}