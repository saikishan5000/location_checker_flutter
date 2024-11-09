import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
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
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        } else if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            )
          );
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
      print("GPS Service is not enabled, turn on GPS location");
    }

    setState(() {
      //refresh the UI
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position.longitude); // Output: 80.24599079
    print(position.latitude); // Output: 29.6593457

    long = position.longitude.toString();
    lat = position.latitude.toString();

    setState(() {
      //refresh UI
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, // accuracy of the location data
      distanceFilter: 100, // minimum distance (measured in meters)
    );

    positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings).listen((Position position) {
      print(position.longitude); // Output: 80.24599079
      print(position.latitude); // Output: 29.6593457

      long = position.longitude.toString();
      lat = position.latitude.toString();

      setState(() {
        //refresh UI on update
      });
    });
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
              hasPermission
                  ? "Permission Granted"
                  : "GPS Permission Denied",
              style: TextStyle(
                fontSize: 20,
                color: hasPermission ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 30),

            // Display Loading Indicator
            if (isLoading)
              const CircularProgressIndicator(),
            if (!isLoading)
              Column(
                children: [
                  // Display coordinates once available
                  Text(
                    "Longitude: $long",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Latitude: $lat",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
