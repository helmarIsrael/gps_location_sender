import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pubnub/pubnub.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isTracking = false;
  StreamSubscription<Position>? positionStream;
  Position? currentPosition;
  PubNub? pubnub;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Initialize PubNub instance with your PubNub keys
    pubnub = PubNub(
      defaultKeyset: Keyset(
        subscribeKey: 'sub-c-9b1b6642-c02c-4a31-8318-b11a7e03d387',
        publishKey: 'pub-c-3a0c331d-6dfd-4e0c-ae5a-efe81298da62',
        userId: UserId('tracker_dart'),
      ),
    );
  }

  Future<void> _toggleGPS() async {
    if (isTracking) {
      positionStream?.cancel();
      timer?.cancel();
    } else {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        positionStream = Geolocator.getPositionStream(
          desiredAccuracy: LocationAccuracy.best,
          distanceFilter: 1,
        ).listen((Position position) async {
          setState(() {
            currentPosition = position;
          });
        });

        // Start a timer to periodically publish GPS coordinates
        const Duration interval =
            Duration(seconds: 1); // Update every 30 seconds
        timer = Timer.periodic(interval, (timer) {
          _publishGPS();
        });
      }
    }

    setState(() {
      isTracking = !isTracking;
    });
  }

  Future<void> _publishGPS() async {
    if (pubnub != null && currentPosition != null) {
      await pubnub!.publish('bird-send-coords', [
        {
          "bird_id": "alpha",
          "lat": currentPosition!.latitude.toDouble(),
          "lng": currentPosition!.longitude.toDouble(),
          "signature": "d27718e2f6642bd3e01befe78ac19cc8",
          "site": "MSU-IIT",
          "color": "red"
        }
      ]);
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _toggleGPS,
              child: Text(isTracking ? 'Turn Off' : 'Turn On'),
            ),
            SizedBox(height: 20.0),
            Text(
              'GPS Tracking Status: ${isTracking ? 'On' : 'Off'}',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 20.0),
            if (currentPosition != null)
              Text(
                'Current Position: (${currentPosition!.latitude}, ${currentPosition!.longitude})',
                style: TextStyle(fontSize: 18.0),
              ),
          ],
        ),
      ),
    );
  }
}
