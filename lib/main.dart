import 'package:flutter/material.dart';
import 'package:watermeter/screens/ForgotPassword/forgotPassword.dart';
import 'package:watermeter/screens/Home/dashboard_1.dart';
import 'package:watermeter/screens/Home/home_screen.dart';
import 'package:watermeter/screens/Login/login.dart';
import 'package:watermeter/screens/Profile/profile.dart';
import 'package:watermeter/screens/Questionnaire/quesScreen_1.dart';
import 'package:watermeter/screens/SignUp/signup.dart';
import 'package:firebase_core/firebase_core.dart';
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
      home: LoginPage(), // Start at login screen
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/dashboard1': (context) => const DashboardPage(),
        '/questionnaire1': (context) => const QuestionnairePage(),
        '/forgotPassword': (context) => const ForgotPasswordPage(), 
        '/profilepage': (context) => const ProfilePage(), // Placeholder, replace with actual ProfilePage when available
      },
    );
  }
}
