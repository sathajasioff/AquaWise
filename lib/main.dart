import 'package:flutter/material.dart';
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
// import 'firebase_options.dart'; // Uncomment if you have this file from flutterfire configure

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // If you have firebase_options.dart, use this:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Otherwise, this works if google-services.json (Android)
  // and GoogleService-Info.plist (iOS) are correctly added:
  await Firebase.initializeApp();
  // String? errorMessage;

  // try {
  //   await dotenv.load(fileName: ".env");
  //   print('DotEnv loaded successfully');
  //   print('GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY']}'); // Debug
  // } catch (e, stackTrace) {
  //   print('Error loading .env file: $e\nStackTrace: $stackTrace');
  //   errorMessage = 'Failed to load .env file: $e';
  // }

  // if (errorMessage == null) {
  //   final apiKey = dotenv.env['GEMINI_API_KEY'];
  //   if (apiKey == null || apiKey.isEmpty) {
  //     print('Error: GEMINI_API_KEY is missing or empty');
  //     errorMessage = 'GEMINI_API_KEY is missing';
  //   } else {
  //     try {
  //       await Gemini.init(apiKey: apiKey);
  //       print('Gemini initialized successfully');
  //     } catch (e, stackTrace) {
  //       print('Error initializing Gemini: $e\nStackTrace: $stackTrace');
  //       errorMessage = 'Failed to initialize Gemini: $e';
  //     }
  //   }
  // }
  String? errorMessage;

  try {
    await dotenv.load(fileName: ".env");
    print('DotEnv loaded successfully');
    print('GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY']?.substring(0, 4)}... (obfuscated for security)'); // Partial key
  } catch (e, stackTrace) {
    print('Error loading .env file: $e\nStackTrace: $stackTrace');
    errorMessage = 'Failed to load .env file: $e';
  }

  if (errorMessage == null) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Error: GEMINI_API_KEY is missing or empty');
      errorMessage = 'GEMINI_API_KEY is missing or empty';
    } else {
      try {
        await Gemini.init(apiKey: 'AIzaSyDqJb9WqzkqPju5JcKCIw13Lvg4OyiS89w');
        print('Gemini initialized successfully');
        // Test API connectivity
        final gemini = Gemini.instance;
        final testResponse = await gemini.text('Test connectivity');
        print('Gemini test response: ${testResponse?.toJson()}');
      } catch (e, stackTrace) {
        print('Error initializing or testing Gemini: $e\nStackTrace: $stackTrace');
        errorMessage = 'Failed to initialize or test Gemini: $e';
      }
    }
  }
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 23, 110, 210),
        ),
        useMaterial3: true,
      ),
      home: AIPersonalizationPage(), // Start at login screen
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/dashboard1': (context) => const DashboardPage(),
        '/questionnaire1': (context) => const QuestionnairePage(),
        '/forgotPassword': (context) => const ForgotPasswordPage(), 
        '/profilepage': (context) => const ProfilePage(),
        '/aitips' : (context) => const AIPersonalizationPage(), 
        '/checkusertype' :(context) => const CheckUserTypePage()// Add this line for AI Tips page
      },
    );
  }
}
