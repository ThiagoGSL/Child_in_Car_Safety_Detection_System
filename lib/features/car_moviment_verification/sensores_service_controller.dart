import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import '../car_moviment_verification/sensores_service.dart';
import '../car_moviment_verification/Database_helper.dart';

enum VehicleState {moving, stopped}

class VehicleDetectionController extends GetxController {
  final SensorDataRepository _repository = SensorDataRepository();
  final DatabaseHelper _databaseHelper = DatabaseHelper(); // Instância do DatabaseHelper

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
  final accelerometerStreamController = StreamController<AccelerometerEvent>.broadcast();

  Timer? _dbReadTimer;
  static const Duration _dbReadInterval = Duration(milliseconds: 500); // Frequência de leitura do DB
  AccelerometerEvent? _lastAccelerometerEventFromDb;

  // _movementThreshold agora se aplica à *diferença* de magnitude
  static const double _movementThreshold = 1.0; // Ajuste este valor conforme a sensibilidade desejada
  static const double _locationMovementThresholdMeters = 5.0;
  static const int _stopDelaySeconds = 3;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> init() async{
    _initSensorDataSaving();
    _startDbReadTimer();
    print('SensorController iniciado');
  }

  @override
  void onClose() {
    _stopDetectionTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    _dbReadTimer?.cancel();
    accelerometerStreamController.close();
    _repository.dispose();
    print("SensorController finalizado.");
    super.onClose();
  }

  void _initSensorDataSaving() {
    _accelerometerSubscription = _repository.accelerometerStream.listen((event) {
      if (isCollectingData.value) {
        accelerometerStreamController.sink.add(event);
        accelerometerDisplay.value = 'Accel\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
        _databaseHelper.inserirAcelerometro(event.x, event.y, event.z);
      }
    });

    _locationSubscription = _repository.locationStream.listen((position) {
      if (isCollectingData.value) {
        locationDisplay.value = 'Lat: ${position.latitude.toStringAsFixed(6)}\nLon: ${position.longitude.toStringAsFixed(6)}';
        _databaseHelper.inserirLocalizacao(position.latitude, position.longitude);
      }
      _repository.saveCurrentSensorData();
    });

    _gyroscopeSubscription = _repository.gyroscopeStream.listen((event) {
      if (isCollectingData.value) {
        gyroscopeDisplay.value = 'Gyro\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
        _databaseHelper.inserirGiroscopio(event.x, event.y, event.z);
      }
    });
  }

  // Modificado: Agora usa _lastAccelerometerEventFromDb para comparação
  void _startDbReadTimer() {
    _dbReadTimer = Timer.periodic(_dbReadInterval, (timer) async {
      if (isCollectingData.value) {
        final latestData = await _databaseHelper.getLatestData();

        // Lógica de detecção baseada no acelerômetro a partir do DB
        if (latestData['ultimo_acelerometro'] != null) {
          final currentAccelMap = latestData['ultimo_acelerometro'] as Map<String, dynamic>;
          final currentEvent = AccelerometerEvent(
            currentAccelMap['x'] as double,
            currentAccelMap['y'] as double,
            currentAccelMap['z'] as double,
            DateTime.parse(currentAccelMap['timestamp'] as String),
          );
          // Passa o evento atual e o último armazenado para a função de detecção
          _detectVehicleStateByAccelerometerFromDb(currentEvent);
        } else {
          // Se não houver dados de acelerômetro, consideramos parado ou inicializamos o estado
          _updateActualVehicleState(VehicleState.stopped);
        }

        // Lógica de detecção baseada na localização a partir do DB
        if (latestData['ultima_localizacao'] != null) {
          final locMap = latestData['ultima_localizacao'] as Map<String, dynamic>;
          final position = Position(
              latitude: locMap['latitude'] as double,
              longitude: locMap['longitude'] as double,
              timestamp: DateTime.parse(locMap['timestamp'] as String), // Converter string para DateTime
              accuracy: 0.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0, isMocked: false,
              altitudeAccuracy: 0.0, headingAccuracy: 0.0
          );
          _detectVehicleStateByLocationFromDb(position);
        }
      }
    });
  }

  // FUNÇÃO MODIFICADA: Agora compara o evento atual com o _lastAccelerometerEventFromDb
  void _detectVehicleStateByAccelerometerFromDb(AccelerometerEvent currentEvent) {
    final double currentMagnitude = sqrt(
        pow(currentEvent.x, 2) + pow(currentEvent.y, 2) + pow(currentEvent.z, 2)
    );
    if (_lastAccelerometerEventFromDb != null) {
      // Calcular a magnitude do evento anterior
      final double previousMagnitude = sqrt(
          pow(_lastAccelerometerEventFromDb!.x, 2) +
              pow(_lastAccelerometerEventFromDb!.y, 2) +
              pow(_lastAccelerometerEventFromDb!.z, 2)
      );

      // Calcular a diferença absoluta entre as magnitudes
      final double magnitudeDifference = (currentMagnitude - previousMagnitude).abs();

      // Comparar a diferença com o threshold
      if (magnitudeDifference < _movementThreshold) {
        if (_stopDetectionTimer == null || !_stopDetectionTimer!.isActive) {
          _stopDetectionTimer = Timer(const Duration(seconds: _stopDelaySeconds), () {
            _updateActualVehicleState(VehicleState.stopped);
          });
        }
      } else {
        _updateActualVehicleState(VehicleState.moving);
        _stopDetectionTimer?.cancel(); // Garante que o timer de parada seja cancelado
      }
    } else {
      _updateActualVehicleState(VehicleState.stopped);
    }

    // Atualiza o último evento de acelerômetro lido para a próxima comparação
    _lastAccelerometerEventFromDb = currentEvent;
  }

  void _detectVehicleStateByLocationFromDb(Position position) {
    if (_lastPosition != null) {
      final double distance = Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        position.latitude, position.longitude,
      );
      if (distance > _locationMovementThresholdMeters) {
        print('Movimento detectado por GPS do DB: ${distance.toStringAsFixed(1)}m');
        _updateActualVehicleState(VehicleState.moving);
      }
    }
    _lastPosition = position;
  }

  // LÓGICA DE ATUALIZAÇÃO DE ESTADO MELHORADA (SEM ALTERAÇÃO)
  void _updateActualVehicleState(VehicleState newState) {
    if (vehicleState.value != newState) {
      if (newState == VehicleState.moving) {
        _stopDetectionTimer?.cancel();
        vehicleState.value = newState;
        _onCarMoving();
        _resumeDataCollection();
      } else {
        vehicleState.value = newState;
        _onCarStopped();
        _pauseDataCollection();
      }
    } else if (newState == VehicleState.moving) {
      _stopDetectionTimer?.cancel();
    }
  }

  void _pauseDataCollection() {
    if (isCollectingData.value) {
      isCollectingData.value = false;
      _showInfoDialog('Coleta Pausada', 'Veículo parado. Coleta de dados pausada.');
    }
  }

  void _resumeDataCollection() {
    if (!isCollectingData.value) {
      isCollectingData.value = true;
      _showInfoDialog('Coleta Retomada', 'Veículo em Movimento.');
    }
  }

  void _onCarStopped() {
    print('Vehicle stopped.');
  }

  void _onCarMoving() {
    print('Vehicle moving.');
  }

  void _showInfoDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}