// lib/controllers/vehicle_detection_controller.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/sensores_service.dart'; // Import the new repository

enum VehicleState { moving, stopped, unknown }

class VehicleDetectionController {
  final SensorDataRepository _sensorDataRepository;

  // Variables for movement detection
  final List<double> _accelerationHistory = [];
  final List<double> _locationHistory = [];
  final int _historySize = 10; // History size for analysis
  final double _movementThreshold = 2.0; // Threshold for detecting acceleration movement
  final double _locationThreshold = 0.1;

  double _lastLat = 0;
  double _lastLon = 0;
  int _unchangedLocationCount = 0;
  final int _maxUnchangedLocations = 6; // 30 seconds (5s * 6)

  // State variables
  VehicleState _vehicleState = VehicleState.unknown;
  bool _isCollectingData = true; // Internal state for data collection

  // Public getter for data collection status
  bool get isCollectingData => _isCollectingData;
  VehicleState get currentVehicleState => _vehicleState;


  // Timer for periodic data processing
  Timer? _detectionTimer;

  // Callbacks to notify UI or main logic
  Function(VehicleState)? onVehicleStateChanged;
  Function(String, String)? onInfoDialogRequested;

  VehicleDetectionController(this._sensorDataRepository) {
    _listenToSensorData();
    _startDetectionTimer();
  }

  void _listenToSensorData() {
    _sensorDataRepository.accelerometerStream.listen((event) {
      double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
      _updateAccelerationHistory(magnitude);
    });

    _sensorDataRepository.locationStream.listen((position) {
      if (_lastLat != 0 && _lastLon != 0) {
        double distance = Geolocator.distanceBetween(_lastLat, _lastLon, position.latitude, position.longitude);
        _updateLocationHistory(distance);
      }
    });
  }

  void _updateAccelerationHistory(double magnitude) {
    _accelerationHistory.add(magnitude);
    if (_accelerationHistory.length > _historySize) {
      _accelerationHistory.removeAt(0);
    }
  }

  void _updateLocationHistory(double distance) {
    _locationHistory.add(distance);
    if (_locationHistory.length > _historySize) {
      _locationHistory.removeAt(0);
    }
  }

  bool _isVehicleMoving() {
    if (_accelerationHistory.length < 3 && _locationHistory.length < 3) {
      return false; // Insufficient data for a robust decision
    }

    // Check movement based on acceleration (variance)
    bool accelerationMovement = false;
    if (_accelerationHistory.length >= 3) {
      double avgAcceleration = _accelerationHistory.reduce((a, b) => a + b) / _accelerationHistory.length;
      double variance = 0;
      for (double acc in _accelerationHistory) {
        variance += (acc - avgAcceleration) * (acc - avgAcceleration);
      }
      variance /= _accelerationHistory.length;
      accelerationMovement = variance > _movementThreshold;
    }

    // Check movement based on location (coordinate change)
    bool locationMovement = false;
    if (_locationHistory.length >= 3) {
      double totalDistance = _locationHistory.reduce((a, b) => a + b);
      locationMovement = totalDistance > 5; // Assuming distanceFilter of Geolocator gives distance in meters
    }

    return accelerationMovement || locationMovement;
  }

  void _startDetectionTimer() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Determine vehicle state
      bool isMoving = _isVehicleMoving();
      VehicleState newState = isMoving ? VehicleState.moving : VehicleState.stopped;

      // Notify vehicle state change
      if (newState != _vehicleState) {
        _vehicleState = newState;
        onVehicleStateChanged?.call(newState); // Call the callback
      }

      // Check if location has changed significantly to pause collection
      bool locationChanged = _hasLocationChangedSignificantly();

      if (!locationChanged) {
        _unchangedLocationCount++;
      } else {
        _unchangedLocationCount = 0;
        _lastLat = _sensorDataRepository.lat; // Update last known position from repository
        _lastLon = _sensorDataRepository.lon;
      }

      if (_unchangedLocationCount >= _maxUnchangedLocations && _vehicleState == VehicleState.stopped) {
        if (_isCollectingData) { // Only trigger if state is changing
          _isCollectingData = false; // Set internal state to not collecting
          onInfoDialogRequested?.call('Coleta pausada', 'Veículo parado por muito tempo. Coleta de dados pausada.');
        }
      } else {
        if (!_isCollectingData) { // If it was paused and now moving/location changed
          resumeDataCollection();
          onInfoDialogRequested?.call('Coleta de dados reativada', 'Veículo em movimento. Coleta de dados reativada.');
        }
      }

      // Store data in the database if collecting
      if (_isCollectingData) {
        await _sensorDataRepository.saveCurrentSensorData();
      }
    });
  }

  bool _hasLocationChangedSignificantly() {
    double latDiff = (_sensorDataRepository.lat - _lastLat).abs();
    double lonDiff = (_sensorDataRepository.lon - _lastLon).abs();
    return latDiff > _locationThreshold || lonDiff > _locationThreshold;
  }

  // Method to manually resume data collection or when the vehicle starts moving again
  void resumeDataCollection() {
    _isCollectingData = true; // Set internal state to collecting
    _unchangedLocationCount = 0;
    // The timer is already periodic, so no need to restart it here, just update the flag.
  }

  void dispose() {
    _detectionTimer?.cancel();
    // No need to dispose streams here, as they are managed by SensorDataRepository
  }
}