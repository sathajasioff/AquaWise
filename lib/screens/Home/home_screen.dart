import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watermeter/api/api.dart';
import 'package:watermeter/screens/Home/home_details.dart';

/// Model class for Subject
class Subject {
  final int id;
  final String title;
  final String description;
  final String address;
  final String postcode;
  final String phoneNumber;
  final String latitude;
  final String longitude;
  final String imageSmall;
  final String imageMedium;
  final String imageLarge;

  Subject({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.postcode,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.imageSmall,
    required this.imageMedium,
    required this.imageLarge,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      postcode: json['postcode'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      imageSmall: json['image']?['small'] ?? '',
      imageMedium: json['image']?['medium'] ?? '',
      imageLarge: json['image']?['large'] ?? '',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Subject> _subjects = [];
  bool _isLoading = true;

  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _apiGetSubjects();
  }

  // Fetch data from API - API.DART
  void _apiGetSubjects() async {
    try {
      var res = await CallApi().getAllData('hotels.json');
      var body = json.decode(res.body);

      if (body['status'] == 200 && body['data'] != null) {
        setState(() {
          _subjects =
              (body['data'] as List).map((e) => Subject.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.green[900], 
        centerTitle: true,
        title: const Text(
          "List VIEW",
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_user != null) ...[
            const SizedBox(height: 16),
            Text(
              _user!.displayName ?? "No Name",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _user!.email ?? "",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[900], 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),

            ),
            const Divider(thickness: 1, height: 20),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subjects.isEmpty
                    ? const Center(child: Text("No data found"))
                    : ListView.builder(
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          final subject = _subjects[index];
                          return Card(
                            // margin: const EdgeInsets.symmetric(
                            //     vertical: 8, horizontal: 12),
                            // shape: RoundedRectangleBorder(
                            //     borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            child: ListTile(

                              leading: subject.imageSmall.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                      //  "https://www.pexels.com/photo/two-yellow-labrador-retriever-puppies-1108099/",
                                       // "https://unsplash.com/photos/a-brown-and-white-dog-sitting-on-top-of-a-white-sheet-FP5M2q3M4J0",
                                       subject.imageSmall,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) =>
                                            const Icon(Icons.broken_image,
                                                size: 40),
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      size: 40),
                              title: Text(subject.title),
                              subtitle: Text(subject.address),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        HomeDetails(subject: subject),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
