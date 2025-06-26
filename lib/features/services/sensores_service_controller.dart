import 'dart:async';
import 'dart:math';
import 'package:app_v0/features/models/check.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sensores_service.dart'; // Import the new repository

enum VehicleState {moving, stopped}

class VehicleDetectionController extends GetxController{
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
  static const double _movementThreshold = 1.0; // Threshold for detecting acceleration movement
  static const double _locationThreshold = 0.0001;

  @override
  void onInit(){
    super.onInit();
    _restoreStatus();
    _initSensorMonitoring();
    print('SensorController iniciado');
  }

  @override
  void onClose() {
    // Cancela todos os timers e streams para evitar memory leaks
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    _stopDetectionTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    accelerometerStreamController.close();
    _repository.dispose(); // Também chama o dispose do repositório
    print("SensorController finalizado.");
    super.onClose();
  }

  void _initSensorMonitoring() {
    // Listener do acelerômetro (permanece igual)
    _accelerometerSubscription = _repository.accelerometerStream.listen((event) {
      if (isCollectingData.value) {
        accelerometerStreamController.sink.add(event);
        _detectVehicleState(event); // Renomeado para clareza
        accelerometerDisplay.value = 'Accel\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      }
    });

    _locationSubscription = _repository.locationStream.listen((position) {
      if (isCollectingData.value) {
        locationDisplay.value = 'Lat: ${position.latitude.toStringAsFixed(6)}\nLon: ${position.longitude.toStringAsFixed(6)}';
      }


      // Se já temos uma posição anterior, calculamos a distância
      if (_lastPosition != null) {
        final double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Se a distância for maior que o nosso limite, consideramos como movimento
        if (distance > _locationThreshold) {
          print('Movimento detectado por GPS: ${distance.toStringAsFixed(1)}m');
          // Se o GPS detecta movimento, o estado DEVE ser "moving".
          // Isso cancela qualquer timer de parada que estivesse rodando.
          _updateActualVehicleState(VehicleState.moving);
        }
      }

      // Atualiza a última posição para a próxima verificação
      _lastPosition = position;

      // --- FIM DA NOVA LÓGICA ---

      _repository.saveCurrentSensorData();

    }, onError: (e) {
      print('Erro na localização: $e');
    });
  }


  void _detectVehicleState(AccelerometerEvent event){
    final double magnitude = sqrt(event.x*event.x + event.y*event.y + event.z*event.z);
    if (magnitude <_movementThreshold) {
      if (_stopDetectionTimer == null || !_stopDetectionTimer.isActive) {
        _stopDetectionTimer =
            Timer(const Duration(seconds: _stopDelaySeconds), () {
              _updateActualVehicleState(VehicleState.stopped);
            });
      }
    } else{
      _stopDetectionTimer?.cancel();
      _updateActualVehicleState(VehicleState.moving);

    }
  }

  void _updateActualVehicleState(VehicleState newState){
    if (newState != vehicleState.value){
      vehicleState.value = newState;

      if (newState == VehicleState.stopped){
        _onCarStopped();
        _pauseDataColletion();
      } else if (newState == VehicleState.moving){
        _onCarMoving();
        _resumeDataColletion();
      }
    }
  }

  void _pauseDataColletion() {
    if (isCollectingData.value) {
      isCollectingData.value = false;
      _showInforDialog('Coleta Pausada', 'Veículo parado.Coleta de dados pausada');
    }
  }

  void _resumeDataColletion(){
    if (!isCollectingData.value){
      isCollectingData.value = true;
      _showInfoDialog('Coleta Retomada', 'Veículo em Movimento');

    }
  }

  Future<void> onAppResumed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      await prefs.remove('checkinConfirmed');
      _confirmCheckin();
    }
  }

  Future<void>_restoreStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      checkinStatus.value = CheckinStatus.confirmed;

    }
  }

  void _confirmCheckin() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    AwesomeNotifications().cancel(1);
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

  void _resetAllTimersAndNotifications(){
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    checkinSeconds.value = 0;
    alertSeconds.value = 0;
    AwesomeNotifications().cancelAll();
  }
  Future<void> onAppResumed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      await prefs.remove('checkinConfirmed');
      _confirmCheckin();
    }
  }

  Future<void> _restoreStatus() async { /* ... */ }
  void _confirmCheckin() { /* ... */ }
  Future<void> _showCheckinNotification() async { /* ... */ }
  void _startAlertCountdown() { /* ... */ }
  Future<void> _showDangerNotification() async { /* ... */ }
  void _pauseDataCollection() { /* ... */ }
  void _resumeDataCollection() { /* ... */ }

}

