import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final ForgotPasswordController _controller = ForgotPasswordController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    final email = _emailController.text.trim();

    // Call controller
    final result = await _controller.sendPasswordReset(email);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (result == null) {
      // ✅ Success
      setState(() {
        _isSuccess = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Password reset link sent to your email",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      
      // Auto navigate after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    } else {
      // ❌ Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: "Enter your email address",
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        child: Icon(icon, color: const Color(0xFF176ED2), size: 24),
      ),
      labelStyle: GoogleFonts.poppins(
        color: const Color(0xFF176ED2),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF176ED2),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Forgot Password",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF176ED2),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF176ED2),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header Icon
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF176ED2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 50,
                      color: Color(0xFF176ED2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  "Reset Your Password",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF176ED2),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  "Enter your email address and we'll send you a link to reset your password.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                Text(
                  "Email Address",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleReset(),
                  decoration: _inputDecoration("Email", Icons.email_outlined),
                ),
                const SizedBox(height: 8),

                // Help text
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "Make sure this email is associated with your account",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Reset Button
                SizedBox(
                  height: 58,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176ED2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      shadowColor: const Color(0xFF176ED2).withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "SEND RESET LINK",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                // Success Message
                if (_isSuccess) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Check your email for the password reset link. You'll be redirected to login shortly.",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      "Back to Login",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF176ED2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}