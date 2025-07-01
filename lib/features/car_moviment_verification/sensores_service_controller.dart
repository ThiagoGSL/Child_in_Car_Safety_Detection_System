import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../car_moviment_verification/sensores_service.dart';


enum VehicleState {moving, stopped}

class VehicleDetectionController extends GetxController {
  final SensorDataRepository _repository = SensorDataRepository();

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

  static const double _movementThreshold = 1.2; // Limiar de vibração
  static const double _locationMovementThresholdMeters = 5.0; // 5 metros, um valor mais realista
  static const int _stopDelaySeconds = 3; // CONSTANTE QUE FALTAVA FOI ADICIONADA

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> init() async{
    _initSensorMonitoring();
    print('SensorController iniciado');
  }

  @override
  void onClose() {
    _stopDetectionTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    accelerometerStreamController.close();
    _repository.dispose();
    print("SensorController finalizado.");
    super.onClose();
  }

  void _initSensorMonitoring() {
    _accelerometerSubscription = _repository.accelerometerStream.listen((event) {
      if (isCollectingData.value) {
        accelerometerStreamController.sink.add(event);
        _detectVehicleStateByAccelerometer(event);
        accelerometerDisplay.value = 'Accel\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      }
    });

    _locationSubscription = _repository.locationStream.listen((position) {
      if (isCollectingData.value) {
        locationDisplay.value = 'Lat: ${position.latitude.toStringAsFixed(6)}\nLon: ${position.longitude.toStringAsFixed(6)}';
      }

      if (_lastPosition != null) {
        final double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
        // CORREÇÃO: Usando o novo limiar mais realista
        if (distance > _locationMovementThresholdMeters) {
          print('Movimento detectado por GPS: ${distance.toStringAsFixed(1)}m');
          _updateActualVehicleState(VehicleState.moving);
        }
      }
      _lastPosition = position;
      _repository.saveCurrentSensorData();
    });
  }

  void _detectVehicleStateByAccelerometer(AccelerometerEvent event) {
    final double magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

    if (magnitude < _movementThreshold) {
      if (_stopDetectionTimer == null || !_stopDetectionTimer!.isActive) {
        _stopDetectionTimer = Timer(const Duration(seconds: _stopDelaySeconds), () {
          _updateActualVehicleState(VehicleState.stopped);
        });
      }
    } else {
      _updateActualVehicleState(VehicleState.moving);
    }
  }

  // LÓGICA DE ATUALIZAÇÃO DE ESTADO MELHORADA
  void _updateActualVehicleState(VehicleState newState) {
    if (vehicleState.value != newState) {
      if (newState == VehicleState.moving) {
        _stopDetectionTimer?.cancel();
        vehicleState.value = newState;
        _onCarMoving();
        _resumeDataCollection();
      } else { // newState == VehicleState.stopped
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
    // No longer handling check-in logic here
    print('Vehicle stopped.');
  }

  void _onCarMoving() {
    // No longer handling check-in logic here
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
