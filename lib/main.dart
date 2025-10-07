import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, Settings;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:watermeter/screens/Home/dashboard_view.dart' show DashboardView;

// Import your screens
import 'package:watermeter/screens/Login/login.dart';
import 'package:watermeter/screens/Home/dashboard_1.dart';

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
      home: const LoginPage(), // 👈 App starts here always
      routes: {
        '/dashboard': (context) => const DashboardView(), // named route
      },
    );
  }
}
