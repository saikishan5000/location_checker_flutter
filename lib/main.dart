import 'dart:async';
import 'dart:math';
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
      distanceFilter: 50, // minimum distance (measured in meters)
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
                    onPressed: _launchMapsUrl, // Open map on button press
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Open in App',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// LocationInfo class to store location data and labels
class LocationInfo {
  final LatLng position;
  final String label;
  LocationInfo(this.position, this.label);
}

class MapScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapScreen({super.key, required this.initialPosition});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late LatLng currentPosition;
  late StreamSubscription<Position> positionStream;
  late List<LocationInfo> nearbyLocations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    currentPosition = widget.initialPosition;
    nearbyLocations = _generateNearbyLocations();
    _getCurrentLocation();
  }

  List<LocationInfo> _generateNearbyLocations() {
    List<LocationInfo> locations = [];
    final labels = ['Restaurant', 'Park', 'Coffee Shop', 'Store'];
    for (int i = 0; i < 4; i++) {
      double randomLat =
          currentPosition.latitude + (_random.nextDouble() - 0.5) * 0.02;
      double randomLng =
          currentPosition.longitude + (_random.nextDouble() - 0.5) * 0.02;
      locations.add(LocationInfo(
        LatLng(randomLat, randomLng),
        labels[i],
      ));
    }
    return locations;
  }

  _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      nearbyLocations = _generateNearbyLocations();
    });

    positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
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

  Future<void> _navigateToLocation(LatLng targetLocation) async {
    final coordinates =
        Coords(targetLocation.latitude, targetLocation.longitude);
    final availableMaps = await MapLauncher.installedMaps;

    if (availableMaps.isNotEmpty) {
      await availableMaps.first.showMarker(
        coords: coordinates,
        title: "Random Location",
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No maps installed')),
        );
      }
    }
  }

  void _onMarkerTapped(LatLng location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Navigate to Location"),
          content: const Text("Do you want to navigate to this location?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLocation(location);
              },
              child: const Text("Navigate"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('Current Location'),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Scanned Item Location'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerWithLabel(LocationInfo location) {
    return GestureDetector(
      onTap: () => _onMarkerTapped(location.position),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.place,
            color: Colors.red,
            size: 40,
          ),
          Positioned(
            top:
                -40, // Adjust this value to position the label above the marker
            left: -60, // Center the label (half of the maxWidth)
            width: 120, // Fixed width to match constraints
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                location.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Locations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                nearbyLocations = _generateNearbyLocations();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: currentPosition,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const [],
                    ),
                    MarkerLayer(
                      markers: [
                        ...nearbyLocations.map(
                          (location) => Marker(
                            point: location.position,
                            child: _buildMarkerWithLabel(location),
                          ),
                        ),
                        Marker(
                          point: currentPosition,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: _buildLegend(),
                ),
                Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize
                            .min, // Ensures the container does not expand vertically
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.factory,
                                color: Colors.grey,
                                size: 30,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "QuikAudit",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8), // Space between the rows
                          Text(
                            "Click on scanned location to navigate to them",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
