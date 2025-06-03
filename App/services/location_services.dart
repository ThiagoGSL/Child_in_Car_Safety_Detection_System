import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static StreamSubscription<Position>? _positionSubscription;
  static final StreamController<Position> _locationController =
  StreamController<Position>.broadcast();

  static Stream<Position> get locationStream => _locationController.stream;

  /// Inicia a escuta por atualizações de localização.
  static Future<void> startListening() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _positionSubscription ??= Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // Em metros
          timeLimit: Duration(seconds: 180), // Para evitar listeners infinitos em alguns casos
        ),
      ).listen((Position position) {
        if (!_locationController.isClosed) {
          _locationController.add(position);
        }
      });
    } else {
      // Lidar com a permissão negada
      print("Permissão de localização negada.");
    }
  }

  /// Para a escuta por atualizações de localização.
  static void stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationController.close(); // Fechar o StreamController
  }

  /// Calcula a distância entre duas coordenadas em metros.
  static double getDistanceBetween(double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }
}