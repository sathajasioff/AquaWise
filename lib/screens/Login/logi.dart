import 'package:flutter/material.dart';



class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Text("login Screen"),
      appBar: AppBar(
        title: const Text("Login ScreeBBGHGHn"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          
          // Action to perform when the button is pressed
          print("Floating Action Button Pressed");
        },
        child: const Icon(Icons.dangerous_sharp),
      ),  
    );
  }
}

