import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationRepository {
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  StreamSubscription<Position>? _positionSubscription;

  /// Requests location permission and starts listening for location updates.
  /// Adds received positions to the internal stream.
  Future<void> startListeningToLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // In meters
          timeLimit: Duration(seconds: 180), // To avoid infinite listeners in some cases
        ),
      ).listen((Position position) {
        if (!_locationController.isClosed) {
          _locationController.add(position);
        }
      }, onError: (e) {
        print("Error receiving location: $e");
        if (!_locationController.isClosed) {
          _locationController.addError(e); // Propagate errors
        }
      });
    } else {
      print("Location permission denied.");
      // You might want to add an error to the stream or a callback for UI notification_ext
      if (!_locationController.isClosed) {
        _locationController.addError('Location permission denied.');
      }
    }
  }

  /// Stops listening for location updates and cancels the subscription.
  void stopListeningToLocation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculates the distance between two coordinates in meters.
  static double getDistanceBetween(double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  /// Disposes of the internal stream controller.
  void dispose() {
    _locationController.close();
  }
}