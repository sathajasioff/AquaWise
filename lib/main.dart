import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:watermeter/screens/AI/AItips.dart';
import 'package:watermeter/screens/Login/login.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Load .env
  await dotenv.load(fileName: ".env");

  // Get keys
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WaterMeter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176ED2)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/aitips': (context) => const AIPersonalizationPage(),
      },
    );
  }
}

/// Checks user login
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
        return snapshot.data! ? const AIPersonalizationPage() : const LoginPage();
      },
    );
  }
}
