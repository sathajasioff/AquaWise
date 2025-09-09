import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';  
import 'package:url_launcher/url_launcher.dart';

class MapViewPage extends StatefulWidget {
  final String title;
  final double latitude;
  final double longitude;

  const MapViewPage({
    super.key,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  late GoogleMapController _mapController;



void openMap(double lat, double lng) async {
  final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw "Could not launch $url";
  }
}


  @override
  Widget build(BuildContext context) {
    final LatLng position = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[900],
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: GoogleMap(
        mapType: MapType.normal, 
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId:  MarkerId("subject_location"),
            position: position,
            infoWindow: InfoWindow(
              title: widget.title,
              snippet:
                  "Lat: ${widget.latitude}, Lng: ${widget.longitude}", // shows when tapped
            ),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
