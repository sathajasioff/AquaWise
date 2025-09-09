import 'package:flutter/material.dart';
import 'package:watermeter/screens/Home/home_map.dart';
import 'package:watermeter/screens/Home/home_screen.dart'; // to access Subject model

class HomeDetails extends StatelessWidget {
  final Subject subject;

  const HomeDetails({super.key, required this.subject});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[900], // dark green
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
  IconButton(
    icon: const Icon(Icons.location_on),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapViewPage(
            title: subject.title,
            latitude: double.tryParse(subject.latitude) ?? 0.0,
            longitude: double.tryParse(subject.longitude) ?? 0.0,
          ),
        ),
      );
    },
  ),
],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (subject.imageLarge.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  subject.imageLarge,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) =>
                      const Icon(Icons.broken_image, size: 100),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              subject.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subject.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Text(
              subject.address,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
