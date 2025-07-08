import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../car_moviment_verification/sensores_service.dart';

// Definição do enum para o código funcionar de forma independente
enum CheckinStatus {idle, pending, confirmed, timeout}

enum VehicleState {moving, stopped}

class VehicleDetectionController extends GetxController {
  final SensorDataRepository _repository = SensorDataRepository();

  var vehicleState = VehicleState.stopped.obs;
  var checkinStatus = CheckinStatus.idle.obs;
  var isCollectingData = true.obs;
  var checkinSeconds = 0.obs;
  var alertSeconds = 0.obs;
  var accelerometerDisplay = 'Accel\nX: 0.00\nY: 0.00\nZ: 0.00'.obs;
  var gyroscopeDisplay = 'Gyro\nX: 0.00\nY: 0.00\nZ: 0.00'.obs;
  var locationDisplay = 'Lat: 0.000000\nLon: 0.000000'.obs;

  Timer? _parkedTimer;
  Timer? _alertTimer;
  Timer? _stopDetectionTimer;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _locationSubscription;
  Position? _lastPosition;
  final accelerometerStreamController = StreamController<AccelerometerEvent>.broadcast();

  // --- CONSTANTES CORRIGIDAS E ADICIONADAS ---
  static const double _movementThreshold = 1.2; // Limiar de vibração
  static const double _locationMovementThresholdMeters = 5.0; // 5 metros, um valor mais realista
  static const int _stopDelaySeconds = 3; // CONSTANTE QUE FALTAVA FOI ADICIONADA

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    super.onInit();
    _restoreStatus();
    _initSensorMonitoring();
    print('SensorController iniciado');
  }

  @override
  void onClose() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
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

  // CORREÇÃO: Nome do método e da chamada interna corrigidos
  void _pauseDataCollection() {
    if (isCollectingData.value) {
      isCollectingData.value = false;
      _showInfoDialog('Coleta Pausada', 'Veículo parado. Coleta de dados pausada.');
    }
  }

  // CORREÇÃO: Nome do método corrigido
  void _resumeDataCollection() {
    if (!isCollectingData.value) {
      isCollectingData.value = true;
      _showInfoDialog('Coleta Retomada', 'Veículo em Movimento.');
    }
  }

  Future<void> onAppResumed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      await prefs.remove('checkinConfirmed');
      _confirmCheckin();
    }
  }

  Future<void> _restoreStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      checkinStatus.value = CheckinStatus.confirmed;
      await prefs.remove('checkinConfirmed');
    }
  }

  void _confirmCheckin() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    AwesomeNotifications().cancel(10); // Cancelar notificação de check-in
    AwesomeNotifications().cancel(11); // Cancelar notificação de alerta
    checkinStatus.value = CheckinStatus.confirmed;
  }

  void _onCarStopped() {
    _resetAllTimersAndNotifications();
    checkinStatus.value = CheckinStatus.pending;
    checkinSeconds.value = 30;
    _parkedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (checkinSeconds.value > 0) {
        checkinSeconds.value--;
      } else {
        t.cancel();
        _showCheckinNotification();
      }
    });
  }

  void _onCarMoving() {
    _resetAllTimersAndNotifications();
    checkinStatus.value = CheckinStatus.idle;
  }

  void _resetAllTimersAndNotifications() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    checkinSeconds.value = 0;
    alertSeconds.value = 0;
    AwesomeNotifications().cancelAll();
  }

  Future<void> _showCheckinNotification() async {
    if (checkinStatus.value != CheckinStatus.pending) return;
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'checkin_channel',
            title: 'Tudo bem?',
            body: 'Seu veículo está parado. Confirme se está tudo certo.'),
        actionButtons: [
          NotificationActionButton(key: 'CONFIRM_OK', label: 'Tudo OK')
        ]);
    _startAlertCountdown();
  }

  void _startAlertCountdown() {
    if (checkinStatus.value != CheckinStatus.pending) return;
    alertSeconds.value = 30;
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (alertSeconds.value > 0) {
        alertSeconds.value--;
      } else {
        t.cancel();
        checkinStatus.value = CheckinStatus.timeout;
        _showDangerNotification();
      }
    });
  }

  Future<void> _showDangerNotification() async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 11,
            channelKey: 'alert_channel',
            title: '🚨 Alerta de Segurança 🚨',
            body: 'Nenhuma resposta recebida. Um alerta pode ter sido enviado.'));
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