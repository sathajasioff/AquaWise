import 'package:flutter/material.dart';
import 'package:watermeter/screens/Home/home_screen.dart';
import 'package:watermeter/screens/Login/logi.dart';
import 'package:watermeter/screens/SignUp/signup.dart';

void main() {

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 23, 110, 210)),
      ),
      home: LoginPage(),
      routes: {
    '/signup': (context) => const SignupPage(), 
    '/login' : (context) => const LoginPage(),
  },

  
  );
}
}