import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool serviceStatus = false;
  bool hasPermission = false;
  late LocationPermission permission;
  late Position position;
  String long = "", lat = "";
  bool isLoading = true;
  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    checkGps();
    super.initState();
  }

  checkGps() async {
    serviceStatus = await Geolocator.isLocationServiceEnabled();
    if (serviceStatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        } else if (permission == LocationPermission.deniedForever && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ));
        } else {
          hasPermission = true;
        }
      } else {
        hasPermission = true;
      }

      if (hasPermission) {
        setState(() {
          isLoading = false; // Stop the loading indicator
        });
        getLocation();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
    }

    setState(() {
      //refresh the UI
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    long = position.longitude.toString();
    lat = position.latitude.toString();

    setState(() {
      // * refresh UI
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, // accuracy of the location data
      distanceFilter: 100, // minimum distance (measured in meters)
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      long = position.longitude.toString();
      lat = position.latitude.toString();

      setState(() {
        // * refresh UI on update
      });
    });
  }

  // Method to launch the map with coordinates
  _launchMap() async {
    final coordinates = Coords(double.parse(lat), double.parse(long));
    final availableMaps = await MapLauncher.installedMaps;
    if (availableMaps.isNotEmpty) {
      // Open the first available map
      availableMaps.first.showMarker(
        coords: coordinates,
        title: "Location",
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No maps installed')),
        );
      }
    }
  }
  _launchMapsUrl() {
    final LatLng userLocation = LatLng(double.parse(lat), double.parse(long));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(initialPosition: userLocation),
      ),
    );
  }

  @override
  void dispose() {
    positionStream
        .cancel(); // Cancel the position stream when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Show GPS status with icons
            Icon(
              Icons.location_on,
              size: 50,
              color: serviceStatus ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              serviceStatus ? "GPS is Enabled" : "GPS is Disabled",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: serviceStatus ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasPermission ? "Permission Granted" : "GPS Permission Denied",
              style: TextStyle(
                fontSize: 20,
                color: hasPermission ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 30),
            if (!serviceStatus)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Enable Location Services',
                    style: TextStyle(color: Colors.white)),
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            // Display Loading Indicator
            if (isLoading) const CircularProgressIndicator(),
            if (!isLoading)
              Column(
                children: [
                  // Display coordinates once available
                  Text(
                    "Longitude: $long",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Latitude: $lat",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _launchMap, // Open map on button press
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Open in Google Maps' , style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: _launchMapsUrl, // Open map on button press
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Open in App' , style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}



class MapScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapScreen({super.key, required this.initialPosition});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late LatLng currentPosition;
  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    super.initState();
    currentPosition = widget.initialPosition;
    _getCurrentLocation();
  }

  _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });

    positionStream = Geolocator.getPositionStream(locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    )).listen((Position position) {
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  @override
  void dispose() {
    positionStream.cancel();
    super.dispose();
  }

  // Method to launch map navigation
  _navigateToLocation() async {
    final coordinates = Coords(currentPosition.latitude, currentPosition.longitude);
    final availableMaps = await MapLauncher.installedMaps;

    if (availableMaps.isNotEmpty) {
      await availableMaps.first.showMarker(
        coords: coordinates,
        title: "Your Location",
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No maps installed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map View"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: currentPosition,  // Set the center here
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: []
              )
,
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.initialPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  Marker(
                    point: currentPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [currentPosition, widget.initialPosition],
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _navigateToLocation,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Navigate to Location',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

