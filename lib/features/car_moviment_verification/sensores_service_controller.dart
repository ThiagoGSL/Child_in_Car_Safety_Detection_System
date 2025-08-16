import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import '../car_moviment_verification/sensores_service.dart';
import '../car_moviment_verification/Database_helper.dart';

enum VehicleState { moving, stopped }

class VehicleDetectionController extends GetxController {
  final SensorDataRepository _repository = SensorDataRepository();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  var vehicleState = VehicleState.stopped.obs;
  var isCollectingData = true.obs;
  var accelerometerDisplay = 'Accel\nX: 0.00\nY: 0.00\nZ: 0.00'.obs;
  var gyroscopeDisplay = 'Gyro\nX: 0.00\nY: 0.00\nZ: 0.00'.obs;
  var locationDisplay = 'Lat: 0.000000\nLon: 0.000000'.obs;

  Timer? _stopDetectionTimer;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _locationSubscription;
  Position? _lastPosition;
  final accelerometerStreamController =
      StreamController<AccelerometerEvent>.broadcast();

  Timer? _dbReadTimer;
  Timer? _dbWriteTimer; // Novo timer para escrita
  static const Duration _dbReadInterval = Duration(milliseconds: 500);
  static const Duration _dbWriteInterval = Duration(
    seconds: 1,
  ); // Exemplo: escreve a cada 1 segundo
  AccelerometerEvent? _lastAccelerometerEventFromDb;

  // Buffers temporários para acumular dados
  final List<Map<String, dynamic>> _acelerometroBuffer = [];
  final List<Map<String, dynamic>> _giroscopioBuffer = [];
  final List<Map<String, dynamic>> _localizacaoBuffer = [];

  // O onInit já existe, adicione o novo método
  @override
  void onInit() {
    super.onInit();
  }

  Future<void> init() async {
    _initSensorDataSaving();
    _startDbReadTimer();
    _startDbWriteTimer(); // Inicia o timer de escrita
    print('SensorController iniciado');
  }

  @override
  void onClose() {
    _stopDetectionTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    _dbReadTimer?.cancel();
    _dbWriteTimer?.cancel(); // Cancela o timer de escrita
    accelerometerStreamController.close();
    _repository.dispose();
    print("SensorController finalizado.");
    super.onClose();
  }

  void _initSensorDataSaving() {
    _accelerometerSubscription = _repository.accelerometerStream.listen((
      event,
    ) {
      if (isCollectingData.value) {
        accelerometerDisplay.value =
            'Accel\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
        _acelerometroBuffer.add({
          'x': event.x,
          'y': event.y,
          'z': event.z,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    _locationSubscription = _repository.locationStream.listen((position) {
      if (isCollectingData.value) {
        locationDisplay.value =
            'Lat: ${position.latitude.toStringAsFixed(6)}\nLon: ${position.longitude.toStringAsFixed(6)}';
        _localizacaoBuffer.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    _gyroscopeSubscription = _repository.gyroscopeStream.listen((event) {
      if (isCollectingData.value) {
        gyroscopeDisplay.value =
            'Gyro\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
        _giroscopioBuffer.add({
          'x': event.x,
          'y': event.y,
          'z': event.z,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _startDbReadTimer() {
    _dbReadTimer = Timer.periodic(_dbReadInterval, (timer) async {
      if (isCollectingData.value) {
        final latestData = await _databaseHelper.getLatestData();
        if (latestData['ultimo_acelerometro'] != null) {
          final currentAccelMap =
              latestData['ultimo_acelerometro'] as Map<String, dynamic>;
          final currentEvent = AccelerometerEvent(
            currentAccelMap['x'] as double,
            currentAccelMap['y'] as double,
            currentAccelMap['z'] as double,
            DateTime.parse(currentAccelMap['timestamp'] as String),
          );
          _detectVehicleStateByAccelerometerFromDb(currentEvent);
        } else {
          _updateActualVehicleState(VehicleState.stopped);
        }
        if (latestData['ultima_localizacao'] != null) {
          final locMap =
              latestData['ultima_localizacao'] as Map<String, dynamic>;
          final position = Position(
            latitude: locMap['latitude'] as double,
            longitude: locMap['longitude'] as double,
            timestamp: DateTime.parse(locMap['timestamp'] as String),
            accuracy: 0.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            isMocked: false,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          _detectVehicleStateByLocationFromDb(position);
        }
      }
    });
  }

  // Novo método para salvar os dados em lote
  void _startDbWriteTimer() {
    _dbWriteTimer = Timer.periodic(_dbWriteInterval, (timer) {
      if (isCollectingData.value) {
        if (_acelerometroBuffer.isNotEmpty ||
            _giroscopioBuffer.isNotEmpty ||
            _localizacaoBuffer.isNotEmpty) {
          _databaseHelper.inserirDadosSensores(
            List.from(_acelerometroBuffer),
            List.from(_giroscopioBuffer),
            List.from(_localizacaoBuffer),
          );
          _acelerometroBuffer.clear();
          _giroscopioBuffer.clear();
          _localizacaoBuffer.clear();
        }
      }
    });
  }

  void _detectVehicleStateByAccelerometerFromDb(
    AccelerometerEvent currentEvent,
  ) {
    final double currentMagnitude = sqrt(
      pow(currentEvent.x, 2) + pow(currentEvent.y, 2) + pow(currentEvent.z, 2),
    );
    if (_lastAccelerometerEventFromDb != null) {
      final double previousMagnitude = sqrt(
        pow(_lastAccelerometerEventFromDb!.x, 2) +
            pow(_lastAccelerometerEventFromDb!.y, 2) +
            pow(_lastAccelerometerEventFromDb!.z, 2),
      );
      final double magnitudeDifference =
          (currentMagnitude - previousMagnitude).abs();
      if (magnitudeDifference < 2.0) {
        if (_stopDetectionTimer == null || !_stopDetectionTimer!.isActive) {
          _stopDetectionTimer = Timer(const Duration(seconds: 1), () {
            _updateActualVehicleState(VehicleState.stopped);
          });
        }
      } else {
        _updateActualVehicleState(VehicleState.moving);
        _stopDetectionTimer?.cancel();
      }
    } else {
      _updateActualVehicleState(VehicleState.stopped);
    }
    _lastAccelerometerEventFromDb = currentEvent;
  }

  void _detectVehicleStateByLocationFromDb(Position position) {
    if (_lastPosition != null) {
      final double distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance > 5.5) {
        print(
          'Movimento detectado por GPS do DB: ${distance.toStringAsFixed(1)}m',
        );
        _updateActualVehicleState(VehicleState.moving);
      }
      if (distance < 5.5) {
        _updateActualVehicleState(VehicleState.stopped);
      }
    }
    _lastPosition = position;
  }

  void _updateActualVehicleState(VehicleState newState) {
    if (vehicleState.value != newState) {
      if (newState == VehicleState.moving) {
        _stopDetectionTimer?.cancel();
        vehicleState.value = newState;
      } else {
        vehicleState.value = newState;
      }
    } else if (newState == VehicleState.moving) {
      _stopDetectionTimer?.cancel();
    }
  }
}
