import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/controllers/theme_controller.dart';
import '../../controllers/edit_profile_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _controller = EditProfileController();
  final _nameController = TextEditingController();
  String? _themePreference;
  File? _imageFile;
  String? _photoUrl;
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _currentUsername; // Store the current username separately

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final data = await _controller.getCurrentProfile();
    if (data != null) {
      setState(() {
        _currentUsername = data['username'] ?? '';
        _nameController.text = _currentUsername!;
        _photoUrl = data['photoUrl'];
        _themePreference = data['theme'] ?? 'system';
      });
    }
  }

  void _checkForChanges() {
    final hasChanges = _imageFile != null || 
        (_nameController.text.isNotEmpty && _nameController.text != _currentUsername);
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose Profile Photo",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B47),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageOptionButton(
                  icon: Icons.photo_library_outlined,
                  label: "Gallery",
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() {
                        _imageFile = File(picked.path);
                        _hasChanges = true;
                      });
                    }
                  },
                ),
                _imageOptionButton(
                  icon: Icons.photo_camera_outlined,
                  label: "Camera",
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() {
                        _imageFile = File(picked.path);
                        _hasChanges = true;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final username = _nameController.text.trim();
    
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter your name",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? uploadedUrl = _photoUrl;
      
      // Upload new image if selected
      if (_imageFile != null) {
        print("🔄 Uploading new profile photo...");
        uploadedUrl = await _controller.uploadProfilePhoto(_imageFile!);
        if (uploadedUrl == null) {
          throw Exception("Failed to upload profile photo");
        }
        print("✅ Profile photo uploaded: $uploadedUrl");
      }

      // Update profile in Firestore
      print("🔄 Updating user profile...");
      final success = await _controller.updateUserProfile(
        username: username,
        photoUrl: uploadedUrl,
        themePreference: _themePreference,
      );

      if (success) {
        print("✅ Profile updated successfully!");
        
        // Update the current username immediately to prevent flicker
        setState(() {
          _currentUsername = username;
          _hasChanges = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Profile updated successfully!",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          // Wait a bit before navigating to ensure Firestore update is complete
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(context);
        }
      } else {
        throw Exception("Failed to update profile in database");
      }
    } catch (e) {
      print("❌ Error in _saveProfile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error updating profile. Please try again.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1A2B47),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A2B47)),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D7DD2),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 🔹 Profile Image Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Profile Picture",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2B47),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2D7DD2).withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      )
                                    : _photoUrl != null
                                        ? Image.network(
                                            _photoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildDefaultAvatar();
                                            },
                                          )
                                        : _buildDefaultAvatar(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D7DD2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tap camera icon to update photo",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Personal Information Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Personal Information",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2B47),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          onChanged: (value) => _checkForChanges(),
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                            hintText: "Enter your full name",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2D7DD2),
                                width: 2,
                              ),
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D7DD2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: const Color(0xFF2D7DD2),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF1A2B47),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Theme Preference Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "App Theme",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2B47),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Choose your preferred theme",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _themePreference,
                              isExpanded: true,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D7DD2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              items: [
                                _buildThemeOption('light', Icons.light_mode_outlined, "Light Mode"),
                                _buildThemeOption('dark', Icons.dark_mode_outlined, "Dark Mode"),
                                _buildThemeOption('system', Icons.settings_suggest_outlined, "System Default"),
                              ],
                              onChanged: (val) async {
                                setState(() {
                                  _themePreference = val;
                                  _hasChanges = true;
                                });
                                // Update theme instantly
                                if (mounted) {
                                  final themeController = Provider.of<ThemeController>(
                                    context,
                                    listen: false,
                                  );
                                  await themeController.updateTheme(val!);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🔹 Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _saveProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges ? const Color(0xFF2D7DD2) : Colors.grey,
                        foregroundColor: Colors.white,
                        elevation: _hasChanges ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shadowColor: _hasChanges ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Save Changes",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D7DD2), Color(0xFF1A5FA6)],
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.person_outline,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _imageOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF2D7DD2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(
              icon,
              color: const Color(0xFF2D7DD2),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A2B47),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildThemeOption(String value, IconData icon, String text) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7DD2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2D7DD2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF1A2B47),
            ),
          ),
        ],
      ),
    );
  }
}