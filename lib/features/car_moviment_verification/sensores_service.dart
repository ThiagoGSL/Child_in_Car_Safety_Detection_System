// lib/car_moviment_verification/sensores_service.dart
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// import '../car_moviment_verification/Database_helper.dart'; // Descomente e ajuste o path se estiver usando

class SensorDataRepository {
  double ax = 0, ay = 0, az = 0;
  double gx = 0, gy = 0, gz = 0;
  double lat = 0, lon = 0;

  final _accelerometerController = StreamController<AccelerometerEvent>.broadcast();
  Stream<AccelerometerEvent> get accelerometerStream => _accelerometerController.stream;

  final _gyroscopeController = StreamController<GyroscopeEvent>.broadcast();
  Stream<GyroscopeEvent> get gyroscopeStream => _gyroscopeController.stream;

  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  // final dbHelper = DatabaseHelper(); // Descomente para usar o banco

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
      ax = event.x; ay = event.y; az = event.z;
      _accelerometerController.add(event);
    });

    gyroscopeEvents.listen((event) {
      gx = event.x; gy = event.y; gz = event.z;
      _gyroscopeController.add(event);
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Atualiza a cada 2 metros movidos
      ),
    ).listen((Position position) {
      lat = position.latitude; lon = position.longitude;
      _locationController.add(position);
    });
  }

  Future<void> saveCurrentSensorData() async {
    // await dbHelper.inserirAcelerometro(ax, ay);
    // await dbHelper.inserirGiroscopio(gx, gy);
    // await dbHelper.inserirLocalizacao(lat, lon);
    // print('Dados salvos no banco.'); // Log de depuração
  }

  void dispose() {
    _accelerometerController.close();
    _gyroscopeController.close();
    _locationController.close();
  }
}