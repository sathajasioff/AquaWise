import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/controllers/theme_controller.dart';
import 'package:watermeter/screens/AI/AItipOP.dart';
import 'package:watermeter/screens/AI/AItips.dart';
import 'package:watermeter/screens/About/about.dart';
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

  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY is missing in .env');
  }
  await Gemini.init(apiKey: apiKey);

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
      themeMode: themeController.themeMode, // ✅ controlled by provider
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
        '/privacy_policy' : (context) => const PrivacyPolicyPage(),
        '/about' : (context) => const AboutPage(),
        '/aitips' : (context) => const AIPersonalizationPage(),
        // '/report' : (context) => const ReportGeneratorPage(),
        
      },
    );
  }
}
