import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, Settings;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:watermeter/controllers/theme_controller.dart';
import 'package:watermeter/screens/Home/dashboard_view.dart' show DashboardView;

// Import your screens
import 'package:watermeter/screens/Login/login.dart';
import 'package:watermeter/screens/Home/dashboard_1.dart';
import 'package:watermeter/screens/Profile/edit_profile_page.dart';
import 'package:watermeter/screens/Profile/profile.dart';
import 'package:watermeter/screens/Questionnaire/quesScreen_1.dart';
import 'package:watermeter/screens/SignUp/signup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Load environment variables
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Gemini
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY is missing in .env');
  }
  await Gemini.init(apiKey: apiKey);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  /// Load theme from Firestore or local pref (optional future expansion)
  Future<void> _loadTheme() async {
    // Default to system theme; later can load from Firestore when user logs in
    setState(() => _themeMode = ThemeMode.system);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WaterMeter',
      themeMode: ThemeController().themeMode, // Now listens dynamically


      // ✅ Updated Theme Section
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176ED2)),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176ED2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // ✅ Keep your existing routes
      home: const LoginPage(),
      routes: {
        '/dashboard': (context) => const DashboardView(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/questionnaire1': (context) => QuestionnairePage(),
        '/profile': (context) => ProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
      },
    );
  }
}
