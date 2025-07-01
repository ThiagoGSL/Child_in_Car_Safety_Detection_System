// lib/controllers/location_controller.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../car_moviment_verification/location_services.dart'; // Import the new repository

class LocationController {
  final LocationRepository _locationRepository;

  // Expose the location stream from the repository
  Stream<Position> get locationStream => _locationRepository.locationStream;

  LocationController(this._locationRepository);

  /// Starts the location service. This will request permissions if not granted
  /// and begin streaming location updates.
  Future<void> startLocationService() async {
    await _locationRepository.startListeningToLocation();
  }

  /// Stops the location service. This will cease streaming location updates.
  void stopLocationService() {
    _locationRepository.stopListeningToLocation();
  }

  /// A utility method to calculate distance, exposed through the controller.
  double getDistance(double startLat, double startLon, double endLat, double endLon) {
    return LocationRepository.getDistanceBetween(startLat, startLon, endLat, endLon);
  }

  /// Disposes of resources used by the controller and its repository.
  void dispose() {
    _locationRepository.dispose();
  }
}