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

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final data = await _controller.getCurrentProfile();
    if (data != null) {
      setState(() {
        _nameController.text = data['username'] ?? '';
        _photoUrl = data['photoUrl'];
        _themePreference = data['theme'] ?? 'system';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    String? uploadedUrl = _photoUrl;
    if (_imageFile != null) {
      uploadedUrl = await _controller.uploadProfilePhoto(_imageFile!);
    }

    await _controller.updateUserProfile(
      username: _nameController.text.trim(),
      photoUrl: uploadedUrl,
      themePreference: _themePreference,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF176ED2),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 🔹 Profile Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_photoUrl != null
                                        ? NetworkImage(_photoUrl!)
                                        : const AssetImage(
                                            'assets/images/default_avatar.png',
                                          ))
                                    as ImageProvider,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Username Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Theme Preference
                  DropdownButtonFormField<String>(
                    value: _themePreference,
                    decoration: InputDecoration(
                      labelText: "App Theme",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.color_lens_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text("Light")),
                      DropdownMenuItem(value: 'dark', child: Text("Dark")),
                      DropdownMenuItem(
                        value: 'system',
                        child: Text("System Default"),
                      ),
                    ],
                    onChanged: (val) async {
                      setState(() => _themePreference = val);
                      await _controller.updateUserProfile(themePreference: val);
                      // 🔥 Update UI theme instantly
                      if (mounted) {
                        final themeController = Provider.of<ThemeController>(
                          context,
                          listen: false,
                        );
                        await themeController.updateTheme(val!);
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text("Save Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176ED2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
