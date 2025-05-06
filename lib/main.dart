import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  String _accelerometer = 'Accel\nX: 0.00\nY: 0.00\nZ: 0.00';
  String _gyroscope = 'Gyro\nX: 0.00\nY: 0.00\nZ: 0.00';
  String _location = 'Lat: 0.000000\nLon: 0.000000';

  @override
  void initState() {
    super.initState();
    _listenToSensors();
    _requestPermissionAndStartLocation();
  }

  void _listenToSensors() {
    accelerometerEvents.listen((event) {
      setState(() {
        _accelerometer = 'Accel\nX: ${event.x.toStringAsFixed(2)}\n'
            'Y: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });

    gyroscopeEvents.listen((event) {
      setState(() {
        _gyroscope = 'Gyro\nX: ${event.x.toStringAsFixed(2)}\n'
            'Y: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });
  }

  Future<void> _requestPermissionAndStartLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
          timeLimit: Duration(seconds: 180),
        ),
      ).listen((Position position) {
        setState(() {
          _location = 'Lat: ${position.latitude.toStringAsFixed(6)}\n'
              'Lon: ${position.longitude.toStringAsFixed(6)}';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sensores e GPS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_accelerometer, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(_gyroscope, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(_location, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}