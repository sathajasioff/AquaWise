import 'package:flutter/material.dart';
import 'package:watermeter/screens/AI/AItipOP.dart';
import 'package:watermeter/screens/AI/AItips.dart';
import 'package:watermeter/screens/ForgotPassword/forgotPassword.dart';
import 'package:watermeter/screens/Home/dashboard_1.dart';
import 'package:watermeter/screens/Home/home_screen.dart';
import 'package:watermeter/screens/Login/login.dart';
import 'package:watermeter/screens/Profile/profile.dart';
import 'package:watermeter/screens/Questionnaire/quesScreen_1.dart';
import 'package:watermeter/screens/SignUp/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:watermeter/screens/Test/check_user_type.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  String? errorMessage;

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    print('DotEnv loaded successfully');
    print(
      'GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY']?.substring(0, 4)}... (obfuscated)',
    );
  } catch (e, stackTrace) {
    print('Error loading .env file: $e\nStackTrace: $stackTrace');
    errorMessage = 'Failed to load .env file: $e';
  }

  // Initialize Gemini
  if (errorMessage == null) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Error: GEMINI_API_KEY is missing or empty');
      errorMessage = 'GEMINI_API_KEY is missing or empty';
    } else {
      try {
        await Gemini.init(apiKey: apiKey);
        print('Gemini initialized successfully');

        // Optional test call
        final gemini = Gemini.instance;
        final testResponse = await gemini.text('Test connectivity');
        print('Gemini test response: ${testResponse?.output}');
      } catch (e, stackTrace) {
        print('Error initializing or testing Gemini: $e\nStackTrace: $stackTrace');
        errorMessage = 'Failed to initialize or test Gemini: $e';
      }
    }
  }

  // Optional: pass error message to app for UI handling
  runApp(MyApp(geminiError: errorMessage));
}

class MyApp extends StatelessWidget {
  final String? geminiError;
  const MyApp({super.key, this.geminiError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WaterMeter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 23, 110, 210),
        ),
        useMaterial3: true,
      ),
      home: geminiError != null
          ? Scaffold(
              body: Center(
                child: Text(
                  'Error initializing AI: $geminiError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            )
          : AiTipsPage(), // Start at AI Tips Page
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/dashboard1': (context) => const DashboardPage(),
        '/questionnaire1': (context) => const QuestionnairePage(),
        '/forgotPassword': (context) => const ForgotPasswordPage(),
        '/profilepage': (context) => const ProfilePage(),
        '/aitips': (context) => const AIPersonalizationPage(),
        '/aitipsop': (context) => const AiTipsPage(),
        '/checkusertype': (context) => const CheckUserTypePage(),
      },
    );
  }
}
