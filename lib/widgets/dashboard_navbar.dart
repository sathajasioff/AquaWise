import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/Login/login.dart';
import '../screens/Home/dashboard_view.dart';
import '../settings/settings.dart';
import '../screens/Profile/profile.dart';
// Import your community page
import '../screens/Community/community_feed.dart'; // Make sure to import your community page

class DashboardNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DashboardNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0: // Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
        break;

      case 1: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;

      case 2: // Community (replaced Logout)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CommunityScreen()), 
        );
        break;

      case 3: // Settings
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _handleNavigation(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people), // Changed from logout to people icon
          label: "Community",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
    );
  }
}