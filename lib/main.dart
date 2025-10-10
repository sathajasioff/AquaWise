// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_gemini/flutter_gemini.dart';
// <<<<<<< HEAD
// import 'package:watermeter/screens/AI/AItips.dart';
// import 'package:watermeter/screens/Login/login.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// =======
// import 'package:provider/provider.dart';
// import 'package:watermeter/controllers/theme_controller.dart';
// import 'package:watermeter/screens/AI/AItipOP.dart';
// import 'package:watermeter/screens/AI/AItips.dart';
// import 'package:watermeter/screens/About/about.dart';
// import 'package:watermeter/screens/Login/login.dart';
// import 'package:watermeter/screens/Home/dashboard_view.dart';
// import 'package:watermeter/screens/Privacy/privacy.dart';
// import 'package:watermeter/screens/Profile/profile.dart';
// import 'package:watermeter/screens/Profile/edit_profile_page.dart';
// import 'package:watermeter/screens/Questionnaire/quesScreen_1.dart';
// import 'package:watermeter/screens/SignUp/signup.dart';
// >>>>>>> UserManagement

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   await dotenv.load(fileName: ".env");

// <<<<<<< HEAD
//   // Get keys
//   final geminiKey = dotenv.env['GEMINI_API_KEY'];
//   final weatherKey = dotenv.env['OPENWEATHER_API_KEY'];

//   if (geminiKey == null || geminiKey.isEmpty) {
//     throw Exception('❌ GEMINI_API_KEY missing in .env');
//   }
//   if (weatherKey == null || weatherKey.isEmpty) {
//     throw Exception('❌ OPENWEATHER_API_KEY missing in .env');
// =======
//   final apiKey = dotenv.env['GEMINI_API_KEY'];
//   if (apiKey == null || apiKey.isEmpty) {
//     throw Exception('GEMINI_API_KEY is missing in .env');
// >>>>>>> UserManagement
//   }

//   // Initialize Gemini
//   await Gemini.init(apiKey: geminiKey);
//   print('✅ Gemini initialized successfully');
//   print('🌤 OpenWeather Key: ${weatherKey.substring(0, 4)}****');
//   print('🤖 Gemini Key: ${geminiKey.substring(0, 4)}****');

//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => ThemeController()..loadUserTheme(),
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeController = Provider.of<ThemeController>(context);

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'WaterMeter',
//       themeMode: themeController.themeMode, // ✅ controlled by provider
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176ED2)),
//         useMaterial3: true,
//       ),
// <<<<<<< HEAD
//       home: const AuthWrapper(),
//       routes: {
//         '/aitips': (context) => const AIPersonalizationPage(),
//       },
//     );
//   }
// }

// /// Checks user login
// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   Future<bool> _isLoggedIn() async {
//     return FirebaseAuth.instance.currentUser != null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<bool>(
//       future: _isLoggedIn(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//         return snapshot.data! ? const AIPersonalizationPage() : const LoginPage();
// =======
//       darkTheme: ThemeData.dark(useMaterial3: true),
//       home: const LoginPage(),
//       routes: {
//         '/dashboard': (context) => const DashboardView(),
//         '/signup': (context) => const SignupPage(),
//         '/login': (context) => const LoginPage(),
//         '/questionnaire1': (context) => QuestionnairePage(),
//         '/profile': (context) => const ProfilePage(),
//         '/edit_profile': (context) => const EditProfilePage(),
//         '/privacy_policy' : (context) => const PrivacyPolicyPage(),
//         '/about' : (context) => const AboutPage(),
//         '/aitips' : (context) => const AIPersonalizationPage(),
//         // '/report' : (context) => const ReportGeneratorPage(),
        
// >>>>>>> UserManagement
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Controllers
import 'package:watermeter/controllers/theme_controller.dart';

// Screens
// import 'package:watermeter/screens/AI/AItipOP.dart';
import 'package:watermeter/screens/AI/AItips.dart';
import 'package:watermeter/screens/About/about.dart';
import 'package:watermeter/screens/ForgotPassword/forgotPassword.dart';
import 'package:watermeter/screens/Gamification/gamification.dart';
import 'package:watermeter/screens/Login/login.dart';
import 'package:watermeter/screens/Home/dashboard_view.dart';
import 'package:watermeter/screens/Privacy/privacy.dart';
import 'package:watermeter/screens/Profile/profile.dart';
import 'package:watermeter/screens/Profile/edit_profile_page.dart';
import 'package:watermeter/screens/Questionnaire/quesScreen_1.dart';
import 'package:watermeter/screens/SignUp/signup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");

  // ✅ Load keys safely
  final geminiKey = dotenv.env['GEMINI_API_KEY'];
  final weatherKey = dotenv.env['OPENWEATHER_API_KEY'];

  if (geminiKey == null || geminiKey.isEmpty) {
    throw Exception('❌ GEMINI_API_KEY missing in .env');
  }
  if (weatherKey == null || weatherKey.isEmpty) {
    throw Exception('❌ OPENWEATHER_API_KEY missing in .env');
  }

  // Initialize Gemini
  await Gemini.init(apiKey: geminiKey);
  print('✅ Gemini initialized successfully');
  print('🌤 OpenWeather Key: ${weatherKey.substring(0, 4)}****');
  print('🤖 Gemini Key: ${geminiKey.substring(0, 4)}****');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController()..loadUserTheme(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WaterMeter',
      themeMode: themeController.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176ED2)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const LoginPage(),
      routes: {
        '/dashboard': (context) => const DashboardView(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/questionnaire1': (context) => QuestionnairePage(),
        '/profile': (context) => const ProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/privacy_policy': (context) => const PrivacyPolicyPage(),
        '/about': (context) => const AboutPage(),
        '/aitips': (context) => const AIPersonalizationPage(),
        // '/report' : (context) => const ReportGeneratorPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/gamification': (context) => const GamificationScreen(),
        
      },
    );
  }
}

/// ✅ Auth wrapper to check user login before showing pages
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isLoggedIn() async {
    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!
            ? const DashboardView() // Logged in users go to dashboard
            : const LoginPage();    // Non-logged in users go to login
      },
    );
  }
}
