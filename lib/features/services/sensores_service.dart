// lib/services/sensor_data_repository.dart

import 'dart:async';
import 'package:flutter/material.dart'; // Needed for WidgetsBindingObserver in some contexts, but not directly used here
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/Database_helper.dart'; // Path to your Database_helper


class SensorDataRepository {
  // Sensor variables (for external access or display)
  double vx = 0, vy = 0, vz = 0; // Velocity - typically derived, not directly from sensors_plus
  double ax = 0, ay = 0, az = 0;
  double gx = 0, gy = 0, gz = 0;
  double lat = 0, lon = 0;

  final _accelerometerController = StreamController<AccelerometerEvent>.broadcast();
  Stream<AccelerometerEvent> get accelerometerStream => _accelerometerController.stream;

  final _gyroscopeController = StreamController<GyroscopeEvent>.broadcast();
  Stream<GyroscopeEvent> get gyroscopeStream => _gyroscopeController.stream;

  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  // Database helper
  final dbHelper = DatabaseHelper();

  SensorDataRepository() {
    _initializeSensors();
  }

  Future<void> _initializeSensors() async {
    await _requestSensorPermissions();
    _listenToSensorEvents();
  }

  Future<void> _requestSensorPermissions() async {
    await Permission.location.request();
  }

  void _listenToSensorEvents() {
    accelerometerEvents.listen((event) {
      ax = event.x;
      ay = event.y;
      az = event.z;
      _accelerometerController.add(event); // Add to stream
    });

    gyroscopeEvents.listen((event) {
      gx = event.x;
      gy = event.y;
      gz = event.z;
      _gyroscopeController.add(event); // Add to stream
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Minimum distance to update (meters)
        timeLimit: Duration(seconds: 180), // Timeout for obtaining position
      ),
    ).listen((Position position) {
      lat = position.latitude;
      lon = position.longitude;
      _locationController.add(position); // Add to stream
    });
  }

  // Method to save current sensor data to the database
  Future<void> saveCurrentSensorData() async {
    await dbHelper.inserirAcelerometro(ax, ay);
    await dbHelper.inserirGiroscopio(gx, gy);
    await dbHelper.inserirLocalizacao(lat, lon);
  }

  void dispose() {
    _accelerometerController.close();
    _gyroscopeController.close();
    _locationController.close();
  }
}