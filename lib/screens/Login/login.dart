import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {



  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  User? _user; 

  // Future<void> _loginWithEmail() async {
  //   try {
  //     final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: emailController.text.trim(),
  //       password: passwordController.text.trim(),
  //     );
  //     setState(() {
  //       _user = cred.user;
  //     });
  //   } on FirebaseAuthException catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Login failed: ${e.message}")),
  //     );
  //   }
  // }

  Future<void> _loginWithEmail() async {
  try {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() {
      _user = cred.user;
    });

    // Navigate only if login worked
    if (_user != null) {
      Navigator.pushReplacementNamed(context, '/dashboard1');
    }

  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login failed: ${e.message}")),
    );
  }
}


  Future<void> _loginWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      setState(() {
        _user = user;
      });
    Navigator.pushReplacementNamed(context, '/dashboard1');

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(" Logged in with Google")),
    );
     
    } else {
   
     
    }
  }

  Future<void> _logout() async {
   // await _authService.signOut();
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(24),
          child: _user == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _header(),
                    _inputField(),          // ✅ email & password fields
                  _forgotPassword(),      // ✅ forgot password option
                  _loginButton(),
                    GoogleAuthButton(onPressed: _loginWithGoogle),
                    _signup(),
                  ],
                )
              : _userInfoView(), 
        ),
      ),
    );
  }

  Widget _header() {
    return const Column(
      children: [
        Text(
          "Welcome Back",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Enter your credentials to login"),
      ],
    );
  }

  Widget _inputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "Email",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: const Color.fromARGB(255, 23, 110, 210).withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: const Color.fromARGB(255, 23, 110, 210).withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.lock),
          ),
        ),
      ],
    );
  }

  // Widget _loginButton() {
  //   return ElevatedButton(
  //     onPressed: _loginWithEmail,
  //     style: ElevatedButton.styleFrom(
  //       shape: const StadiumBorder(),
  //       padding: const EdgeInsets.symmetric(vertical: 16),
  //       backgroundColor: const Color.fromARGB(255, 23, 110, 210),
  //     ),
  //     child: const Text(
  //       "Login",
  //       style: TextStyle(fontSize: 20),
  //     ),
  //   );
  // }
  Widget _loginButton() {
  return SizedBox(
    width: double.infinity, // makes it full width like input fields
    child: ElevatedButton(
      onPressed: _loginWithEmail,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 23, 110, 210),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // rectangular with smooth corners
        ),
      ),
      child: const Text(
        "Login",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}




  Widget _forgotPassword() {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/forgotPassword');
      },
      child: const Text(
        "Forgot password?",
        style: TextStyle(color: Color.fromARGB(255, 23, 110, 210)),
      ),
    );
  }

  Widget _signup() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/signup');
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(color: Color.fromARGB(255, 23, 110, 210)),
          ),
        ),
      ],
    );
  }

  
  Widget _userInfoView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _user!.displayName ?? "No Name",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _user!.email ?? "",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[900],
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Logout",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
